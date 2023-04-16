//
//  DataLibrary.swift
//  BioSwift
//
//  Created by Koen van der Drift on 1/29/22.
//

import Foundation

public var dataLibrary = DataLibrary()

public var aminoAcidLibrary: [AminoAcid] = dataLibrary.aminoAcids
public var elementLibrary: [ChemicalElement] = dataLibrary.elements
public var enzymeLibrary: [Enzyme] = dataLibrary.enzymes
public var hydropathyLibrary: [Hydro] = dataLibrary.hydropathy
public var modificationLibrary: [Modification] = dataLibrary.modifications

public struct DataLibrary {
    private enum LibraryType {
        case aminoAcids
        case elements
        case enzymes
        case hydropathy
        case modifications
    }

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
                return try parseJSONDataFromBundle(from: "elements")
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

    public func loadUnimod() throws {
        try UnimodController().loadUnimod()
    }
}
