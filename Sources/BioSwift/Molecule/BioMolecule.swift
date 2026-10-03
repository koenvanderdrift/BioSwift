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

    /// The molecular formula formatted using Hill-system element ordering.
    public var formulaString: String {
        formula.formulaString
    }
}

extension BioMolecule {
    /// The sequence of the first chain, or an empty string when the molecule has no chains.
    public var sequence: String {
        sequence(chainIndex: 0)
    }

    /// The residue count of the first chain, or zero when the molecule has no chains.
    public var sequenceLength: Int {
        sequenceLength(chainIndex: 0)
    }

    /// The residues of the first chain, or an empty array when the molecule has no chains.
    public var residues: [any Residue] {
        residues(chainIndex: 0)
    }

    /// Residue counts for the first chain.
    public var residueCounts: NSCountedSet {
        residueCounts(chainIndex: 0)
    }

    /// Returns the first chain with the specified name.
    public func chain(named name: String) -> ChainType? {
        chains.first { $0.name == name }
    }

    /// Returns the index of the first chain with the specified name.
    public func chainIndex(named name: String) -> Int? {
        chains.firstIndex { $0.name == name }
    }

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

    public func sequenceLength(chainIndex: Int) -> Int {
        guard chains.indices.contains(chainIndex) else {
            return 0
        }

        return chains[chainIndex].residueCount
    }

    public func sequenceLength(chainName: String) -> Int? {
        chain(named: chainName)?.residueCount
    }

    public func residues(chainIndex: Int) -> [any Residue] {
        guard chains.indices.contains(chainIndex) else {
            return []
        }

        return chains[chainIndex].residues
    }

    public func residues(chainName: String) -> [any Residue]? {
        chain(named: chainName)?.residues
    }

    public func sequence(chainIndex: Int) -> String {
        guard chains.indices.contains(chainIndex) else {
            return ""
        }

        return chains[chainIndex].sequenceString
    }

    public func sequence(chainName: String) -> String? {
        chain(named: chainName)?.sequenceString
    }

    public func residueLocations(with identifiers: [String], chainIndex: Int = 0) -> [Int] {
        guard chains.indices.contains(chainIndex) else {
            return []
        }

        return chains[chainIndex].residueLocations(with: Set(identifiers))
    }

    public func residueLocations(with identifiers: [String], chainName: String) -> [Int]? {
        chain(named: chainName)?.residueLocations(with: Set(identifiers))
    }

    public func residueCounts(chainIndex: Int) -> NSCountedSet {
        guard chains.indices.contains(chainIndex) else {
            return NSCountedSet()
        }

        return chains[chainIndex].residueCounts
    }

    public func residueCounts(chainName: String) -> NSCountedSet? {
        chain(named: chainName)?.residueCounts
    }

    public func residueCount(for identifier: String, chainIndex: Int = 0) -> Int {
        guard chains.indices.contains(chainIndex) else {
            return 0
        }

        return chains[chainIndex].residueCount(for: identifier)
    }

    public func residueCount(for identifier: String, chainName: String) -> Int? {
        chain(named: chainName)?.residueCount(for: identifier)
    }

    public func selectionLength(chainIndex index: Int = 0, _ range: Range<Int>) -> Int {
        guard chains.indices.contains(index) else {
            return 0
        }

        let sub = chains[index].subChain(range: range)

        return sub.residueCount
    }

    public mutating func insertResidue(
        _ residue: ChainType.ResidueType,
        at location: Int,
        chainIndex: Int = 0
    ) throws {
        try insertResidues([residue], at: location, chainIndex: chainIndex)
    }

    public func insertingResidue(
        _ residue: ChainType.ResidueType,
        at location: Int,
        chainIndex: Int = 0
    ) throws -> Self {
        var copy = self
        try copy.insertResidue(residue, at: location, chainIndex: chainIndex)
        return copy
    }

    public mutating func insertResidues(
        _ newResidues: [ChainType.ResidueType],
        at location: Int,
        chainIndex: Int = 0
    ) throws {
        guard chains.indices.contains(chainIndex) else {
            throw CrossLinkError.invalidChainIndex(chainIndex)
        }

        guard newResidues.isEmpty == false else {
            return
        }

        let chainID = chains[chainIndex].id
        try chains[chainIndex].insertResidues(newResidues, at: location)
        remapCrossLinks(on: chainID) { site in
            CrossLinkSite(
                chainID: site.chainID,
                residueIndex: site.residueIndex >= location
                    ? site.residueIndex + newResidues.count
                    : site.residueIndex
            )
        }
    }

    public func insertingResidues(
        _ newResidues: [ChainType.ResidueType],
        at location: Int,
        chainIndex: Int = 0
    ) throws -> Self {
        var copy = self
        try copy.insertResidues(newResidues, at: location, chainIndex: chainIndex)
        return copy
    }

    public mutating func removeResidue(
        at location: Int,
        chainIndex: Int = 0
    ) throws {
        guard chains.indices.contains(chainIndex) else {
            throw CrossLinkError.invalidChainIndex(chainIndex)
        }

        guard chains[chainIndex].residues.indices.contains(location) else {
            throw ChainEditingError.indexOutOfBounds(
                index: location,
                residueCount: chains[chainIndex].residues.count
            )
        }

        try removeResidues(in: location..<(location + 1), chainIndex: chainIndex)
    }

    public func removingResidue(
        at location: Int,
        chainIndex: Int = 0
    ) throws -> Self {
        var copy = self
        try copy.removeResidue(at: location, chainIndex: chainIndex)
        return copy
    }

    /// Removes a residue range from one chain and maintains molecule cross-links.
    ///
    /// Cross-links touching a removed residue are deleted. Retained endpoints on
    /// the edited chain are shifted with ``RangeRemovalMapping``; endpoints on
    /// other chains and retained cross-link identifiers remain unchanged.
    public mutating func removeResidues(
        in range: Range<Int>,
        chainIndex: Int = 0
    ) throws {
        guard chains.indices.contains(chainIndex) else {
            throw CrossLinkError.invalidChainIndex(chainIndex)
        }

        let chainID = chains[chainIndex].id
        try chains[chainIndex].removeResidues(in: range)

        let mapping = RangeRemovalMapping(removedRange: range)
        remapCrossLinks(on: chainID) { site in
            guard let residueIndex = mapping.map(site.residueIndex) else {
                return nil
            }

            return CrossLinkSite(chainID: site.chainID, residueIndex: residueIndex)
        }
    }

    public func removingResidues(
        in range: Range<Int>,
        chainIndex: Int = 0
    ) throws -> Self {
        var copy = self
        try copy.removeResidues(in: range, chainIndex: chainIndex)
        return copy
    }

    public mutating func replaceResidue(
        at location: Int,
        with residue: ChainType.ResidueType,
        chainIndex: Int = 0
    ) throws {
        guard chains.indices.contains(chainIndex) else {
            throw CrossLinkError.invalidChainIndex(chainIndex)
        }

        try chains[chainIndex].replaceResidue(at: location, with: residue)
    }

    public func replacingResidue(
        at location: Int,
        with residue: ChainType.ResidueType,
        chainIndex: Int = 0
    ) throws -> Self {
        var copy = self
        try copy.replaceResidue(at: location, with: residue, chainIndex: chainIndex)
        return copy
    }

    public mutating func addModification(
        _ modification: Modification,
        at location: Int,
        chainIndex: Int = 0
    ) {
        guard chains.indices.contains(chainIndex) else {
            return
        }

        chains[chainIndex].addModification(modification, at: location)
    }

    public mutating func removeModification(at location: Int, chainIndex: Int = 0) {
        guard chains.indices.contains(chainIndex) else {
            return
        }

        chains[chainIndex].removeModification(at: location)
    }

    public mutating func modifyResidues(
        for identifier: String,
        with modification: Modification,
        chainIndex: Int = 0
    ) {
        guard chains.indices.contains(chainIndex) else {
            return
        }

        chains[chainIndex].modifyResidues(for: identifier, with: modification)
    }

    public mutating func removeModifications(for identifier: String, chainIndex: Int = 0) {
        guard chains.indices.contains(chainIndex) else {
            return
        }

        chains[chainIndex].removeModifications(for: identifier)
    }
}

private extension BioMolecule {
    mutating func remapCrossLinks(
        on chainID: UUID,
        transform: (CrossLinkSite) -> CrossLinkSite?
    ) {
        crossLinks = crossLinks.compactMap { crossLink in
            let firstSite: CrossLinkSite?
            if crossLink.firstSite.chainID == chainID {
                firstSite = transform(crossLink.firstSite)
            } else {
                firstSite = crossLink.firstSite
            }

            let secondSite: CrossLinkSite?
            if crossLink.secondSite.chainID == chainID {
                secondSite = transform(crossLink.secondSite)
            } else {
                secondSite = crossLink.secondSite
            }

            guard let firstSite, let secondSite else {
                return nil
            }

            return CrossLink(
                id: crossLink.id,
                modification: crossLink.modification,
                firstSite: firstSite,
                secondSite: secondSite
            )
        }
    }
}

extension BioMolecule where ChainType.ResidueType == AminoAcid {
    /// The isoelectric point of the first chain, calculated with free N- and C-termini.
    public var isoelectricPoint: Double {
        isoelectricPoint()
    }

    public func isoelectricPoint(chainIndex index: Int = 0, range: Range<Int>? = nil) -> Double {
        guard chains.indices.contains(index) else {
            return 0.0
        }

        let chain = chains[index]

        guard let range else {
            return IsoelectricPointCalculator.isoelectricPoint(for: chain.residues)
        }

        let validRange = range.clamped(toSequenceLength: chain.residues.count)

        guard validRange.isValidRange, !validRange.isEmpty else {
            return 0.0
        }

        return IsoelectricPointCalculator.isoelectricPoint(for: chain.residues[validRange])
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

extension BioMolecule {
    var masses: MassContainer {
        let chainMasses = chains.reduce(zeroMass) {
            $0 + $1.calculatedMasses()
        }

        return crossLinks.reduce(chainMasses) {
            $0 + $1.modification.masses
        }
    }
}

extension BioMolecule: MassRepresentable {
    public var charge: Charge {
        adducts.reduce(0) {
            $0 + $1.charge
        }
    }

    public var monoisotopicMass: Dalton {
        massContainer.monoisotopicMass
    }

    public var averageMass: Dalton {
        massContainer.averageMass
    }

    public var nominalMass: Int {
        massContainer.nominalMass
    }

    public var massContainer: MassContainer {
        masses.applying(adducts: adducts)
    }

    public func selectionMass(
        chainIndex index: Int = 0,
        _ range: Range<Int>
    ) -> MassContainer {
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

            return selectedMasses.applying(adducts: adducts)
        }

        let sub = chain.subChain(range: validRange)
        return sub.calculatedMasses().applying(adducts: adducts)
    }

    public mutating func setAdducts(type: Adduct, count: Int) {
        adducts = Array(repeating: type, count: count)
    }
}

extension BioMolecule: Ionizable {}
