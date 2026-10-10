//
//  Protein.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/18/21.
//  Copyright © 2021 - 2026 Koen van der Drift. All rights reserved.
//

import Foundation

/// Protein contains one or more ``ProteinChain`` values.
public typealias Protein = BioMolecule<ProteinChain>

extension BioMolecule where ChainType == ProteinChain {
    public var nTermModifications: [Modification] {
        get throws {
            if let nTermAA = residues.first {
                var nTermGroups = try UnimodModificationReferenceDefaults.loadBundled().modifications.filter { mod in
                mod.specificities.contains { spec in
                    spec.position.contains("Protein N-term") && spec.site == nTermAA.oneLetterCode
                }
            }

            nTermGroups.append(hydrogenModification)

            return nTermGroups
        }

            return []
        }
    }

    public var cTermModifications: [Modification] {
        get throws {
            if let cTermAA = residues.last {
                var cTermGroups = try UnimodModificationReferenceDefaults.loadBundled().modifications.filter { mod in
                mod.specificities.contains { spec in
                    spec.position.contains("Protein C-term") && spec.site == cTermAA.oneLetterCode
                }
            }

            cTermGroups.append(hydroxylModification)

            return cTermGroups
        }

            return []
        }
    }

    public var nTermLocation: Int? {
        nTermLocation(chainIndex: 0)
    }

    public func nTermLocation(chainIndex: Int) -> Int? {
        guard chains.indices.contains(chainIndex), chains[chainIndex].sequenceLength > 0 else {
            return nil
        }

        return 0
    }

    public func nTermLocation(chainName: String) -> Int? {
        guard let chain = chain(named: chainName), chain.sequenceLength > 0 else {
            return nil
        }
        return 0
    }

    public var cTermLocation: Int? {
        cTermLocation(chainIndex: 0)
    }

    public func cTermLocation(chainIndex: Int) -> Int? {
        guard chains.indices.contains(chainIndex), chains[chainIndex].sequenceLength > 0 else {
            return nil
        }

        return chains[chainIndex].sequenceLength - 1
    }

    public func cTermLocation(chainName: String) -> Int? {
        guard let chain = chain(named: chainName), chain.sequenceLength > 0 else {
            return nil
        }
        return chain.sequenceLength - 1
    }

    public func aminoAcid(at location: Int, chainIndex: Int = 0) -> AminoAcid? {
        residue(at: location, chainIndex: chainIndex)
    }

    public func aminoAcid(at location: Int, chainName: String) -> AminoAcid? {
        residue(at: location, chainName: chainName)
    }

    public var aminoAcids: [AminoAcid] {
        residues
    }

    public func aminoAcids(chainIndex: Int) -> [AminoAcid] {
        residues(chainIndex: chainIndex)
    }

    public func aminoAcids(chainName: String) -> [AminoAcid]? {
        residues(chainName: chainName)
    }

    /// Attaches a glycan to an amino acid, accounting for the water lost during
    /// glycosidic bond formation.
    public mutating func glycosylate(
        with glycan: Glycan,
        at location: Int,
        chainIndex: Int = 0
    ) throws {
        let modificationName = glycan.name.isEmpty
            ? "Glycosylation"
            : "\(glycan.name) glycosylation"
        let modification = Modification(
            name: modificationName,
            reactions: [
                .add(.glycan(glycan)),
                .remove(.functionalGroup(water)),
            ]
        )

        try addModification(modification, at: location, chainIndex: chainIndex)
    }

    /// Returns a copy with a glycan attached to an amino acid.
    public func glycosylated(
        with glycan: Glycan,
        at location: Int,
        chainIndex: Int = 0
    ) throws -> Self {
        var copy = self
        try copy.glycosylate(with: glycan, at: location, chainIndex: chainIndex)
        return copy
    }

    /// Applies a modification to cysteines that have no residue modification
    /// and do not participate in a cross-link.
    public mutating func modifyFreeCysteines(with modification: Modification) {
        let occupiedSites = Set(
            crossLinks.flatMap { [$0.firstSite, $0.secondSite] }
        )

        for chainIndex in chains.indices {
            let chainID = chains[chainIndex].id

            for residueIndex in chains[chainIndex].residues.indices {
                let residue = chains[chainIndex].residues[residueIndex]
                let site = CrossLinkSite(chainID: chainID, residueIndex: residueIndex)

                guard residue.identifier == "C",
                    residue.modification == nil,
                    occupiedSites.contains(site) == false
                else {
                    continue
                }

                chains[chainIndex].residues[residueIndex].modification = modification
            }
        }
    }

    /// Returns a copy with all free cysteines modified.
    public func modifyingFreeCysteines(with modification: Modification) -> Self {
        var copy = self
        copy.modifyFreeCysteines(with: modification)
        return copy
    }
}
