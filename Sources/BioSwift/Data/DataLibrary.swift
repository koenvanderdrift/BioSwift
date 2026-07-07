//
//  DataLibrary.swift
//  BioSwift
//
//  Created by Koen van der Drift on 1/29/22.
//  Copyright © 2022 - 2025 Koen van der Drift. All rights reserved.

import Foundation

public var loadElementsFromUnimod: Bool = false

public var dataLibrary = DataLibrary()

//public var aminoAcidLibrary: [AminoAcid] = dataLibrary.aminoAcids
public var elementLibrary: [ChemicalElement] = dataLibrary.elements
public var enzymeLibrary: [Enzyme] = [unspecifiedEnzyme] + dataLibrary.enzymes
public var hydropathyLibrary: [Hydro] = dataLibrary.hydropathy
//public var modificationLibrary: [Modification] = [zeroModification] + dataLibrary.modifications

public enum LibraryType: Codable, Identifiable {
    case aminoAcids
    case elements
    case enzymes
    case hydropathy
    case modifications

    public var id: Self {
        self
    }
}

public struct DataLibrary: Codable {
    public var aminoAcids: [AminoAcid] {
        library(.aminoAcids)
    }

    public var elements: [ChemicalElement] {
        library(.elements)
    }

    public var enzymes: [Enzyme] {
        library(.enzymes)
    }

    public var hydropathy: [Hydro] {
        library(.hydropathy)
    }

    public var modifications: [Modification] {
        library(.modifications)
    }

    private func library<T: Decodable>(_ type: LibraryType) -> [T] {
        do {
            switch type {
            case .aminoAcids:
                return [] // populated in loadUnimod
            case .modifications:
                return [] // populated in loadUnimod
            case .elements:
                if loadElementsFromUnimod {
                    return [] // populated in loadUnimod
                } else {
                    return try parseJSONDataFromBundle(from: "elements")
                }

            case .enzymes:
                return try parseJSONDataFromBundle(from: "enzymes")

            case .hydropathy:
                return try parseJSONDataFromBundle(from: "hydropathy")
            }
        } catch {
            print("Error occurred \(error)")
        }

        return []
    }
}

// 1. Add Sendable to simple value structs.
// 2. Introduce DataLibraries as the immutable bundled snapshot.
// 3. Make XML/JSON loaders return partial results instead of mutating globals.
// 4. Combine into DataLibraryDefaults.bundled.
// 5. Keep old names as computed aliases only if needed.
// 6. Move user-editable additions into an app-side Store later.

// MARK: - Final public bundled-data snapshot

public struct DataLibraries: Sendable {
    public let aminoAcids: [AminoAcid]
    public let modifications: [Modification]
    public let enzymes: [Enzyme]

    public init(
        aminoAcids: [AminoAcid],
        modifications: [Modification],
        enzymes: [Enzyme])
    {
        self.aminoAcids = aminoAcids
        self.modifications = modifications
        self.enzymes = enzymes
    }
}

// MARK: - Public access point

public enum DataLibraryDefaults {
    /// Public immutable bundled defaults.
    public static let bundled: DataLibraries = {
        do {
            return try DataLibraryLoader.load()
        } catch {
            fatalError("Failed to load bundled data libraries: \(error)")
        }
    }()

    /// Useful for tests/debugging because it throws instead of trapping.
    public static func loadBundled() throws -> DataLibraries {
        try DataLibraryLoader.load()
    }
}

// MARK: - Optional compatibility aliases

// These replace old public globals like:
// public var fooLibrary: [AminoAcid] = ...
//
// They are computed, not stored mutable globals.

//@available(*, deprecated, message: "Use DataLibraryDefaults.bundled.aminoAcids instead.")
public var aminoAcidsLibrary: [AminoAcid] {
    DataLibraryDefaults.bundled.aminoAcids
}

//@available(*, deprecated, message: "Use DataLibraryDefaults.bundled.modifications instead.")
public var modificationsLibrary: [Modification] {
    DataLibraryDefaults.bundled.modifications
}

// MARK: - Combined loader

enum DataLibraryLoader {
    static func load() throws -> DataLibraries {
        let xmlLibraries = try XMLDataLibraryLoader.load()
        let jsonLibraries = try JSONDataLibraryLoader.load()

        return DataLibraries(
            aminoAcids: xmlLibraries.aminoAcids,
            modifications: xmlLibraries.modifications,
            enzymes: jsonLibraries.enzymes)
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
    let elements: [ChemicalElement]
    let hydropathyvalues: [Hydro]
}

// MARK: - JSON loader

enum JSONDataLibraryLoader {
    static func load() throws -> JSONDataLibraries {
        let enzymes = try parseJSONDataFromBundle(
            Enzyme.self,
            from: "enzymes")

        let elements = try parseJSONDataFromBundle(
            ChemicalElement.self,
            from: "elements")

        let hydropathyvalues = try parseJSONDataFromBundle(
            Hydro.self,
            from: "hydropathy")

        return JSONDataLibraries(
            enzymes: enzymes,
            elements: elements,
            hydropathyvalues: hydropathyvalues)
    }
}

// MARK: - JSON helper

func parseJSONDataFromBundle<A: Decodable>(
    _: A.Type,
    from fileName: String) throws -> [A]
{
    let fullName = "\(fileName).json"

    let data = try loadData(
        from: fileName,
        withExtension: "json",
        in: .module)

    do {
        return try JSONDecoder().decode([A].self, from: data)
    } catch {
        throw LoadError.fileDecodingFailed(
            name: fullName,
            underlyingError: error)
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
