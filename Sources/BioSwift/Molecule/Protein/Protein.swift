//
//  Protein.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/18/21.
//

import Foundation

public typealias Protein = BioMolecule<AminoAcid>

extension Protein {
    public init(sequence: String) {
        self.chains = [Peptide(sequence: sequence)]
    }
    
    public init(residues: [AminoAcid]) {
        self.chains = [Peptide(residues: residues)]
    }

    public func aminoAcids(for chainIndex: Int = 0) -> [AminoAcid] {
        self.residues(for: chainIndex) as [AminoAcid]
    }
}


