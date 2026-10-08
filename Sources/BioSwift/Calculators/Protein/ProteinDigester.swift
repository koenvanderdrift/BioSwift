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
public final class ProteinDigester: Sendable {
    public let protein: Protein
    
    public init(protein: Protein) {
        self.protein = protein
    }
    
    public func peptides(using enzyme: Enzyme, with missedCleavages: Int = 0) throws -> [Peptide] {
        try protein.chains.flatMap { chain in
            try chain.digest(using: enzyme, with: missedCleavages).map {
                Peptide(proteinChain: $0, id: chain.id)
            }
        }
    }
}
