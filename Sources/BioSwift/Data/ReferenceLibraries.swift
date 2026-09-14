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
}

public struct ModificationLibrary: Sendable {
    public let vocabulary: ModificationVocabulary
    public let version: String
    public let modifications: [Modification]
    public let rejectedTermCount: Int

    private let references: ModificationReferences

    public init(
        vocabulary: ModificationVocabulary,
        version: String,
        modifications: [Modification],
        rejectedTermCount: Int = 0
    ) {
        self.vocabulary = vocabulary
        self.version = version
        self.modifications = modifications
        self.rejectedTermCount = rejectedTermCount
        self.references = ModificationReferences(modifications: modifications)
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
}

// MARK: - Public compatibility globals

public var aminoAcidLibrary: [AminoAcid] {
    ReferenceLibraryDefaults.bundled.aminoAcids
}

public var modificationLibrary: [Modification] {
    ReferenceLibraryDefaults.bundled.unimodLibrary.modifications + [zeroModification]
}

public var elementLibrary: [ChemicalElement] {
    ReferenceLibraryDefaults.bundled.elements
}

public var enzymeLibrary: [Enzyme] {
    ReferenceLibraryDefaults.bundled.enzymes + [unspecifiedEnzyme]
}

public var hydrophobicityLibrary: [HydrophobicityScale] {
    ReferenceLibraryDefaults.bundled.hydrophobicityScales
}

public enum ElementsLibraryDefaults {
    public static let bundled: [ChemicalElement] = {
        do {
            return try JSONReferenceLibraryLoader.loadElements()
        } catch {
            fatalError("Failed to load bundled elements library: \(error)")
        }
    }()
}

public enum ReferenceLibraryDefaults {
    public static let bundled: ReferenceLibraries = {
        do {
            return try ReferenceLibraryLoader.loadBundled()
        } catch {
            fatalError("Failed to load bundled reference libraries: \(error)")
        }
    }()

    public static func loadBundled() throws -> ReferenceLibraries {
        try ReferenceLibraryLoader.loadBundled()
    }
}

enum ReferenceLibraryLoader {
    static func loadBundled() throws -> ReferenceLibraries {
        let elements = try JSONReferenceLibraryLoader.loadElements()
        let jsonLibraries = try JSONReferenceLibraryLoader.loadOtherLibraries()
        let elementReferences = ElementReferences(elements: elements)
        let unimodLibraries = try UnimodReferenceLibraryLoader.load(elements: elementReferences)
        let psiModLibrary = try PSIModReferenceLibraryLoader.load(elements: elementReferences)
        let unimodLibrary = ModificationLibrary(
            vocabulary: .unimod,
            version: "2.0",
            modifications: unimodLibraries.modifications
        )

        return ReferenceLibraries(
            elements: elements,
            aminoAcids: unimodLibraries.aminoAcids,
            unimodLibrary: unimodLibrary,
            enzymes: jsonLibraries.enzymes,
            hydrophobicityScales: jsonLibraries.hydrophobicityScales,
            psiModLibrary: psiModLibrary
        )
    }
}

public enum ElementReferenceDefaults {
    public static let bundled = ElementReferences(elements: ElementsLibraryDefaults.bundled)
}

public enum AminoAcidReferenceDefaults {
    public static var bundled: AminoAcidReferences {
        ReferenceLibraryDefaults.bundled.aminoAcidReferences
    }
}

public enum UnimodModificationReferenceDefaults {
    public static var bundled: ModificationLibrary {
        ReferenceLibraryDefaults.bundled.unimodLibrary
    }
}

public enum EnzymeReferenceDefaults {
    public static var bundled: EnzymeReferences {
        ReferenceLibraryDefaults.bundled.enzymeReferences
    }
}

public enum HydrophobicityReferenceDefaults {
    public static var bundled: HydrophobicityReferences {
        ReferenceLibraryDefaults.bundled.hydrophobicityReferences
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

public struct AminoAcidReferences: Sendable {
    public let aminoAcids: [AminoAcid]

    private let aminoAcidsByIdentifier: [String: AminoAcid]

    public init(aminoAcids: [AminoAcid]) {
        self.aminoAcids = aminoAcids
        self.aminoAcidsByIdentifier = Dictionary(
            uniqueKeysWithValues: aminoAcids.map {
                ($0.identifier, $0)
            })
    }

    public func aminoAcid(identifier: String) -> AminoAcid? {
        aminoAcidsByIdentifier[identifier]
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
    private let numericHydrophobicityValuesByName: [String: [String: Double]]

    public init(hydrophobicityScales: [HydrophobicityScale]) {
        self.hydrophobicityScales = hydrophobicityScales
        self.hydrophobicityScalesByName = Dictionary(
            uniqueKeysWithValues: hydrophobicityScales.map {
                ($0.name, $0)
            })
        self.numericHydrophobicityValuesByName = Dictionary(
            uniqueKeysWithValues: hydrophobicityScales.map { scale in
                let numericValues = scale.values.compactMapValues(Double.init)

                return (scale.name, numericValues)
            })
    }

    public func hydrophobicityScale(named name: String) -> HydrophobicityScale? {
        hydrophobicityScalesByName[name]
    }

    public func hydrophobicityScale(named name: HydrophobicityScaleName) -> HydrophobicityScale? {
        hydrophobicityScale(named: name.rawValue)
    }

    public func numericHydrophobicityValues(named name: String) -> [String: Double] {
        numericHydrophobicityValuesByName[name] ?? [:]
    }

    public func numericHydrophobicityValues(named name: HydrophobicityScaleName) -> [String: Double] {
        numericHydrophobicityValues(named: name.rawValue)
    }
}

public struct ReferenceLibraries: Sendable {
    public let elements: [ChemicalElement]
    public let aminoAcids: [AminoAcid]
    public let unimodLibrary: ModificationLibrary
    public let enzymes: [Enzyme]
    public let hydrophobicityScales: [HydrophobicityScale]
    public let psiModLibrary: ModificationLibrary

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
        psiModLibrary: ModificationLibrary
    ) {
        self.elements = elements
        self.aminoAcids = aminoAcids
        self.unimodLibrary = unimodLibrary
        self.enzymes = enzymes
        self.hydrophobicityScales = hydrophobicityScales
        self.psiModLibrary = psiModLibrary

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
