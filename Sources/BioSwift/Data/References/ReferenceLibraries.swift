//
//  ReferenceLibraries.swift
//  BioSwift
//
//  Created by Koen van der Drift on 22.08.2026.
//  Copyright © 2026 Koen van der Drift. All rights reserved.
//

/*
 Parsing of modifications in ReferenceLibraries has become quite complex. It uses ModificationVocabulary, TaxonomicRange, ModificationCrossReference, ModificationMetadata and ModificationLibrary. And then PSIModTerm and UniProtPTMRecord.
 
 Are these all really needed?
 
 
 Missing formulas, how to handle?
 
 RESID is outdated: RESID Database of Protein Modifications Release Notes
 Release 76.00 31-May-2018

 ChEBI is well maintained: http://www.ebi.ac.uk/chebi
 */


import Foundation

public enum ReferenceLibraryDefaults {
    public static let bundledResult = Result { try ReferenceLibraryLoader.loadBundled() }

    public static func loadBundled() throws -> ReferenceLibraries {
        try bundledResult.get()
    }
}

enum ReferenceLibraryLoader {
    // Formula parsing is used while loading the other libraries, so elements
    // must be available independently of the complete bundled collection.
    private static let bundledElements = Result {
        ElementReferences(elements: try JSONReferenceLibraryLoader.loadElements())
    }

    static func loadElements() throws -> ElementReferences {
        try bundledElements.get()
    }

    static func loadBundled() throws -> ReferenceLibraries {
        let elementReferences = try loadElements()
        let elements = elementReferences.elements
        let jsonLibraries = try JSONReferenceLibraryLoader.loadOtherLibraries()
        let unimodLibraries = try UnimodReferenceLibraryLoader.load(elements: elementReferences)
        let psiModLibrary = try PSIModReferenceLibraryLoader.load(elements: elementReferences)
        let aminoAcidReferences = AminoAcidReferences(aminoAcids: unimodLibraries.aminoAcids)
        let uniProtPTMLibrary = try UniProtPTMReferenceLibraryLoader.load(
            elements: elementReferences,
            aminoAcids: aminoAcidReferences
        )
        let unimodLibrary = ModificationLibrary(
            vocabulary: .unimod,
            version: "2.0",
            modifications: unimodLibraries.modifications
        )

        // Keep the full Unimod definitions for modification conversion above, but
        // expose only the standard 20 amino acids in the bundled sequence library.
        let standardCodes = Set("ACDEFGHIKLMNPQRSTVWY".map(String.init))
        let standardAminoAcids = unimodLibraries.aminoAcids.filter {
            standardCodes.contains($0.oneLetterCode)
        }

        return ReferenceLibraries(
            elements: elements,
            aminoAcids: standardAminoAcids,
            unimodLibrary: unimodLibrary,
            enzymes: jsonLibraries.enzymes,
            hydrophobicityScales: jsonLibraries.hydrophobicityScales,
            psiModLibrary: psiModLibrary,
            uniProtPTMLibrary: uniProtPTMLibrary
        )
    }
}

public struct ElementReferences: Sendable {
    public let elements: [ChemicalElement]

    private let elementsBySymbol: [String: ChemicalElement]

    public init(elements: [ChemicalElement]) {
        self.elements = elements
        self.elementsBySymbol = Dictionary(uniqueKeysWithValues: elements.map {
            ($0.symbol, $0)
        })
    }

    public func element(symbol: String) -> ChemicalElement? {
        elementsBySymbol[symbol]
    }
}

public enum AminoAcidReferenceError: Error, Equatable, Sendable {
    case invalidCode(String, expectedLength: Int)
    case duplicateCode(String)
}

public struct AminoAcidReferences: Sendable {
    public let aminoAcids: [AminoAcid]

    private let aminoAcidsByIdentifier: [String: AminoAcid]
    private let sequenceCodeTable: [UInt8]

    public init(aminoAcids: [AminoAcid]) {
        self.aminoAcids = aminoAcids
        self.aminoAcidsByIdentifier = Dictionary(
            uniqueKeysWithValues: aminoAcids.map {
                ($0.identifier, $0)
            })

        var table = [UInt8](repeating: 0, count: 256)
        for aminoAcid in aminoAcids where Self.isValidCode(aminoAcid.oneLetterCode, length: 1) {
            if let byte = aminoAcid.oneLetterCode.uppercased().utf8.first {
                table[Int(byte)] = byte
                table[Int(byte + 32)] = byte
            }
        }
        sequenceCodeTable = table
    }

    /// Filters raw one-letter sequence text for editing, retaining only defined ASCII
    /// codes and normalizing lowercase to uppercase. Order and repetitions are preserved.
    ///
    /// Scans UTF-8 bytes in O(n) time using a lookup table built with these references.
    /// Non-ASCII bytes are discarded; no Unicode transliteration is performed.
    /// This is not a FASTA parser: letters in headers or other prose are also retained.
    public func filterSequence(_ sequence: String) -> String {
        var result: [UInt8] = []
        result.reserveCapacity(sequence.utf8.count)
        for byte in sequence.utf8 {
            let code = sequenceCodeTable[Int(byte)]
            if code != 0 {
                result.append(code)
            }
        }
        return String(decoding: result, as: UTF8.self)
    }

    public func aminoAcid(identifier: String) -> AminoAcid? {
        aminoAcidsByIdentifier[identifier]
    }
}

extension AminoAcidReferences {
    private static func isValidCode(_ code: String, length: Int) -> Bool {
        code.utf8.count == length && code.utf8.allSatisfy {
            $0.isASCIIUppercase || $0.isASCIILowercase
        }
    }

    static func normalizedCode(_ code: String, length: Int) throws -> String {
        guard isValidCode(code, length: length) else {
            throw BioSwiftDiagnostics.logged(
                AminoAcidReferenceError.invalidCode(code, expectedLength: length)
            )
        }

        return code.uppercased()
    }

    public var allowedOneLetterCodes: Set<String> {
        Set((65...90).compactMap { index in
            sequenceCodeTable[index] == 0 ? nil : String(decoding: [sequenceCodeTable[index]], as: UTF8.self)
        })
    }

    /// Combines bundled and custom definitions without permitting code overrides.
    /// Codes are normalized to uppercase; omitted three-letter codes are not indexed.
    public init(customAminoAcids: [AminoAcid]) throws {
        let bundled = try ReferenceLibraryDefaults.loadBundled().aminoAcidReferences
        var combined: [AminoAcid] = []
        var oneLetterCodes: Set<String> = []
        var threeLetterCodes: Set<String> = []

        for aminoAcid in bundled.aminoAcids + customAminoAcids {
            let code = try Self.normalizedCode(aminoAcid.oneLetterCode, length: 1)
            let threeLetterCode = aminoAcid.threeLetterCode.isEmpty
                ? ""
                : try Self.normalizedCode(aminoAcid.threeLetterCode, length: 3)

            guard oneLetterCodes.insert(code).inserted else {
                throw BioSwiftDiagnostics.logged(
                    AminoAcidReferenceError.duplicateCode(code)
                )
            }

            if !threeLetterCode.isEmpty,
               !threeLetterCodes.insert(threeLetterCode).inserted {
                throw BioSwiftDiagnostics.logged(
                    AminoAcidReferenceError.duplicateCode(threeLetterCode)
                )
            }

            var normalized = AminoAcid(
                name: aminoAcid.name, oneLetterCode: code,
                threeLetterCode: threeLetterCode, formula: aminoAcid.formula,
                represents: aminoAcid.represents, representedBy: aminoAcid.representedBy
            )
            normalized.properties = aminoAcid.properties
            normalized.modification = aminoAcid.modification
            combined.append(normalized)
        }

        self.init(aminoAcids: combined)
    }
}

public struct EnzymeReferences: Sendable {
    public let enzymes: [Enzyme]

    private let enzymesByName: [String: Enzyme]

    public init(enzymes: [Enzyme]) {
        self.enzymes = enzymes
        self.enzymesByName = Dictionary(uniqueKeysWithValues: enzymes.map {
            ($0.name, $0)
        })
    }

    public func enzyme(named name: String) -> Enzyme? {
        enzymesByName[name]
    }
}

public struct HydrophobicityReferences: Sendable {
    public let hydrophobicityScales: [HydrophobicityScale]

    private let hydrophobicityScalesByName: [String: HydrophobicityScale]

    public init(hydrophobicityScales: [HydrophobicityScale]) {
        self.hydrophobicityScales = hydrophobicityScales
        self.hydrophobicityScalesByName = Dictionary(
            uniqueKeysWithValues: hydrophobicityScales.map {
                ($0.name, $0)
            })
    }

    public func hydrophobicityScale(named name: String) -> HydrophobicityScale? {
        hydrophobicityScalesByName[name]
    }

    public func hydrophobicityScale(named name: HydrophobicityScaleName) -> HydrophobicityScale? {
        hydrophobicityScale(named: name.rawValue)
    }

    public func numericHydrophobicityValues(named name: String) throws -> [String: Double] {
        guard let scale = hydrophobicityScalesByName[name] else {
            throw BioSwiftDiagnostics.logged(HydropathyError.scaleNotFound(name))
        }
        return try scale.values.reduce(into: [:]) { result, entry in
            guard let value = Double(entry.value) else {
                throw BioSwiftDiagnostics.logged(
                    HydropathyError.invalidReferenceValue(
                        scale: name, key: entry.key, value: entry.value))
            }
            result[entry.key] = value
        }
    }

    public func numericHydrophobicityValues(named name: HydrophobicityScaleName) throws -> [String: Double] {
        try numericHydrophobicityValues(named: name.rawValue)
    }
}

public struct ReferenceLibraries: Sendable {
    public let elements: [ChemicalElement]
    public let aminoAcids: [AminoAcid]
    public let unimodLibrary: ModificationLibrary
    public let enzymes: [Enzyme]
    public let hydrophobicityScales: [HydrophobicityScale]
    public let psiModLibrary: ModificationLibrary
    public let uniProtPTMLibrary: ModificationLibrary

    public let elementReferences: ElementReferences
    public let aminoAcidReferences: AminoAcidReferences
    public let enzymeReferences: EnzymeReferences
    public let hydrophobicityReferences: HydrophobicityReferences

    public init(
        elements: [ChemicalElement],
        aminoAcids: [AminoAcid],
        unimodLibrary: ModificationLibrary,
        enzymes: [Enzyme],
        hydrophobicityScales: [HydrophobicityScale],
        psiModLibrary: ModificationLibrary,
        uniProtPTMLibrary: ModificationLibrary
    ) {
        self.elements = elements
        self.aminoAcids = aminoAcids
        self.unimodLibrary = unimodLibrary
        self.enzymes = enzymes
        self.hydrophobicityScales = hydrophobicityScales
        self.psiModLibrary = psiModLibrary
        self.uniProtPTMLibrary = uniProtPTMLibrary

        self.elementReferences = ElementReferences(elements: elements)
        self.aminoAcidReferences = AminoAcidReferences(aminoAcids: aminoAcids)
        self.enzymeReferences = EnzymeReferences(enzymes: enzymes)
        self.hydrophobicityReferences = HydrophobicityReferences(hydrophobicityScales: hydrophobicityScales)
    }

    public func element(symbol: String) -> ChemicalElement? {
        elementReferences.element(symbol: symbol)
    }

    public func aminoAcid(identifier: String) -> AminoAcid? {
        aminoAcidReferences.aminoAcid(identifier: identifier)
    }

    public func enzyme(named name: String) -> Enzyme? {
        enzymeReferences.enzyme(named: name)
    }

    public func hydrophobicityScale(named name: String) -> HydrophobicityScale? {
        hydrophobicityReferences.hydrophobicityScale(named: name)
    }

    public func hydrophobicityScale(named name: HydrophobicityScaleName) -> HydrophobicityScale? {
        hydrophobicityReferences.hydrophobicityScale(named: name)
    }

}
