//
//  BioMolecule.swift
//
//
//  Created by Koen van der Drift on 5/9/21.
//  Copyright © 2021 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

/// BioMolecule is a protocol that contains a ``Chain`` array
public protocol BioMolecule: Chargeable {
    associatedtype ChainType: Chain

    var chains: [ChainType] { get set }
}

extension BioMolecule {
    public var masses: MassContainer { massOverCharge() }

    public var charge: Charge {
        if let chargeableChains = chains as? [Chargeable] {
            return chargeableChains.reduce(0) { $0 + $1.charge }
        }

        return 0
    }

    public func calculateMasses() -> MassContainer {
        if let chargeableChains = chains as? [Chargeable] {
            return chargeableChains.reduce(zeroMass) { $0 + $1.massOverCharge() }
        }

        return zeroMass
    }

    public func monoIsotopicMass() -> Dalton { return pseudomolecularIon().monoisotopicMass }

    public func averageMass() -> Dalton { return pseudomolecularIon().averageMass }

    public func isoelectricPoint(chainIndex index: Int = 0) -> Double {
        return Hydropathy(residues: chains[index].residues).isoElectricPoint()
    }

    public func selectedMonoIsotopicMass(chainIndex _: Int = 0, _ range: Range<Int>) -> Dalton {
        return selectionMass(range).monoisotopicMass
    }

    public func selectedAverageMass(chainIndex _: Int = 0, _ range: Range<Int>) -> Dalton {
        return selectionMass(range).averageMass
    }

    public func selectionMass(chainIndex index: Int = 0, _ range: Range<Int>) -> MassContainer {
        guard var sub = chains[index].subChain(range: range) as? Chargeable else { return zeroMass }

        if charge > 0 { sub.setAdducts(type: protonAdduct, count: charge) }

        return sub.pseudomolecularIon()
    }

    public func selectedIsoelectricPoint(chainIndex index: Int = 0, _ range: Range<Int>) -> Double {
        let sub = chains[index].subChain(range: range)
        guard sub.numberOfResidues > 0 else { return 0.0 }

        return Hydropathy(residues: sub.residues).isoElectricPoint()
    }

    public func selectionLength(chainIndex index: Int = 0, _ range: Range<Int>) -> Int {
        let sub = chains[index].subChain(range: range)

        return sub.numberOfResidues
    }
}

extension BioMolecule {
    public var formula: Formula { chains.reduce(zeroFormula) { $0 + $1.formula } }

    public func sequenceLength(for chainIndex: Int = 0) -> Int {
        chains[chainIndex].numberOfResidues
    }

    public func residues(for chainIndex: Int = 0) -> [any Residue] {
        return chains[chainIndex].residues
    }

    public func sequence(for chainIndex: Int = 0) -> String { chains[chainIndex].sequenceString }

    public func residueLocations(for chainIndex: Int = 0, with identifiers: [String]) -> [Int] {
        guard chains.indices.contains(chainIndex) else { return [] }

        return chains[chainIndex].residueLocations(with: Set(identifiers))
    }

    public func countResidues(for chainIndex: Int = 0) -> NSCountedSet {
        chains[chainIndex].countAllResidues()
    }

    public func countOneResidue(with identifier: String, for chainIndex: Int = 0) -> Int {
        chains[chainIndex].countOneResidue(with: identifier)
    }

    public mutating func setAdducts(type: Adduct, count: Int, for chainIndex: Int = 0) {
        if var chain = chains[chainIndex] as? Chargeable {
            adducts = Array(repeating: type, count: count)

            chain.setAdducts(adducts)
        }
    }

    public mutating func addModification(mod: Modification, at loc: Int, for chainIndex: Int = 0) {
        chains[chainIndex].addModification(mod, at: loc)
    }

    public mutating func removeModification(at loc: Int, for chainIndex: Int = 0) {
        chains[chainIndex].removeModification(at: loc)
    }

    public mutating func modifyResidues(
        for identifier: String, with modification: Modification, for chainIndex: Int = 0
    ) {
        guard chains.indices.contains(chainIndex) else { return }

        chains[chainIndex].modifyResidues(for: identifier, with: modification)
    }

    public mutating func removeModifications(for identifier: String, for chainIndex: Int = 0) {
        guard chains.indices.contains(chainIndex) else { return }

        chains[chainIndex].removeModifications(for: identifier)
    }
}
