//
//  BioMolecule.swift
//  
//
//  Created by Koen van der Drift on 5/9/21.
//

import Foundation

public struct BioMolecule<T: Chain> {
    public var name: String
    public var chains: [T]
}
