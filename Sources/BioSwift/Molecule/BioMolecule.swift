//
//  BioMolecule.swift
//
//
//  Created by Koen van der Drift on 5/9/21.
//  Copyright © 2021 - 2026 Koen van der Drift. All rights reserved.
//

import Foundation

/// BioMolecule contains one or more typed ``Chain`` values.
public struct BioMolecule<ChainType: Chain> {
    public var adducts: [Adduct]
    public var chains: [ChainType]
    public var crossLinks: [CrossLink]

    public init(chains: [ChainType], adducts: [Adduct] = [], crossLinks: [CrossLink] = []) {
        self.chains = chains
        self.adducts = adducts
        self.crossLinks = crossLinks
    }
}

extension BioMolecule: Codable where ChainType: Codable {
    private enum CodingKeys: String, CodingKey {
        case adducts
        case chains
        case crossLinks
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        adducts = try container.decode([Adduct].self, forKey: .adducts)
        chains = try container.decode([ChainType].self, forKey: .chains)
        crossLinks = try container.decodeIfPresent([CrossLink].self, forKey: .crossLinks) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(adducts, forKey: .adducts)
        try container.encode(chains, forKey: .chains)
        try container.encode(crossLinks, forKey: .crossLinks)
    }
}

extension BioMolecule: Equatable where ChainType: Equatable {}

extension BioMolecule: Sendable where ChainType: Sendable {}

extension BioMolecule where ChainType: Structure {
    public var formula: Formula {
        let chainFormula = chains.reduce(zeroFormula) {
            $0 + $1.formula
        }

        return crossLinks.reduce(chainFormula) {
            $0 + $1.modification.formula
        }
    }
}

extension BioMolecule {
    /// Creates and adds a validated cross-link between two residues.
    @discardableResult
    public mutating func addCrossLink(
        modification: Modification,
        between firstResidueIndex: Int,
        inChain firstChainIndex: Int = 0,
        and secondResidueIndex: Int,
        inChain secondChainIndex: Int = 0
    ) throws -> CrossLink {
        guard chains.indices.contains(firstChainIndex) else {
            throw CrossLinkError.invalidChainIndex(firstChainIndex)
        }
        guard chains.indices.contains(secondChainIndex) else {
            throw CrossLinkError.invalidChainIndex(secondChainIndex)
        }
        guard chains[firstChainIndex].residues.indices.contains(firstResidueIndex) else {
            throw CrossLinkError.invalidResidueIndex(
                chainIndex: firstChainIndex, residueIndex: firstResidueIndex)
        }
        guard chains[secondChainIndex].residues.indices.contains(secondResidueIndex) else {
            throw CrossLinkError.invalidResidueIndex(
                chainIndex: secondChainIndex, residueIndex: secondResidueIndex)
        }

        let firstSite = CrossLinkSite(
            chainID: chains[firstChainIndex].id, residueIndex: firstResidueIndex)
        let secondSite = CrossLinkSite(
            chainID: chains[secondChainIndex].id, residueIndex: secondResidueIndex)

        guard firstSite != secondSite else {
            throw CrossLinkError.identicalSites
        }

        let crossLink = CrossLink(
            modification: modification, firstSite: firstSite, secondSite: secondSite)
        crossLinks.append(crossLink)
        return crossLink
    }

    public mutating func removeCrossLink(id: UUID) {
        crossLinks.removeAll { $0.id == id }
    }

    public func crossLinks(at site: CrossLinkSite) -> [CrossLink] {
        crossLinks.filter { $0.firstSite == site || $0.secondSite == site }
    }

    public func sequenceLength(for chainIndex: Int = 0) -> Int {
        guard chains.indices.contains(chainIndex) else {
            return 0
        }

        return chains[chainIndex].numberOfResidues
    }

    public func residues(for chainIndex: Int = 0) -> [any Residue] {
        guard chains.indices.contains(chainIndex) else {
            return []
        }

        return chains[chainIndex].residues
    }

    public func sequence(for chainIndex: Int = 0) -> String {
        guard chains.indices.contains(chainIndex) else {
            return ""
        }

        return chains[chainIndex].sequenceString
    }

    public func residueLocations(for chainIndex: Int = 0, with identifiers: [String]) -> [Int] {
        guard chains.indices.contains(chainIndex) else {
            return []
        }

        return chains[chainIndex].residueLocations(with: Set(identifiers))
    }

    public func countResidues(for chainIndex: Int = 0) -> NSCountedSet {
        guard chains.indices.contains(chainIndex) else {
            return NSCountedSet()
        }

        return chains[chainIndex].countAllResidues()
    }

    public func countOneResidue(with identifier: String, for chainIndex: Int = 0) -> Int {
        guard chains.indices.contains(chainIndex) else {
            return 0
        }

        return chains[chainIndex].countOneResidue(with: identifier)
    }

    public func selectionLength(chainIndex index: Int = 0, _ range: Range<Int>) -> Int {
        guard chains.indices.contains(index) else {
            return 0
        }

        let sub = chains[index].subChain(range: range)

        return sub.numberOfResidues
    }

    public mutating func addModification(mod: Modification, at loc: Int, for chainIndex: Int = 0) {
        guard chains.indices.contains(chainIndex) else {
            return
        }

        chains[chainIndex].addModification(mod, at: loc)
    }

    public mutating func removeModification(at loc: Int, for chainIndex: Int = 0) {
        guard chains.indices.contains(chainIndex) else {
            return
        }

        chains[chainIndex].removeModification(at: loc)
    }

    public mutating func modifyResidues(for identifier: String, with modification: Modification, for chainIndex: Int = 0) {
        guard chains.indices.contains(chainIndex) else {
            return
        }

        chains[chainIndex].modifyResidues(for: identifier, with: modification)
    }

    public mutating func removeModifications(for identifier: String, for chainIndex: Int = 0) {
        guard chains.indices.contains(chainIndex) else {
            return
        }

        chains[chainIndex].removeModifications(for: identifier)
    }
}

extension BioMolecule where ChainType.ResidueType == AminoAcid {
    public func isoelectricPoint(chainIndex index: Int = 0, range: Range<Int>? = nil) -> Double {
        guard chains.indices.contains(index) else {
            return 0.0
        }

        let chain = chains[index]

        guard let range else {
            return chain.isoelectricPoint()
        }

        let validRange = range.clamped(toSequenceLength: chain.residues.count)

        guard validRange.isValidRange, !validRange.isEmpty else {
            return 0.0
        }

        return IsoelectricPointCalculator.isoElectricPoint(for: chain.residues[validRange])
    }

    public func selectedIsoelectricPoint(chainIndex index: Int = 0, _ range: Range<Int>) -> Double {
        isoelectricPoint(chainIndex: index, range: range)
    }

    public func hydrophobicityValues(chainIndex index: Int = 0, for hydrophobicityScale: String) -> [Double] {
        guard chains.indices.contains(index) else {
            return []
        }

        return chains[index].hydrophobicityValues(for: hydrophobicityScale)
    }

    public func hydrophobicityValues(chainIndex index: Int = 0, for hydrophobicityScale: HydrophobicityScaleName) -> [Double] {
        hydrophobicityValues(chainIndex: index, for: hydrophobicityScale.rawValue)
    }
}

extension BioMolecule where ChainType: MassRepresentable {
    public func neutralMasses() -> MassContainer {
        let chainMasses = chains.reduce(zeroMass) {
            $0 + $1.masses
        }

        return crossLinks.reduce(chainMasses) {
            $0 + $1.modification.masses
        }
    }
}

extension BioMolecule: MassRepresentable where ChainType: Ionizable {
    public var masses: MassContainer {
        massOverCharge()
    }

    public var charge: Charge {
        chains.reduce(0) {
            $0 + $1.charge
        }
    }

    public func calculateMasses() -> MassContainer {
        let chainMasses = chains.reduce(zeroMass) {
            $0 + $1.massOverCharge()
        }

        return crossLinks.reduce(chainMasses) {
            $0 + $1.modification.masses
        }
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
        guard chains.indices.contains(index) else {
            return zeroMass
        }

        let chain = chains[index]
        let validRange = range.clamped(toSequenceLength: chain.residues.count)

        guard validRange.isValidRange, !validRange.isEmpty else {
            return zeroMass
        }

        if let aminoAcidChain = chain as? any AminoAcidChain {
            let selectedMasses = aminoAcidChain.aminoAcidResidueMasses(in: validRange)
                + aminoAcidChain.nTerminal.masses
                + aminoAcidChain.cTerminal.masses

            return selectedMasses.selectionMassOverCharge(for: charge)
        }

        var sub = chain.subChain(range: validRange)

        if charge > 0 {
            sub.setAdducts(type: protonAdduct, count: charge)
        }

        return sub.pseudomolecularIon()
    }

    public mutating func setAdducts(type: Adduct, count: Int, for chainIndex: Int = 0) {
        guard chains.indices.contains(chainIndex) else {
            return
        }

        adducts = Array(repeating: type, count: count)
    }
}

extension BioMolecule: Ionizable where ChainType: Ionizable {}
