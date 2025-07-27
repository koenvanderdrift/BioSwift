//
//  Protein.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/18/21.
//  Copyright © 2021 - 2024 Koen van der Drift. All rights reserved.
//

import Foundation

public typealias Protein = BioMolecule<AminoAcid>

public extension Protein {
    init(sequence: String) {
        self.chains = [Peptide(sequence: sequence)]
    }

    init(sequences: [String]) {
        self.chains = sequences.map { Peptide(sequence: $0) }
    }

    init(residues: [AminoAcid]) {
        self.chains = [Peptide(residues: residues)]
    }

    func aminoAcids(for chainIndex: Int = 0) -> [AminoAcid] {
        self.residues(for: chainIndex) as [AminoAcid]
    }

    func isoelectricPoint(for chainIndex: Int = 0) -> Double {
        return chains[chainIndex].isoelectricPoint()
    }

    func isoelectricPoint(for chainIndex: Int = 0, with range: ChainRange) -> Double {
        if let peptide = chains[chainIndex].subChain(with: range) {
            return peptide.isoelectricPoint()
        }

        return 0
    }
}
