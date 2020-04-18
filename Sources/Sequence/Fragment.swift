//
//  Fragment.swift
//  BioSwift
//
//  Created by Koen van der Drift on 4/12/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public enum FragmentType {
    case precursor
    case immonium
    case nTerminal
    case cTerminal
    case undefined
}

public class Fragment: Peptide {
    public let fragmentType: FragmentType

    public init(residues: [Residue], type: FragmentType) {
        fragmentType = type

        super.init(residues: residues, library: uniAminoAcids)
    }

    public init(sequence: String, type: FragmentType) {
        fragmentType = type

        super.init(sequence: sequence)
    }

    public required init(residues _: [Residue], library _: [Symbol]) {
        fatalError("init(residues:library:) has not been implemented")
    }

    override func terminalMasses() -> MassContainer {
        var result = zeroMass
        if fragmentType == .nTerminal {
            result -= (hydrogen.masses + hydroxyl.masses)
        }

        return result
    }
}
