//
//  NucleicAcid.swift
//  BioSwift
//

import Foundation

public protocol NucleicAcidChain: Chain, Structure where ResidueType == Nucleotide {}

extension NucleicAcidChain {
    public var formula: Formula {
        guard !residues.isEmpty else { return zeroFormula }

        return residues.reduce(water.formula) { result, residue in
            result + residue.formula + (residue.modification?.formula ?? zeroFormula)
        }
    }

}
