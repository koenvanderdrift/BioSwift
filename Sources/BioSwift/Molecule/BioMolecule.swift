//
//  BioMolecule.swift
//
//
//  Created by Koen van der Drift on 5/9/21.
//  Copyright © 2021 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

/// BioMolecule is a protocol that contains a ``Chain`` array
public protocol BioMolecule {
    associatedtype ChainType: Chain

    var chains: [ChainType] {
        get set
    }
}

extension BioMolecule {
    public var formula: Formula {
        chains.reduce(zeroFormula) { $0 + $1.formula }
    }

    public func sequenceLength(for chainIndex: Int = 0) -> Int {
        chains[chainIndex].numberOfResidues
    }

    public func residues(for chainIndex: Int = 0) -> [any Residue] {
        return chains[chainIndex].residues
    }

    public func sequence(for chainIndex: Int = 0) -> String {
        chains[chainIndex].sequenceString
    }

    public func residueLocations(for chainIndex: Int = 0, with identifiers: [String]) -> [Int] {
        guard chains.indices.contains(chainIndex) else {
            return []
        }

        return chains[chainIndex].residueLocations(with: Set(identifiers))
    }

    public func countResidues(for chainIndex: Int = 0) -> NSCountedSet {
        chains[chainIndex].countAllResidues()
    }

    public func countOneResidue(with identifier: String, for chainIndex: Int = 0) -> Int {
        chains[chainIndex].countOneResidue(with: identifier)
    }

    public func isoelectricPoint(chainIndex index: Int = 0) -> Double {
        return Hydropathy(residues: chains[index].residues).isoElectricPoint()
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

    public mutating func addModification(mod: Modification, at loc: Int, for chainIndex: Int = 0) {
        chains[chainIndex].addModification(mod, at: loc)
    }

    public mutating func removeModification(at loc: Int, for chainIndex: Int = 0) {
        chains[chainIndex].removeModification(at: loc)
    }

    public mutating func modifyResidues(for identifier: String, with modification: Modification, for chainIndex: Int = 0) {
        guard chains.indices.contains(chainIndex) else { return }

        chains[chainIndex].modifyResidues(for: identifier, with: modification)
    }

    public mutating func removeModifications(for identifier: String, for chainIndex: Int = 0) {
        guard chains.indices.contains(chainIndex) else { return }

        chains[chainIndex].removeModifications(for: identifier)
    }
}

extension BioMolecule where ChainType: MassRepresentable {
    public func neutralMasses() -> MassContainer {
        chains.reduce(zeroMass) { $0 + $1.masses }
    }
}

extension BioMolecule where Self: Ionizable, ChainType: Ionizable {
    public var masses: MassContainer {
        massOverCharge()
    }

    public var charge: Charge {
        chains.reduce(0) { $0 + $1.charge }
    }

    public func calculateMasses() -> MassContainer {
        chains.reduce(zeroMass) { $0 + $1.massOverCharge() }
    }

    public func monoIsotopicMass() -> Dalton {
        return pseudomolecularIon().monoisotopicMass
    }

    public func averageMass() -> Dalton {
        return pseudomolecularIon().averageMass
    }

    public func selectedMonoIsotopicMass(chainIndex index: Int = 0, _ range: Range<Int>) -> Dalton {
        return selectionMass(chainIndex: index, range).monoisotopicMass
    }

    public func selectedAverageMass(chainIndex index: Int = 0, _ range: Range<Int>) -> Dalton {
        return selectionMass(chainIndex: index, range).averageMass
    }

    public func selectionMass(chainIndex index: Int = 0, _ range: Range<Int>) -> MassContainer {
        var sub = chains[index].subChain(range: range)

        if charge > 0 {
            sub.setAdducts(type: protonAdduct, count: charge)
        }

        return sub.pseudomolecularIon()
    }

    public mutating func setAdducts(type: Adduct, count: Int, for chainIndex: Int = 0) {
        guard chains.indices.contains(chainIndex) else { return }

        adducts = Array(repeating: type, count: count)
    }
}
