//
//  DataLibraries.swift
//  BioSwift
//
//  Created by Koen van der Drift on 1/29/22.
//  Copyright © 2022 - 2025 Koen van der Drift. All rights reserved.

import Foundation

public var loadElementsFromUnimod: Bool = false

// 1. Add Sendable to simple value structs.
// 2. Introduce DataLibraries as the immutable bundled snapshot.
// 3. Make XML/JSON loaders return partial results instead of mutating globals.
// 4. Combine into DataLibraryDefaults.bundled.
// 5. Keep old names as computed aliases only if needed.
// 6. Move user-editable additions into an app-side Store later.

// MARK: - public globals

public var aminoAcidLibrary: [AminoAcid] {
    DataLibraryDefaults.bundled.aminoAcids
}

public var modificationLibrary: [Modification] {
    DataLibraryDefaults.bundled.modifications + [zeroModification]
}

public var elementLibrary: [ChemicalElement] {
    ElementsLibraryDefaults.bundled
}

public var enzymeLibrary: [Enzyme] {
    DataLibraryDefaults.bundled.enzymes + [unspecifiedEnzyme]
}

// @available(*, deprecated, message: "Use DataLibraryDefaults.bundled.modifications instead.")
public var hydropathyLibrary: [Hydro] {
    DataLibraryDefaults.bundled.hydropathyValues
}

// MARK: - Final public bundled-data snapshot

public struct DataLibraries: Sendable {
    public let elements: [ChemicalElement]
    public let aminoAcids: [AminoAcid]
    public let modifications: [Modification]
    public let enzymes: [Enzyme]
    public let hydropathyValues: [Hydro]

    public init(
        elements: [ChemicalElement],
        aminoAcids: [AminoAcid],
        modifications: [Modification],
        enzymes: [Enzyme],
        hydropathyValues: [Hydro])
    {
        self.elements = elements
        self.aminoAcids = aminoAcids
        self.modifications = modifications
        self.enzymes = enzymes
        self.hydropathyValues = hydropathyValues
    }
}

// MARK: - Public access point

public enum DataLibraryDefaults {
    public static let bundled: DataLibraries = {
        do {
            return try DataLibraryLoader.load()
        } catch {
            fatalError("Failed to load bundled data libraries: \(error)")
        }
    }()

    public static func loadBundled() throws -> DataLibraries {
        try DataLibraryLoader.load()
    }

    public enum ElementsLibraryDefaults {
        public static let bundled: [ChemicalElement] = {
            do {
                return try JSONDataLibraryLoader.loadElements()
            } catch {
                fatalError("Failed to load bundled foo library: \(error)")
            }
        }()
    }
}

public enum ElementsLibraryDefaults {
    public static let bundled: [ChemicalElement] = {
        do {
            return try JSONDataLibraryLoader.loadElements()
        } catch {
            fatalError("Failed to load bundled elements library: \(error)")
        }
    }()
}



// MARK: - Combined loader

enum DataLibraryLoader {
    static func load() throws -> DataLibraries {
        let elements = ElementsLibraryDefaults.bundled
        let jsonLibraries = try JSONDataLibraryLoader.loadOtherLibraries()

        let xmlLibraries = try XMLDataLibraryLoader.load()

        return DataLibraries(
            elements: elements,
            aminoAcids: xmlLibraries.aminoAcids,
            modifications: xmlLibraries.modifications,
            enzymes: jsonLibraries.enzymes,
            hydropathyValues: jsonLibraries.hydropathyValues)
    }
}

// MARK: - Partial XML result

struct XMLDataLibraries {
    let aminoAcids: [AminoAcid]
    let modifications: [Modification]
}

// MARK: - XML loader

enum XMLDataLibraryLoader {
    static func load() throws -> XMLDataLibraries {
        let data = try loadData(
            from: "unimod",
            withExtension: "xml",
            in: .module)

        let parser = UnimodXMLParser()
        return try parser.parse(data: data)
    }

    /// Handy for tests with custom XML data.
    static func parse(data: Data) throws -> XMLDataLibraries {
        let parser = UnimodXMLParser()
        return try parser.parse(data: data)
    }
}

// MARK: - Partial JSON result

struct JSONDataLibraries {
    let enzymes: [Enzyme]
    let hydropathyValues: [Hydro]
}

// MARK: - JSON loader

enum JSONDataLibraryLoader {
    // parse elements first before anything else.
    
    static func loadElements() throws -> [ChemicalElement] {
        try parseJSONDataFromBundle(ChemicalElement.self, from: "elements")
    }

    static func loadOtherLibraries() throws -> JSONDataLibraries {
        let enzymes = try parseJSONDataFromBundle(
            Enzyme.self,
            from: "enzymes")

        let hydropathyValues = try parseJSONDataFromBundle(
            Hydro.self,
            from: "hydropathy")

        return JSONDataLibraries(
            enzymes: enzymes,
            hydropathyValues: hydropathyValues)
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
//        DataLibraryDefaults.bundled.aminoAcids + customAminoAcids
//    }
//
//    var allModifications: [Modification] {
//        DataLibraryDefaults.bundled.modifications + customModifications
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
// DataLibraryDefaults.bundled.aminoAcids
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
