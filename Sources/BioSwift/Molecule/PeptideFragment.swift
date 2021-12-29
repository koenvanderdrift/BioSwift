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

public protocol Fragmentable {
    var fragmentType: FragmentType { get set }
}

public struct PeptideFragment: RangedChain & Fragmentable {
    public var name: String = ""
    public var symbolLibrary: [Symbol] = uniAminoAcids
    
    public var residues: [AminoAcid] = []
    
    public var termini: (first: AminoAcid, last: AminoAcid)? = (nTerm, cTerm)
    public var adducts: [Adduct] = []

    public var rangeInParent: ChainRange = zeroChainRange

    public var fragmentType: FragmentType = .undefined
}

extension PeptideFragment {
    public init(sequence: String) {
        self.residues = createResidues(from: sequence)
    }
    
    public init(residues: [AminoAcid]) {
        self.residues = residues
    }

    public init(residues: [AminoAcid], type: FragmentType, adducts: [Adduct]) {
        self.residues = residues
        self.fragmentType = type
        self.adducts = adducts
    }
}

extension PeptideFragment: Mass & Chargeable {
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
