//
//  BioMolecule2.swift
//  
//
//  Created by Koen van der Drift on 1/24/24.
//

import Foundation

public struct BioMolecule2<T: Residue> {
    public var name: String = ""
    public var chains: [Chain2] = []
}

public struct Chain2: Structure {
    public var name: String
    public var formula: Formula
    public var masses: MassContainer
    public var adducts: [Adduct] // should this be in mass?

    var symbolLibrary: [Symbol] // this should not be a property of each chain

    var residues: [Residue]

    var termini: (first: Residue, last: Residue)?

    var modifications: [LocalizedModification]

//    init(sequence: String)
//    init(residues: [ResidueType])
}


