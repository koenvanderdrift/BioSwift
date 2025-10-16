//
//  BioMolecule.swift
//
//
//  Created by Koen van der Drift on 5/9/21.
//  Copyright © 2021 - 2024 Koen van der Drift. All rights reserved.
//

import Foundation

public struct BioMolecule {
    public var adducts: [Adduct] = []
    public var chains: [any Chain]

    public init(chain: any Chain) {
        self.init(chains: [chain])
    }

    public init(chains: [any Chain]) {
        self.chains = chains
    }
}

extension BioMolecule: Chargeable {
    public var masses: MassContainer {
        calculateMasses()
    }

    public var charge: Int {
        if let chargeableChains = chains as? [Chargeable] {
            return chargeableChains.reduce(0) { $0 + $1.charge }
        }

        return 0
    }

    public func calculateMasses() -> MassContainer {
        if let chargeableChains = chains as? [Chargeable] {
            return chargeableChains.reduce(zeroMass) { $0 + $1.masses }
        }

        return zeroMass
    }
}

public extension BioMolecule {
    func monoIsotopicMass() -> Double {
        return pseudomolecularIon().monoisotopicMass
    }

    func averageMass() -> Double {
        return pseudomolecularIon().averageMass
    }

    func isoelectricPoint(chainIndex index: Int = 0) -> Double {
        return Hydropathy(residues: chains[index].residues).isoElectricPoint()
    }

    func selectedMonoIsotopicMass(chainIndex _: Int = 0, _ range: ChainRange) -> Double {
        return selectionMass(range).monoisotopicMass
    }

    func selectedAverageMass(chainIndex _: Int = 0, _ range: ChainRange) -> Double {
        return selectionMass(range).averageMass
    }

    func selectionMass(chainIndex index: Int = 0, _ range: ChainRange) -> MassContainer {
        guard var sub = chains[index].subChain(with: range) as? Chargeable else { return zeroMass }

        sub.setAdducts(type: protonAdduct, count: charge)

        return sub.pseudomolecularIon()
    }

    func selectedIsoelectricPoint(chainIndex index: Int = 0, _ range: ChainRange) -> Double {
        guard let sub = chains[index].subChain(with: range) else { return 0.0 }

        return Hydropathy(residues: sub.residues).isoElectricPoint()
    }

    func selectionLength(chainIndex index: Int = 0, _ range: ChainRange) -> Int {
        guard let sub = chains[index].subChain(with: range) else { return 0 }

        return sub.numberOfResidues
    }
}

public extension BioMolecule {
    var formula: Formula {
        chains.reduce(zeroFormula) { $0 + $1.formula }
    }

    func sequenceLength(for chainIndex: Int = 0) -> Int {
        chains[chainIndex].numberOfResidues
    }

    func residues(for chainIndex: Int = 0) -> [any Residue] {
//        if let residues = chains[chainIndex].residues {
//            return residues
//        }

        return chains[chainIndex].residues
    }

    func sequence(for chainIndex: Int = 0) -> String {
        chains[chainIndex].sequenceString
    }

    mutating func setAdducts(type: Adduct, count: Int, for chainIndex: Int = 0) {
        if var chain = chains[chainIndex] as? Chargeable {
            chain.setAdducts(type: type, count: count)
            adducts = [Adduct](repeating: type, count: count)
        }
    }

    func countAllResidues(for chainIndex: Int = 0) -> NSCountedSet {
        chains[chainIndex].countAllResidues()
    }

    func countOneResidue(with identifier: String, for chainIndex: Int = 0) -> Int {
        let countedResidues = countAllResidues(for: chainIndex)
        
        if let res = chains[chainIndex].library
            .first(where: { $0.identifier == identifier }) {
            return countedResidues.count(for: res)
        }
        
        return 0
    }



    func residueLocations(for chainIndex: Int = 0, with identifiers: [String]) -> [Int] {
        let result = identifiers.map { i in
            chains[chainIndex].sequenceString.indicesOf(string: i)
        }

        return result.flatMap { $0 }
    }
}
