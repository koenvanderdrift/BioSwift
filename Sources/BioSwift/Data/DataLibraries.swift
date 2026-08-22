//
//  ReferenceLibraryLoaders.swift
//  BioSwift
//
//  Created by Koen van der Drift on 1/29/22.
//  Copyright © 2022 - 2025 Koen van der Drift. All rights reserved.

import Foundation

public var loadElementsFromUnimod: Bool = false

// MARK: - public globals

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
        do { return try JSONReferenceLibraryLoader.loadElements() } catch {
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
    // parse elements first before anything else.

    static func loadElements() throws -> [ChemicalElement] {
        try parseJSONDataFromBundle(ChemicalElement.self, from: "elements")
    }

    static func loadOtherLibraries() throws -> JSONReferenceLibraries {
        let enzymes = try parseJSONDataFromBundle(Enzyme.self, from: "enzymes")

        let hydropathyValues = try parseJSONDataFromBundle(Hydro.self, from: "hydropathy")

        return JSONReferenceLibraries(enzymes: enzymes, hydropathyValues: hydropathyValues)
    }
}

// MARK: - App-side mutable store example

// @MainActor
// @Observable
// final class ReferenceLibraryStore {
//    var customAminoAcids: [AminoAcid] = []
//    var customModifications: [Modification] = []
//
//    var allAminoAcids: [AminoAcid] {
//        ReferenceLibraryDefaults.bundled.aminoAcids + customAminoAcids
//    }
//
//    var allModifications: [Modification] {
//        ReferenceLibraryDefaults.bundled.modifications + customModifications
//    }
//
//    func foo(named name: String) -> AminoAcid? {
//        allAminoAcids.first { $0.name == name }
//    }
//
//    func bar(named name: String) -> Modification? {
//        allModifications.first { $0.name == name }
//    }
//
//    func addCustomAminoAcid(_ foo: AminoAcid) {
//        customAminoAcids.append(foo)
//    }
//
//    func addCustomModification(_ bar: Modification) {
//        customModifications.append(bar)
//    }
// }
//
//// Library:
// ReferenceLibraryDefaults.bundled.aminoAcids
//
//// App:
// referenceLibraryStore.allAminoAcids

// public var dataLibrary = DataLibrary()
//
// public var aminoAcidLibrary: [AminoAcid] = dataLibrary.aminoAcids
// public var elementsLibrary: [ChemicalElement] = dataLibrary.elements
// public var enzymeLibrary: [Enzyme] = [unspecifiedEnzyme] + dataLibrary.enzymes
// public var hydropathyLibrary: [Hydro] = dataLibrary.hydropathy
// public var modificationLibrary: [Modification] = [zeroModification] + dataLibrary.modifications
//
// public enum LibraryType: Codable, Identifiable {
//    case aminoAcids
//    case elements
//    case enzymes
//    case hydropathy
//    case modifications
//
//    public var id: Self {
//        self
//    }
// }
//
// public struct DataLibrary: Codable {
//    public var aminoAcids: [AminoAcid] {
//        library(.aminoAcids)
//    }
//
//    public var elements: [ChemicalElement] {
//        library(.elements)
//    }
//
//    public var enzymes: [Enzyme] {
//        library(.enzymes)
//    }
//
//    public var hydropathy: [Hydro] {
//        library(.hydropathy)
//    }
//
//    public var modifications: [Modification] {
//        library(.modifications)
//    }
//
//    private func library<T: Decodable>(_ type: LibraryType) -> [T] {
//        do {
//            switch type {
//            case .aminoAcids:
//                return [] // populated in loadUnimod
//            case .modifications:
//                return [] // populated in loadUnimod
//            case .elements:
//                if loadElementsFromUnimod {
//                    return [] // populated in loadUnimod
//                } else {
//                    return try parseJSONDataFromBundle(from: "elements")
//                }
//
//            case .enzymes:
//                return try parseJSONDataFromBundle(from: "enzymes")
//
//            case .hydropathy:
//                return try parseJSONDataFromBundle(from: "hydropathy")
//            }
//        } catch {
//            debugPrint("Error occurred \(error)")
//        }
//
//        return []
//    }
// }
