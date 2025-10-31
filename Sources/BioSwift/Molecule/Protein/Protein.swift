//
//  Protein.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/18/21.
//  Copyright © 2021 - 2024 Koen van der Drift. All rights reserved.
//

import Foundation

public struct Protein: BioMolecule {
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
}
