//
//  ReferenceLibraries.swift
//  BioSwift
//
//  Created by Koen van der Drift on 22.08.2026.
//

import Foundation

// MARK: - Public compatibility globals

public var aminoAcidLibrary: [AminoAcid] {
    ReferenceLibraryDefaults.bundled.aminoAcids
}

public var modificationLibrary: [Modification] {
    ReferenceLibraryDefaults.bundled.modifications + [zeroModification]
}

public var elementLibrary: [ChemicalElement] {
    ReferenceLibraryDefaults.bundled.elements
}

public var enzymeLibrary: [Enzyme] {
    ReferenceLibraryDefaults.bundled.enzymes + [unspecifiedEnzyme]
}

public var hydropathyLibrary: [Hydro] {
    ReferenceLibraryDefaults.bundled.hydropathyValues
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

        return ReferenceLibraries(
            elements: elements,
            aminoAcids: unimodLibraries.aminoAcids,
            modifications: unimodLibraries.modifications,
            enzymes: jsonLibraries.enzymes,
            hydropathyValues: jsonLibraries.hydropathyValues
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

public enum ModificationReferenceDefaults {
    public static var bundled: ModificationReferences {
        ReferenceLibraryDefaults.bundled.modificationReferences
    }
}

public enum EnzymeReferenceDefaults {
    public static var bundled: EnzymeReferences {
        ReferenceLibraryDefaults.bundled.enzymeReferences
    }
}

public enum HydropathyReferenceDefaults {
    public static var bundled: HydropathyReferences {
        ReferenceLibraryDefaults.bundled.hydropathyReferences
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

    public init(modifications: [Modification]) {
        self.modifications = modifications
        self.modificationsByName = Dictionary(uniqueKeysWithValues: modifications.map {
            ($0.name, $0)
        })
    }

    public func modification(named name: String) -> Modification? {
        modificationsByName[name]
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

public struct HydropathyReferences: Sendable {
    public let hydropathyValues: [Hydro]

    private let hydropathyValuesByName: [String: Hydro]

    public init(hydropathyValues: [Hydro]) {
        self.hydropathyValues = hydropathyValues
        self.hydropathyValuesByName = Dictionary(
            uniqueKeysWithValues: hydropathyValues.map {
                ($0.name, $0)
            })
    }

    public func hydropathy(named name: String) -> Hydro? {
        hydropathyValuesByName[name]
    }
}

public struct ReferenceLibraries: Sendable {
    public let elements: [ChemicalElement]
    public let aminoAcids: [AminoAcid]
    public let modifications: [Modification]
    public let enzymes: [Enzyme]
    public let hydropathyValues: [Hydro]

    public let elementReferences: ElementReferences
    public let aminoAcidReferences: AminoAcidReferences
    public let modificationReferences: ModificationReferences
    public let enzymeReferences: EnzymeReferences
    public let hydropathyReferences: HydropathyReferences

    public init(
        elements: [ChemicalElement],
        aminoAcids: [AminoAcid],
        modifications: [Modification],
        enzymes: [Enzyme],
        hydropathyValues: [Hydro]
    ) {
        self.elements = elements
        self.aminoAcids = aminoAcids
        self.modifications = modifications
        self.enzymes = enzymes
        self.hydropathyValues = hydropathyValues

        self.elementReferences = ElementReferences(elements: elements)
        self.aminoAcidReferences = AminoAcidReferences(aminoAcids: aminoAcids)
        self.modificationReferences = ModificationReferences(modifications: modifications)
        self.enzymeReferences = EnzymeReferences(enzymes: enzymes)
        self.hydropathyReferences = HydropathyReferences(hydropathyValues: hydropathyValues)
    }

    public func element(symbol: String) -> ChemicalElement? {
        elementReferences.element(symbol: symbol)
    }

    public func aminoAcid(identifier: String) -> AminoAcid? {
        aminoAcidReferences.aminoAcid(identifier: identifier)
    }

    public func modification(named name: String) -> Modification? {
        modificationReferences.modification(named: name)
    }

    public func enzyme(named name: String) -> Enzyme? {
        enzymeReferences.enzyme(named: name)
    }

    public func hydropathy(named name: String) -> Hydro? {
        hydropathyReferences.hydropathy(named: name)
    }

    public func modifications(applicableTo residueIdentifier: String) -> [Modification] {
        modificationReferences.modifications(applicableTo: residueIdentifier)
    }
}
