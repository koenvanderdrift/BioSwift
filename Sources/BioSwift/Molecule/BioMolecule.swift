//
//  BioMolecule.swift
//
//
//  Created by Koen van der Drift on 5/9/21.
//

import Foundation

public struct BioMolecule<T: Residue>: Structure {
    public var name: String = ""
    public var info: String = ""
    public var masses: MassContainer = zeroMass
    public var adducts: [Adduct] = []

    public var chains: [Chain<T>] = []
}

public extension BioMolecule {
    init(residues: [T]) {
        self.init(chain: Chain<T>(residues: residues))
    }

    init(sequence: String) {
        self.init(chain: Chain<T>(sequence: sequence))
    }

    init(chain: Chain<T>) {
        self.init(chains: [chain])
    }

    init(chains: [Chain<T>]) {
        self.chains = chains
    }
    
    func sequenceLength(chainIndex index: Int = 0) -> Int {
        chains[index].numberOfResidues()
    }
    
    var formula: Formula {
        chains.reduce(zeroFormula) { $0 + $1.formula }
    }

    var residues: [Residue] {
        chains.reduce([]) { $0 + $1.residues }
    }

    var charge: Int {
        chains.reduce(0) { $0 + $1.charge }
    }
    
    func mass(chainIndex index: Int = -1) -> MassContainer {
        var chain: Chain<T>

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
        var chain: Chain<T>

        if index == -1 { // calculate for all chains when index = -1
            chain = concatenateChains()
        } else {
            chain = chains[index]
        }

        return Hydropathy(residues: chain.residues).isoElectricPoint()
    }
    
    func concatenateChains() -> Chain<T> {
        let residues = chains.reduce([]) { $0 + $1.residues }

        return Chain<T>(residues: residues)
    }
}


//// Convenience accessors
//public extension BioMolecule {
//    var formula: Formula {
//        chains.reduce(zeroFormula) { $0 + $1.formula }
//    }
//
//    var residues: [Residue] {
//        chains.reduce([]) { $0 + $1.residues }
//    }
//
//    var charge: Int {
//        chains.reduce(0) { $0 + $1.charge }
//    }
//
//    func mass(chainIndex index: Int = -1) -> MassContainer {
//        var chain: T
//
//        if index == -1 { // calculate for all chains when index = -1
//            chain = concatenateChains()
//        } else {
//            chain = chains[index]
//        }
//
//        chain.setAdducts(type: protonAdduct, count: charge)
//
//        return chain.pseudomolecularIon()
//    }
//
//    func selectionMass(chainIndex index: Int = 0, _ range: ChainRange) -> MassContainer {
//        guard var sub = chains[index].subChain(with: range) else { return zeroMass }
//
//        sub.setAdducts(type: protonAdduct, count: charge)
//
//        return sub.pseudomolecularIon()
//    }
//
//    func isoelectricPoint(chainIndex index: Int = -1) -> Double {
//        var chain: T
//
//        if index == -1 { // calculate for all chains when index = -1
//            chain = concatenateChains()
//        } else {
//            chain = chains[index]
//        }
//
//        return Hydropathy(residues: chain.residues).isoElectricPoint()
//    }
//
//    func selectionIsoelectricPoint(chainIndex index: Int = 0, _ range: ChainRange) -> Double {
//        guard let sub = chains[index].subChain(with: range) else { return 0.0 }
//
//        return Hydropathy(residues: sub.residues).isoElectricPoint()
//    }
//
//    func sequenceString(chainIndex index: Int = 0) -> String {
//        chains[index].sequenceString
//    }
//
//    func selectionString(chainIndex index: Int = 0, range: ChainRange) -> String {
//        guard let sub = chains[index].subChain(with: range) else { return "" }
//
//        return sub.sequenceString
//    }
//
//    func sequenceLength(chainIndex index: Int = 0) -> Int {
//        chains[index].numberOfResidues()
//    }
//
//    func selectionLength(chainIndex index: Int = 0, range: ChainRange) -> Int {
//        guard let sub = chains[index].subChain(with: range) else { return 0 }
//
//        return sub.numberOfResidues()
//    }
//
//    func concatenateChains() -> T {
//        let residues = chains.reduce([]) { $0 + $1.residues }
//
//        return T(residues: residues)
//    }
//}
