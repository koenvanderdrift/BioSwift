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
    public var chains: [ChainType]
    public var crossLinks: [CrossLink]

    public init(chains: [ChainType], crossLinks: [CrossLink] = []) {
        self.chains = chains
        self.crossLinks = crossLinks
    }
}

extension BioMolecule: Codable where ChainType: Codable {
    private enum CodingKeys: String, CodingKey {
        case chains
        case crossLinks
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        chains = try container.decode([ChainType].self, forKey: .chains)
        crossLinks = try container.decodeIfPresent([CrossLink].self, forKey: .crossLinks) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
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

extension BioMolecule: Structure where ChainType: Structure {
    public var name: String {
        chains.map(\.name).filter { !$0.isEmpty }.joined(separator: ", ")
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
            throw BioSwiftDiagnostics.logged(CrossLinkError.invalidChainIndex(firstChainIndex))
        }
        guard chains.indices.contains(secondChainIndex) else {
            throw BioSwiftDiagnostics.logged(CrossLinkError.invalidChainIndex(secondChainIndex))
        }
        guard chains[firstChainIndex].residues.indices.contains(firstResidueIndex) else {
            throw BioSwiftDiagnostics.logged(CrossLinkError.invalidResidueIndex(
                chainIndex: firstChainIndex, residueIndex: firstResidueIndex))
        }
        guard chains[secondChainIndex].residues.indices.contains(secondResidueIndex) else {
            throw BioSwiftDiagnostics.logged(CrossLinkError.invalidResidueIndex(
                chainIndex: secondChainIndex, residueIndex: secondResidueIndex))
        }

        let firstSite = CrossLinkSite(
            chainID: chains[firstChainIndex].id, residueIndex: firstResidueIndex)
        let secondSite = CrossLinkSite(
            chainID: chains[secondChainIndex].id, residueIndex: secondResidueIndex)

        guard firstSite != secondSite else {
            throw BioSwiftDiagnostics.logged(CrossLinkError.identicalSites)
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
            throw BioSwiftDiagnostics.logged(CrossLinkError.invalidChainIndex(chainIndex))
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
            throw BioSwiftDiagnostics.logged(CrossLinkError.invalidChainIndex(chainIndex))
        }

        guard chains[chainIndex].residues.indices.contains(location) else {
            throw BioSwiftDiagnostics.logged(ChainEditingError.indexOutOfBounds(
                index: location,
                residueCount: chains[chainIndex].residues.count
            ))
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
            throw BioSwiftDiagnostics.logged(CrossLinkError.invalidChainIndex(chainIndex))
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
            throw BioSwiftDiagnostics.logged(CrossLinkError.invalidChainIndex(chainIndex))
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
    ) throws {
        guard chains.indices.contains(chainIndex) else {
            throw BioSwiftDiagnostics.logged(CrossLinkError.invalidChainIndex(chainIndex))
        }

        try chains[chainIndex].addModification(modification, at: location)
    }

    public mutating func removeModification(at location: Int, chainIndex: Int = 0) throws {
        guard chains.indices.contains(chainIndex) else {
            throw BioSwiftDiagnostics.logged(CrossLinkError.invalidChainIndex(chainIndex))
        }

        try chains[chainIndex].removeModification(at: location)
    }

    public mutating func modifyResidues(
        for identifier: String,
        with modification: Modification,
        chainIndex: Int = 0
    ) throws {
        guard chains.indices.contains(chainIndex) else {
            throw BioSwiftDiagnostics.logged(CrossLinkError.invalidChainIndex(chainIndex))
        }

        try chains[chainIndex].modifyResidues(for: identifier, with: modification)
    }

    public mutating func removeModifications(for identifier: String, chainIndex: Int = 0) throws {
        guard chains.indices.contains(chainIndex) else {
            throw BioSwiftDiagnostics.logged(CrossLinkError.invalidChainIndex(chainIndex))
        }

        try chains[chainIndex].removeModifications(for: identifier)
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
        get throws { try isoelectricPoint() }
    }

    public func isoelectricPoint(chainIndex index: Int = 0, range: Range<Int>? = nil) throws -> Double {
        guard chains.indices.contains(index) else {
            return 0.0
        }

        let chain = chains[index]

        guard let range else {
            return try IsoelectricPointCalculator.isoelectricPoint(for: chain.residues)
        }

        let validRange = range.clamped(toSequenceLength: chain.residues.count)

        guard validRange.isValidRange, !validRange.isEmpty else {
            return 0.0
        }

        return try IsoelectricPointCalculator.isoelectricPoint(for: chain.residues[validRange])
    }

    public func selectedIsoelectricPoint(chainIndex index: Int = 0, _ range: Range<Int>) throws -> Double {
        try isoelectricPoint(chainIndex: index, range: range)
    }

    public func hydrophobicityValues(chainIndex index: Int = 0, for hydrophobicityScale: String) throws -> [Double] {
        guard chains.indices.contains(index) else {
            return []
        }

        return try chains[index].hydrophobicityValues(for: hydrophobicityScale)
    }

    public func hydrophobicityValues(chainIndex index: Int = 0, for hydrophobicityScale: HydrophobicityScaleName) throws -> [Double] {
        try hydrophobicityValues(chainIndex: index, for: hydrophobicityScale.rawValue)
    }
}

extension BioMolecule where ChainType: Structure {
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

            return selectedMasses
        }

        let sub = chain.subChain(range: validRange)
        return sub.calculatedMasses()
    }
}
