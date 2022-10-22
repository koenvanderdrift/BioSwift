//
//  BioMolecule.swift
//
//
//  Created by Koen van der Drift on 5/9/21.
//

import Foundation

public struct BioMolecule<T: Chain> {
    public var name: String = ""
    public var chains: [T] = []
}

public extension BioMolecule {
    init(residues: [T.ResidueType]) {
        self.init(chain: T(residues: residues))
    }

    init(sequence: String) {
        self.init(chain: T(sequence: sequence))
    }

    init(chain: T) {
        self.init(chains: [chain])
    }

    init(chains: [T]) {
        self.chains = chains
    }
}

// Convenience accessors
public extension BioMolecule {
    var formula: Formula {
        return chains.reduce(zeroFormula) { $0 + $1.formula }
    }

    var residues: [Residue] {
        return chains.reduce([]) { $0 + $1.residues }
    }

    var charge: Int {
        return chains.reduce(0) { $0 + $1.charge }
    }

    func mass(chainIndex index: Int = -1) -> MassContainer {
        var chain: T

        if index == -1 { // calculate for all chains when index = -1
            chain = concatenateChains()
        } else {
            chain = chains[index]
        }

        chain.setAdducts(type: protonAdduct, count: charge)

        return chain.pseudomolecularIon()
    }

    func selectionMass(chainIndex index: Int = 0, _ range: ChainRange) -> MassContainer {
        guard var sub = chains[index].subChain(with: range) else { return zeroMass }

        sub.setAdducts(type: protonAdduct, count: charge)

        return sub.pseudomolecularIon()
    }

    func isoelectricPoint(chainIndex index: Int = -1) -> Double {
        var chain: T

        if index == -1 { // calculate for all chains when index = -1
            chain = concatenateChains()
        } else {
            chain = chains[index]
        }

        return Hydropathy(residues: chain.residues).isoElectricPoint()
    }

    func selectionIsoelectricPoint(chainIndex index: Int = 0, _ range: ChainRange) -> Double {
        guard let sub = chains[index].subChain(with: range) else { return 0.0 }

        return Hydropathy(residues: sub.residues).isoElectricPoint()
    }

    func sequenceString(chainIndex index: Int = 0) -> String {
        return chains[index].sequenceString
    }

    func selectionString(chainIndex index: Int = 0, range: ChainRange) -> String {
        guard let sub = chains[index].subChain(with: range) else { return "" }

        return sub.sequenceString
    }

    func sequenceLength(chainIndex index: Int = 0) -> Int {
        return chains[index].numberOfResidues()
    }

    func selectionLength(chainIndex index: Int = 0, range: ChainRange) -> Int {
        guard let sub = chains[index].subChain(with: range) else { return 0 }

        return sub.numberOfResidues()
    }

    func concatenateChains() -> T {
        let residues = chains.reduce([]) { $0 + $1.residues }

        return T(residues: residues)
    }
}
