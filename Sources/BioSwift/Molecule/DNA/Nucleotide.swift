//
//  Nucleotide.swift
//  
//
//  Created by Koen van der Drift on 12/31/21.
//

import Foundation


public struct Nucleotide: Residue {
    public var adducts: [Adduct]
    
    public let formula: Formula
    public let name: String
    public var oneLetterCode: String
    public var threeLetterCode: String
    public var modification: Modification?
    public let represents: [String]
    public let representedBy: [String]
}

extension Nucleotide: Mass {
    public func allowedModifications() -> [Modification] {
        return []
    }
    
    public var masses: MassContainer {
        return calculateMasses()
    }
}
