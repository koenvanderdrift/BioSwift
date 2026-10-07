//
//  NucleicAcid.swift
//  BioSwift
//

import Foundation

public protocol NucleicAcidChain: Chain, Structure {}

extension NucleicAcidChain {
    public var formula: Formula {
        guard !residues.isEmpty else { return zeroFormula }

        return residues.reduce(water.formula) { result, residue in
            result + residue.formula + (residue.modification?.formula ?? zeroFormula)
        }
    }

    public var massContainer: MassContainer {
        masses.applying(adducts: adducts)
    }

    var masses: MassContainer {
        guard !residues.isEmpty else { return zeroMass }

        return residues.reduce(water.masses) { result, residue in
            result + residue.masses
        }
    }
}
