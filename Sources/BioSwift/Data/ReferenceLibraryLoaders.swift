//
//  ReferenceLibraryLoaders.swift
//  BioSwift
//
//  Created by Koen van der Drift on 1/29/22.
//  Copyright © 2022 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

public var loadElementsFromUnimod: Bool = false

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

// MARK: - Partial XML result

struct XMLReferenceLibraries {
    let aminoAcids: [AminoAcid]
    let modifications: [Modification]
}

// MARK: - XML loader

enum XMLReferenceLibraryLoader {
    static func load() throws -> XMLReferenceLibraries {
        let elements = ElementReferences(elements: ElementsLibraryDefaults.bundled)

        return try load(elements: elements)
    }

    static func load(elements: ElementReferences) throws -> XMLReferenceLibraries {
        let data = try loadData(from: "unimod", withExtension: "xml", in: .module)

        let parser = UnimodXMLParser(elements: elements)
        return try parser.parse(data: data)
    }

    /// Handy for tests with custom XML data.
    static func parse(data: Data) throws -> XMLReferenceLibraries {
        let elements = ElementReferences(elements: ElementsLibraryDefaults.bundled)

        let parser = UnimodXMLParser(elements: elements)
        return try parser.parse(data: data)
    }
}

// MARK: - Partial JSON result

struct JSONReferenceLibraries {
    let enzymes: [Enzyme]
    let hydropathyValues: [Hydro]
}

// MARK: - JSON loader

enum JSONReferenceLibraryLoader {
    static func loadElements() throws -> [ChemicalElement] {
        try parseJSONDataFromBundle(ChemicalElement.self, from: "elements")
    }

    static func loadOtherLibraries() throws -> JSONReferenceLibraries {
        let enzymes = try parseJSONDataFromBundle(Enzyme.self, from: "enzymes")

        let hydropathyValues = try parseJSONDataFromBundle(Hydro.self, from: "hydropathy")

        return JSONReferenceLibraries(enzymes: enzymes, hydropathyValues: hydropathyValues)
    }
}
