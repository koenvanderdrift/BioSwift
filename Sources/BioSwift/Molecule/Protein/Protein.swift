//
//  Protein.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/18/21.
//  Copyright © 2021 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

public struct Protein: BioMolecule, Codable, Equatable {
    public var adducts: [Adduct] = []
    public var chains: [Peptide]

    public init(chains: [Peptide]) {
        self.chains = chains
    }

    public init(sequence: String) {
        chains = [Peptide(sequence: sequence)]
    }

    public init(sequences: [String]) {
        chains = sequences.map { Peptide(sequence: $0) }
    }

    public init(residues: [AminoAcid]) {
        chains = [Peptide(residues: residues)]
    }

    public func truncate(by range: ChainRange) -> Protein {
        if let subChain = chains.first?.subChain(removing: range.fromOneBased) {
            return Protein(chains: [subChain])
        }

        return self
    }

    public func nTermModifications() -> [Modification] {
        if let nTermAA = residues().first {
            var nTermGroups = modificationLibrary.filter { mod in
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
        if let cTermAA = residues().last {
            var cTermGroups = modificationLibrary.filter { mod in
                mod.specificities.contains { spec in
                    spec.position.contains("Protein C-term") && spec.site == cTermAA.oneLetterCode
                }
            }

            cTermGroups.append(hydroxylModification)

            return cTermGroups
        }

        return []
    }

    public func nTermLocation(for chainIndex: Int = 0) -> Int {
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

    public func isoelectricPoint(for chainIndex: Int = 0) -> Double {
        chains[chainIndex].isoelectricPoint()
    }

    public func isoelectricPoint(for chainIndex: Int = 0, with range: ChainRange) -> Double {
        if let peptide = chains[chainIndex].subChain(with: range) {
            return peptide.isoelectricPoint()
        }

        return 0.0
    }

    public func hydropathyValues(chainIndex index: Int = 0, for hydropathyType: String) -> [Double] {
        let values = Hydropathy(residues: chains[index].residues).hydrophathyValues(for: hydropathyType)

        return chains[index].residues.compactMap { values[$0.oneLetterCode] }
    }
}
