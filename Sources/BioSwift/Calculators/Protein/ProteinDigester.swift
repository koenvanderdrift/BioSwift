//
//  ProteinDigester.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/12/18.
//  Copyright © 2018 - 2026 Koen van der Drift. All rights reserved.
//

import Foundation

/// ProteinDigester produces a ``Peptides`` array.
///  It takes an ``Enzyme`` and optionally a missedCleavages paramenter
///
public class ProteinDigester {
    public let protein: Protein
    
    public init(protein: Protein) {
        self.protein = protein
    }
    
    public func peptides(using enzyme: Enzyme, with missedCleavages: Int = 0) -> [Peptide] {
        protein.chains.flatMap { chain in
            chain.digest(using: enzyme, with: missedCleavages)
        }
    }
}
