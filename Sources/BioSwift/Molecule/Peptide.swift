//
//  Peptide.swift
//  
//
//  Created by Koen van der Drift on 7/19/21.
//

import Foundation

public typealias Peptide = PolyPeptide

//public struct Peptide: RangedChain {
//    public var residues: [AminoAcid] = []
//
//    public var name: String = ""
//    public var symbolLibrary: [Symbol] = uniAminoAcids
//
//    public var termini: (first: Residue, last: Residue)? = (nTerm, cTerm)
//    public var modifications: ModificationSet = ModificationSet()
//    public var adducts: [Adduct] = []
//
//    public var rangeInParent: ChainRange = zeroChainRange
//}
//extension Peptide {
//    public init(sequence: String) {
//        self.residues = createResidues(from: sequence)
//    }
//    
//    public init(residues: [AminoAcid]) {
//        self.residues = residues
//    }
//}
//
//extension Peptide: Mass {
//    public var masses: MassContainer {
//        return calculateMasses()
//    }
//    
//    public func calculateMasses() -> MassContainer {
//        return mass(of: residues) + terminalMasses()
//    }
//}

//extension Peptide: Chargeable {}
