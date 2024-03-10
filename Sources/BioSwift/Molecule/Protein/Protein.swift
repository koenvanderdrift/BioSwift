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
    
    public init(sequences: [String]) {
        self.chains = sequences.map { Peptide(sequence: $0) }
    }

    public init(residues: [AminoAcid]) {
        self.chains = [Peptide(residues: residues)]
    }

    public func aminoAcids(for chainIndex: Int = 0) -> [AminoAcid] {
        self.residues(for: chainIndex) as [AminoAcid]
    }
    
    public func isoelectricPoint(for chainIndex: Int = 0) -> Double {
        if let peptide = chains[chainIndex] as? Peptide {
            return peptide.isoelectricPoint()
        }
        
        return 0
    }
    
    public func isoelectricPoint(for chainIndex: Int = 0, with range: ChainRange) -> Double {
        if let peptide = chains[chainIndex].subChain(with: range) as? Peptide {
            return peptide.isoelectricPoint()
        }
        
        return 0
    }
}


