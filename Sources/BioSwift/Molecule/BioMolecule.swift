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
    public var chains: [Chain]

    public init(chain: Chain) {
        self.init(chains: [chain])
    }

    public init(chains: [Chain]) {
        self.chains = chains
    }
}

extension BioMolecule: Chargeable {
    public var masses: MassContainer {
        calculateMasses()
    }

    public var charge: Int {
        chains.reduce(0) { $0 + $1.charge }
    }

    public func calculateMasses() -> MassContainer {
        return chains.reduce(zeroMass) { $0 + $1.masses }
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
        guard var sub = chains[index].subChain(with: range) else { return zeroMass }

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
        chains[chainIndex].setAdducts(type: type, count: count)
        adducts = [Adduct](repeating: type, count: count)
    }

    func countResidues(for chainIndex: Int = 0) -> [any Residue : Int] {
        let residues = residues(for: chainIndex)
        let groupedResidues = Dictionary(grouping: residues, by: { $0 })
            .mapValues { residues in residues.count }

        return groupedResidues
    }

    func residueLocations(for chainIndex: Int = 0, with identifiers: [String]) -> [Int] {
        let result = identifiers.map { i in
            chains[chainIndex].sequenceString.indicesOf(string: i)
        }

        return result.flatMap { $0 }
    }
}

// public struct BioMolecule2<T: Residue> {
//    public var name: String = ""
//    public var info: String = ""
//    public var masses: MassContainer = zeroMass
//    public var adducts: [Adduct] = []
//
//    public var chains: [Chain<T>] = []
// }
//
// public extension BioMolecule {
//    init(residues: [T]) {
//        self.init(chain: Chain<T>(residues: residues))
//    }
//
//    init(sequence: String) {
//        self.init(chain: Chain<T>(sequence: sequence))
//    }
//
//    init(chain: Chain<T>) {
//        self.init(chains: [chain])
//    }
//
//    init(chains: [Chain<T>]) {
//        self.chains = chains
//    }
//
//    func sequenceLength(chainIndex index: Int = 0) -> Int {
//        chains[index].numberOfResidues()
//    }
//
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
//        var chain: Chain<T>
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
//        var chain: Chain<T>
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
//    func concatenateChains() -> Chain<T> {
//        let residues = chains.reduce([]) { $0 + $1.residues }
//
//        return Chain<T>(residues: residues)
//    }
// }
//
//
//// Convenience accessors
// public extension BioMolecule {
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
// }
