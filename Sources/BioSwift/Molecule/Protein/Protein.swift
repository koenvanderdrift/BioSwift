//
//  Protein.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/18/21.
//  Copyright © 2021 - 2024 Koen van der Drift. All rights reserved.
//

import Foundation

public typealias Protein = BioMolecule

public extension Protein {
    init(sequence: String) {
        chains = [Peptide(sequence: sequence)]
    }

    init(sequences: [String]) {
        chains = sequences.map { Peptide(sequence: $0) }
    }

    init(residues: [AminoAcid]) {
        chains = [Peptide(residues: residues)]
    }

    func aminoAcids(for chainIndex: Int = 0) -> [AminoAcid] {
        residues(for: chainIndex) as? [AminoAcid] ?? []
    }

    func isoelectricPoint(for chainIndex: Int = 0) -> Double {
        if let peptide = chains[chainIndex] as? Peptide {
            return peptide.isoelectricPoint()
        }
        
        return 0.0
    }

    func isoelectricPoint(for chainIndex: Int = 0, with range: ChainRange) -> Double {
        if let peptide = chains[chainIndex].subChain(with: range) as? Peptide {
            return peptide.isoelectricPoint()
        }

        return 0.0
    }
}
