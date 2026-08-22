//
//  Protein.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/18/21.
//  Copyright © 2021 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

/// Protein can contain one or more ``Peptide`` chains and conforms to the ``BioMolecule`` protocol
///
public struct Protein: BioMolecule, Codable, Equatable, Sendable {
    public var adducts: [Adduct] = []
    public var chains: [Peptide]

    public init(chains: [Peptide]) { self.chains = chains }

    public init(sequence: String) {
        self.init(sequence: sequence, aminoAcids: AminoAcidReferenceDefaults.bundled)
    }

    public init(
        sequence: String,
        aminoAcids: AminoAcidReferences
    ) {
        chains = [Peptide(sequence: sequence, aminoAcids: aminoAcids)]
    }

    public init(sequences: [String]) {
        self.init(sequences: sequences, aminoAcids: AminoAcidReferenceDefaults.bundled)
    }

    public init(
        sequences: [String],
        aminoAcids: AminoAcidReferences
    ) {
        chains = sequences.map { Peptide(sequence: $0, aminoAcids: aminoAcids) }
    }

    public init(residues: [AminoAcid]) { chains = [Peptide(residues: residues)] }

    public func truncate(by range: Range<Int>) -> Protein {
        if let subChain = chains.first?.removing(range) { return Protein(chains: [subChain]) }

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

    public func nTermLocation(for _: Int = 0) -> Int {
        0
    }

    public func cTermLocation(for chainIndex: Int = 0) -> Int {
        chains[chainIndex].sequenceLength - 1
    }

    public func aminoAcid(at loc: Int, for chainIndex: Int = 0) -> AminoAcid {
        aminoAcids(for: chainIndex)[loc]
    }

    public func aminoAcids(for chainIndex: Int = 0) -> [AminoAcid] {
        residues(for: chainIndex) as? [AminoAcid] ?? []
    }

    public func isoelectricPoint(
        for chainIndex: Int = 0,
        hydropathyReferences: HydropathyReferences = HydropathyReferenceDefaults.bundled
    ) -> Double {
        chains[chainIndex].isoelectricPoint(hydropathyReferences: hydropathyReferences)
    }

    public func isoelectricPoint(
        for chainIndex: Int = 0,
        with range: Range<Int>,
        hydropathyReferences: HydropathyReferences = HydropathyReferenceDefaults.bundled
    ) -> Double {
        let peptide = chains[chainIndex].subChain(range: range)

        if peptide.numberOfResidues > 0 {
            return peptide.isoelectricPoint(hydropathyReferences: hydropathyReferences)
        }

        return 0.0
    }

    public func hydropathyValues(
        chainIndex index: Int = 0,
        for hydropathyType: String,
        hydropathyReferences: HydropathyReferences = HydropathyReferenceDefaults.bundled
    ) -> [Double] {
        let values = Hydropathy(
            residues: chains[index].residues,
            hydropathyReferences: hydropathyReferences
        ).hydropathyValues(for: hydropathyType)

        return chains[index].residues.compactMap { values[$0.oneLetterCode] }
    }
}

extension Protein: Ionizable {}
