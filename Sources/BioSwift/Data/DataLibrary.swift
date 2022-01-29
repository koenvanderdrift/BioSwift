//
//  DataLibrary.swift
//  BioSwift
//
//  Created by Koen van der Drift on 1/29/22.
//

import Foundation

public var dataLibrary = DataLibrary()

public var aminoAcidLibrary: [AminoAcid] = dataLibrary.library(with: .aminoAcid)
public var elementLibrary: [ChemicalElement] = dataLibrary.library(with: .element)
public var enzymeLibrary: [Enzyme] = dataLibrary.library(with: .enzyme)
public var hydropathyLibrary: [Hydro] = dataLibrary.library(with: .hydropathy)
public var modificationLibrary: [Modification] = dataLibrary.library(with: .modification)

public enum LibraryType {
    case aminoAcid
    case element
    case enzyme
    case hydropathy
    case modification
}

public struct DataLibrary {
    private var unimodController = UnimodController()
    
    public func library<T: Decodable>(with type: LibraryType) -> [T] {
        do {
            switch type {
//            case .aminoAcid: todo
//            case .modification: todo
            case .element:
                return try parseJSONDataFromBundle(from: "elements")
            case .enzyme:
                return try parseJSONDataFromBundle(from: "enzymes")
            case .hydropathy:
                return try parseJSONDataFromBundle(from: "hydropathy")
            default:
                return []
            }
        } catch {
            print("Error occurred \(error)")
        }
        
        return []
    }
    
    public func loadUnimod(withCompletion completion: @escaping (Bool) -> Void) {
        unimodController.loadUnimod { success in
            completion(success)
        }
    }
}
