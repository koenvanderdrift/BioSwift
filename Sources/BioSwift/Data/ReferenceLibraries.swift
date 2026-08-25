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

        return ReferenceLibraries(
            elements: elements,
            aminoAcids: unimodLibraries.aminoAcids,
            modifications: unimodLibraries.modifications,
            enzymes: jsonLibraries.enzymes,
            hydrophobicityScales: jsonLibraries.hydrophobicityScales
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
    public let modifications: [Modification]
    public let enzymes: [Enzyme]
    public let hydrophobicityScales: [HydrophobicityScale]

    public let elementReferences: ElementReferences
    public let aminoAcidReferences: AminoAcidReferences
    public let modificationReferences: ModificationReferences
    public let enzymeReferences: EnzymeReferences
    public let hydrophobicityReferences: HydrophobicityReferences

    public init(
        elements: [ChemicalElement],
        aminoAcids: [AminoAcid],
        modifications: [Modification],
        enzymes: [Enzyme],
        hydrophobicityScales: [HydrophobicityScale]
    ) {
        self.elements = elements
        self.aminoAcids = aminoAcids
        self.modifications = modifications
        self.enzymes = enzymes
        self.hydrophobicityScales = hydrophobicityScales

        self.elementReferences = ElementReferences(elements: elements)
        self.aminoAcidReferences = AminoAcidReferences(aminoAcids: aminoAcids)
        self.modificationReferences = ModificationReferences(modifications: modifications)
        self.enzymeReferences = EnzymeReferences(enzymes: enzymes)
        self.hydrophobicityReferences = HydrophobicityReferences(hydrophobicityScales: hydrophobicityScales)
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

    public func hydrophobicityScale(named name: String) -> HydrophobicityScale? {
        hydrophobicityReferences.hydrophobicityScale(named: name)
    }

    public func hydrophobicityScale(named name: HydrophobicityScaleName) -> HydrophobicityScale? {
        hydrophobicityReferences.hydrophobicityScale(named: name)
    }

    public func modifications(applicableTo residueIdentifier: String) -> [Modification] {
        modificationReferences.modifications(applicableTo: residueIdentifier)
    }
}
