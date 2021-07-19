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
    public init(with residues: [T.ResidueType]) {
        let chain = T(residues: residues)
        self.chains.append(chain)
    }
    
    public init(with sequence: String) {
        let chain = T(sequence: sequence)
        self.chains.append(chain)
    }
    
    public init(with chain: T) {
        self.chains.append(chain)
    }
}
