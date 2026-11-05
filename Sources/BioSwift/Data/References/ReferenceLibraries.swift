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

/// Bundled reference libraries, loaded on first access and cached for subsequent use.
public enum ReferenceLibrary {
    public static var aminoAcids: AminoAcidReferences {
        get throws {
            try ReferenceLibraryLoader.loadAminoAcids()
        }
    }

    public static var elements: ElementReferences {
        get throws {
            try ReferenceLibraryLoader.loadElements()
        }
    }

    public static var enzymes: EnzymeReferences {
        get throws {
            try ReferenceLibraryLoader.loadEnzymes()
        }
    }

    public static var hydrophobicityScales: HydrophobicityReferences {
        get throws {
            try ReferenceLibraryLoader.loadHydrophobicityScales()
        }
    }

    public static var unimod: ModificationLibrary {
        get throws {
            try ReferenceLibraryLoader.loadUnimod()
        }
    }

    public static var psiMod: ModificationLibrary {
        get throws {
            try ReferenceLibraryLoader.loadPSIMod()
        }
    }

    public static var uniProtPTM: ModificationLibrary {
        get throws {
            try ReferenceLibraryLoader.loadUniProtPTM()
        }
    }
}

enum ReferenceLibraryDefaults {
    static let bundledResult = Result { try ReferenceLibraryLoader.loadBundled() }

    static func loadBundled() throws -> ReferenceLibraries {
        try bundledResult.get()
    }
}

enum ReferenceLibraryLoader {
    // Elements must load independently because formula parsing uses them.
    private static let bundledElements = Result {
        ElementReferences(elements: try JSONReferenceLibraryLoader.loadElements())
    }

    private static let bundledUnimodSource = Result {
        try UnimodReferenceLibraryLoader.load(elements: loadElements())
    }

    private static let bundledAminoAcids = Result {
        let source = try bundledUnimodSource.get()
        let standardCodes = Set("ACDEFGHIKLMNPQRSTVWY".map(String.init))
        return AminoAcidReferences(aminoAcids: source.aminoAcids.filter {
            standardCodes.contains($0.oneLetterCode)
        })
    }

    private static let bundledEnzymes = Result {
        EnzymeReferences(enzymes: try JSONReferenceLibraryLoader.loadEnzymes())
    }

    private static let bundledHydrophobicityScales = Result {
        HydrophobicityReferences(
            hydrophobicityScales: try JSONReferenceLibraryLoader.loadHydrophobicityScales()
        )
    }

    private static let bundledUnimod = Result {
        ModificationLibrary(
            vocabulary: .unimod,
            version: "2.0",
            modifications: try bundledUnimodSource.get().modifications
        )
    }

    private static let bundledPSIMod = Result {
        try PSIModReferenceLibraryLoader.load(elements: loadElements())
    }

    private static let bundledUniProtPTM = Result {
        // Conversion needs the full Unimod definitions, including nonstandard amino acids.
        let source = try bundledUnimodSource.get()
        return try UniProtPTMReferenceLibraryLoader.load(
            elements: loadElements(),
            aminoAcids: AminoAcidReferences(aminoAcids: source.aminoAcids)
        )
    }

    static func loadAminoAcids() throws -> AminoAcidReferences {
        try bundledAminoAcids.get()
    }

    static func loadElements() throws -> ElementReferences {
        try bundledElements.get()
    }

    static func loadEnzymes() throws -> EnzymeReferences {
        try bundledEnzymes.get()
    }

    static func loadHydrophobicityScales() throws -> HydrophobicityReferences {
        try bundledHydrophobicityScales.get()
    }

    static func loadUnimod() throws -> ModificationLibrary {
        try bundledUnimod.get()
    }

    static func loadPSIMod() throws -> ModificationLibrary {
        try bundledPSIMod.get()
    }

    static func loadUniProtPTM() throws -> ModificationLibrary {
        try bundledUniProtPTM.get()
    }

    static func loadBundled() throws -> ReferenceLibraries {
        try ReferenceLibraries(
            elements: loadElements().elements,
            aminoAcids: loadAminoAcids().aminoAcids,
            unimodLibrary: loadUnimod(),
            enzymes: loadEnzymes().enzymes,
            hydrophobicityScales: loadHydrophobicityScales().hydrophobicityScales,
            psiModLibrary: loadPSIMod(),
            uniProtPTMLibrary: loadUniProtPTM()
        )
    }
}

/// Provides direct iteration and indexed access in reference-library order.
extension ElementReferences: RandomAccessCollection {
    public var startIndex: Int { elements.startIndex }
    public var endIndex: Int { elements.endIndex }

    public subscript(position: Int) -> ChemicalElement {
        elements[position]
    }

    public func index(after index: Int) -> Int {
        elements.index(after: index)
    }

    public func index(before index: Int) -> Int {
        elements.index(before: index)
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

/// Provides direct iteration and indexed access in reference-library order.
extension AminoAcidReferences: RandomAccessCollection {
    public var startIndex: Int { aminoAcids.startIndex }
    public var endIndex: Int { aminoAcids.endIndex }

    public subscript(position: Int) -> AminoAcid {
        aminoAcids[position]
    }

    public func index(after index: Int) -> Int {
        aminoAcids.index(after: index)
    }

    public func index(before index: Int) -> Int {
        aminoAcids.index(before: index)
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
        let bundled = try ReferenceLibrary.aminoAcids
        var combined: [AminoAcid] = []
        var oneLetterCodes: Set<String> = []
        var threeLetterCodes: Set<String> = []

        for aminoAcid in Array(bundled) + customAminoAcids {
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

/// Provides direct iteration and indexed access in reference-library order.
extension EnzymeReferences: RandomAccessCollection {
    public var startIndex: Int { enzymes.startIndex }
    public var endIndex: Int { enzymes.endIndex }

    public subscript(position: Int) -> Enzyme {
        enzymes[position]
    }

    public func index(after index: Int) -> Int {
        enzymes.index(after: index)
    }

    public func index(before index: Int) -> Int {
        enzymes.index(before: index)
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

/// Provides direct iteration and indexed access in reference-library order.
extension HydrophobicityReferences: RandomAccessCollection {
    public var startIndex: Int { hydrophobicityScales.startIndex }
    public var endIndex: Int { hydrophobicityScales.endIndex }

    public subscript(position: Int) -> HydrophobicityScale {
        hydrophobicityScales[position]
    }

    public func index(after index: Int) -> Int {
        hydrophobicityScales.index(after: index)
    }

    public func index(before index: Int) -> Int {
        hydrophobicityScales.index(before: index)
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

struct ReferenceLibraries: Sendable {
    let elements: [ChemicalElement]
    let aminoAcids: [AminoAcid]
    let unimodLibrary: ModificationLibrary
    let enzymes: [Enzyme]
    let hydrophobicityScales: [HydrophobicityScale]
    let psiModLibrary: ModificationLibrary
    let uniProtPTMLibrary: ModificationLibrary

    let elementReferences: ElementReferences
    let aminoAcidReferences: AminoAcidReferences
    let enzymeReferences: EnzymeReferences
    let hydrophobicityReferences: HydrophobicityReferences

    init(
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

    func element(symbol: String) -> ChemicalElement? {
        elementReferences.element(symbol: symbol)
    }

    func aminoAcid(identifier: String) -> AminoAcid? {
        aminoAcidReferences.aminoAcid(identifier: identifier)
    }

    func enzyme(named name: String) -> Enzyme? {
        enzymeReferences.enzyme(named: name)
    }

    func hydrophobicityScale(named name: String) -> HydrophobicityScale? {
        hydrophobicityReferences.hydrophobicityScale(named: name)
    }

    func hydrophobicityScale(named name: HydrophobicityScaleName) -> HydrophobicityScale? {
        hydrophobicityReferences.hydrophobicityScale(named: name)
    }

}
