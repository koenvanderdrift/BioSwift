//
//  ReferenceLibraries.swift
//  BioSwift
//
//  Created by Koen van der Drift on 22.08.2026.
//  Copyright © 2026 Koen van der Drift. All rights reserved.
//

import Foundation

public enum ModificationVocabulary: String, Codable, Sendable {
    case unimod
    case psiMod
    case uniProtPTM
}

public struct TaxonomicRange: Codable, Hashable, Sendable {
    public let name: String
    public let taxonIdentifier: Int

    public init(name: String, taxonIdentifier: Int) {
        self.name = name
        self.taxonIdentifier = taxonIdentifier
    }
}

public struct ModificationCrossReference: Codable, Hashable, Sendable {
    public let database: String
    public let identifier: String

    public init(database: String, identifier: String) {
        self.database = database
        self.identifier = identifier
    }
}

public struct ModificationMetadata: Codable, Sendable {
    public let taxonomicRanges: [TaxonomicRange]
    public let keywords: [String]
    public let cellularLocations: [String]
    public let crossReferences: [ModificationCrossReference]

    public init(
        taxonomicRanges: [TaxonomicRange] = [],
        keywords: [String] = [],
        cellularLocations: [String] = [],
        crossReferences: [ModificationCrossReference] = []
    ) {
        self.taxonomicRanges = taxonomicRanges
        self.keywords = keywords
        self.cellularLocations = cellularLocations
        self.crossReferences = crossReferences
    }
}

public struct ModificationLibrary: Sendable {
    public let vocabulary: ModificationVocabulary
    public let version: String
    public let modifications: [Modification]

    private let references: ModificationReferences
    private let metadataByAccession: [String: ModificationMetadata]

    public init(
        vocabulary: ModificationVocabulary,
        version: String,
        modifications: [Modification],
        metadataByAccession: [String: ModificationMetadata] = [:]
    ) {
        self.vocabulary = vocabulary
        self.version = version
        self.modifications = modifications
        self.references = ModificationReferences(modifications: modifications)
        self.metadataByAccession = metadataByAccession
    }

    public func modification(named name: String) -> Modification? {
        references.modification(named: name)
    }

    public func modification(accession: String) -> Modification? {
        references.modification(accession: accession)
    }

    public func modifications(matching query: String, applicableTo residue: String? = nil) -> [Modification] {
        references.modifications(matching: query, applicableTo: residue)
    }

    public func modifications(applicableTo residueIdentifier: String) -> [Modification] {
        references.modifications(applicableTo: residueIdentifier)
    }

    public func metadata(for modification: Modification) -> ModificationMetadata? {
        modification.accession.flatMap { metadataByAccession[$0] }
    }

    public func modifications(taxonIdentifier: Int) -> [Modification] {
        modifications.filter { modification in
            metadata(for: modification)?.taxonomicRanges.contains {
                $0.taxonIdentifier == taxonIdentifier
            } == true
        }
    }
}

public enum ElementsLibraryDefaults {
    public static let bundledResult = Result { try JSONReferenceLibraryLoader.loadElements() }

    public static func loadBundled() throws -> [ChemicalElement] {
        try bundledResult.get()
    }
}

public enum ReferenceLibraryDefaults {
    public static let bundledResult = Result { try ReferenceLibraryLoader.loadBundled() }

    public static func loadBundled() throws -> ReferenceLibraries {
        try bundledResult.get()
    }
}

enum ReferenceLibraryLoader {
    static func loadBundled() throws -> ReferenceLibraries {
        let elements = try JSONReferenceLibraryLoader.loadElements()
        let jsonLibraries = try JSONReferenceLibraryLoader.loadOtherLibraries()
        let elementReferences = ElementReferences(elements: elements)
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

public enum ElementReferenceDefaults {
    public static func loadBundled() throws -> ElementReferences {
        ElementReferences(elements: try ElementsLibraryDefaults.loadBundled())
    }
}

public enum AminoAcidReferenceDefaults {
    public static func loadBundled() throws -> AminoAcidReferences {
        try ReferenceLibraryDefaults.loadBundled().aminoAcidReferences
    }
}

public enum UnimodModificationReferenceDefaults {
    public static func loadBundled() throws -> ModificationLibrary {
        try ReferenceLibraryDefaults.loadBundled().unimodLibrary
    }
}

public enum EnzymeReferenceDefaults {
    public static func loadBundled() throws -> EnzymeReferences {
        try ReferenceLibraryDefaults.loadBundled().enzymeReferences
    }
}

public enum HydrophobicityReferenceDefaults {
    public static func loadBundled() throws -> HydrophobicityReferences {
        try ReferenceLibraryDefaults.loadBundled().hydrophobicityReferences
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
        let bundled = try AminoAcidReferenceDefaults.loadBundled()
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

public struct ModificationReferences: Sendable {
    public let modifications: [Modification]

    private let modificationsByName: [String: Modification]
    private let modificationsByAccession: [String: Modification]

    public init(modifications: [Modification]) {
        self.modifications = modifications
        self.modificationsByName = Dictionary(
            modifications.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
        self.modificationsByAccession = Dictionary(
            modifications.compactMap { modification in
                modification.accession.map { ($0, modification) }
            },
            uniquingKeysWith: { first, _ in first }
        )
    }

    public func modification(named name: String) -> Modification? {
        modificationsByName[name]
    }

    public func modification(accession: String) -> Modification? {
        modificationsByAccession[accession]
    }

    public func modifications(matching query: String, applicableTo residue: String? = nil) -> [Modification] {
        let normalizedQuery = query.folding(
            options: [.caseInsensitive, .diacriticInsensitive], locale: .current)

        return modifications.filter { modification in
            let searchableNames = [modification.name, modification.fullName] + modification.synonyms
            let matchesName = searchableNames.contains { name in
                name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                    .contains(normalizedQuery)
            }
            let matchesResidue = residue == nil || modification.specificities.contains {
                $0.site == residue || $0.site == "X"
            }

            return matchesName && matchesResidue
        }
    }

    public func modifications(applicableTo residueIdentifier: String) -> [Modification] {
        modifications.filter { modification in
            modification.specificities.contains {
                $0.site == residueIdentifier
            }
        }
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
