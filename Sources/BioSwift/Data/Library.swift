//
//  Library.swift
//  BioSwift
//
//  Created by Koen van der Drift on 1/29/22.
//

import Foundation

public var aminoAcidLibrary: [AminoAcid] = Library<AminoAcid>(type: .aminoAcid).library
public var elementLibrary: [ChemicalElement] = Library<ChemicalElement>(type: .element).library
public var enzymeLibrary: [Enzyme] = Library<Enzyme>(type: .enzyme).library
public var hydropathyLibrary: [Hydro] = Library<Hydro>(type: .hydropathy).library
public var modificationLibrary: [Modification] = Library<Modification>(type: .modification).library

public struct Library<T: Decodable> {
    public var library: [T]
    
    enum LibraryType {
        case aminoAcid
        case element
        case enzyme
        case hydropathy
        case modification
    }
    
    init(type: LibraryType) {
        switch type {
        case .aminoAcid:
            library = []
        case .element:
            library = try! parseJSONDataFromBundle(from: "elements")
        case .enzyme:
            library = try! parseJSONDataFromBundle(from: "enzymes")
        case .hydropathy:
            library = try! parseJSONDataFromBundle(from: "hydropathy")
        case .modification:
            library = []
        }
    }
}
