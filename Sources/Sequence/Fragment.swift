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

public struct Fragment: RangeableSequence {
    public var symbolLibrary: [Symbol] = uniAminoAcids
    public var residues: [Residue] = []
    public var termini: (first: Residue, last: Residue)? = (nTerm, cTerm)

    public var modifications: ModificationSet = ModificationSet()
    public var adducts: [Adduct] = []

    public var rangeInParent: Range<Int> = zeroSequenceRange
    public var zeroResidue: Residue = zeroAminoAcid

    public var fragmentType: FragmentType = .undefined
}

extension Fragment {
    public init(sequence: String) {
        self.residues = createResidues(from: sequence)
    }
    
    public init(residues: [Residue]) {
        self.residues = residues
    }

    public init(residues: [Residue], type: FragmentType, adducts: [Adduct]) {
        self.residues = residues
        self.fragmentType = type
        self.adducts = adducts
    }
}

extension Fragment: Chargeable {
    public var masses: MassContainer {
        return calculateMasses()
    }
    
    public func calculateMasses() -> MassContainer {
        return mass(of: residues) + terminalMasses()
    }
    
    public func terminalMasses() -> MassContainer {
        var result = zeroMass
        if fragmentType == .nTerminal {
            result -= (hydrogen.masses + hydroxyl.masses)
        }
        
        return result
    }
}
