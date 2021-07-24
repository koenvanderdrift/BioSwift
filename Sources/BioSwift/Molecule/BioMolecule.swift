//
//  BioMolecule.swift
//  
//
//  Created by Koen van der Drift on 5/9/21.
//

import Foundation

public struct BioMolecule<T: Chain> {
    public var name: String = ""
    public var chains: [T] = []
}

extension BioMolecule {
    public init(residues: [T.ResidueType]) {
        self.init(chain: T(residues: residues))
    }
    
    public init(sequence: String) {
        self.init(chain: T(sequence: sequence))
    }
    
    public init(chain: T) {
        self.init(chains: [chain])
    }

    public init(chains: [T]) {
        self.chains = chains
    }
}
