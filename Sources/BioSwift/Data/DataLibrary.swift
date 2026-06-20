//
//  DataLibrary.swift
//  BioSwift
//
//  Created by Koen van der Drift on 1/29/22.
//  Copyright © 2022 - 2025 Koen van der Drift. All rights reserved.

import Foundation

public var loadElementsFromUnimod: Bool = false

public var dataLibrary = DataLibrary()

public var aminoAcidLibrary: [AminoAcid] = dataLibrary.aminoAcids
public var elementLibrary: [ChemicalElement] = dataLibrary.elements
public var enzymeLibrary: [Enzyme] = [unspecifiedEnzyme] + dataLibrary.enzymes
public var hydropathyLibrary: [Hydro] = dataLibrary.hydropathy
public var modificationLibrary: [Modification] = [zeroModification] + dataLibrary.modifications

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
                    return []  // populated in loadUnimod
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
