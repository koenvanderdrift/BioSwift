//
//  Protein.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/18/21.
//  Copyright © 2021 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

/// Protein contains one or more ``Peptide`` chains.
public typealias Protein = BioMolecule<Peptide>

extension BioMolecule where ChainType == Peptide {
    public init(sequence: String) {
        self.init(sequence: sequence, aminoAcids: AminoAcidReferenceDefaults.bundled)
    }

    public init(sequence: String, aminoAcids: AminoAcidReferences) {
        self.init(chains: [Peptide(sequence: sequence, aminoAcids: aminoAcids)])
    }

    public init(sequences: [String]) {
        self.init(sequences: sequences, aminoAcids: AminoAcidReferenceDefaults.bundled)
    }

    public init(sequences: [String], aminoAcids: AminoAcidReferences) {
        self.init(chains: sequences.map {
            Peptide(sequence: $0, aminoAcids: aminoAcids)
        })
    }

    public init(residues: [AminoAcid]) {
        self.init(chains: [Peptide(residues: residues)])
    }

    public func truncate(by range: Range<Int>) -> Protein {
        if let subChain = chains.first?.removing(range) {
            return Protein(chains: [subChain])
        }

        return self
    }

    public func nTermModifications() -> [Modification] {
        nTermModifications(modifications: ModificationReferenceDefaults.bundled)
    }

    public func nTermModifications(modifications: ModificationReferences) -> [Modification] {
        if let nTermAA = residues().first {
            var nTermGroups = modifications.modifications.filter { mod in
                mod.specificities.contains { spec in
                    spec.position.contains("Protein N-term") && spec.site == nTermAA.oneLetterCode
                }
            }

            nTermGroups.append(hydrogenModification)

            return nTermGroups
        }

        return []
    }

    public func cTermModifications() -> [Modification] {
        cTermModifications(modifications: ModificationReferenceDefaults.bundled)
    }

    public func cTermModifications(modifications: ModificationReferences) -> [Modification] {
        if let cTermAA = residues().last {
            var cTermGroups = modifications.modifications.filter { mod in
                mod.specificities.contains { spec in
                    spec.position.contains("Protein C-term") && spec.site == cTermAA.oneLetterCode
                }
            }

            cTermGroups.append(hydroxylModification)

            return cTermGroups
        }

        return []
    }

    public func nTermLocation(for chainIndex: Int = 0) -> Int? {
        guard chains.indices.contains(chainIndex), chains[chainIndex].sequenceLength > 0 else {
            return nil
        }

        return 0
    }

    public func cTermLocation(for chainIndex: Int = 0) -> Int? {
        guard chains.indices.contains(chainIndex), chains[chainIndex].sequenceLength > 0 else {
            return nil
        }

        return chains[chainIndex].sequenceLength - 1
    }

    public func aminoAcid(at loc: Int, for chainIndex: Int = 0) -> AminoAcid? {
        let aminoAcids = aminoAcids(for: chainIndex)
        guard aminoAcids.indices.contains(loc) else {
            return nil
        }

        return aminoAcids[loc]
    }

    public func aminoAcids(for chainIndex: Int = 0) -> [AminoAcid] {
        residues(for: chainIndex) as? [AminoAcid] ?? []
    }
}
