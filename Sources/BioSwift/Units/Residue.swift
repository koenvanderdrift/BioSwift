//
//  Residue.swift
//  BioSwift
//
//  Created by Koen van der Drift on 9/21/19.
//  Copyright © 2019 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

/// Residue is a building block for a ``Chain``
/// 
public protocol Residue: Symbol, Structure, Hashable {
    var oneLetterCode: String { get }
    var threeLetterCode: String { get }
    var modification: Modification? { get set }
}

public extension Residue {
    var identifier: String {
        oneLetterCode
    }

    var description: String {
        threeLetterCode
    }

    var masses: MassContainer {
        formula.masses + modificationMasses()
    }
    
    func modificationMasses() -> MassContainer {
        modification?.masses ?? zeroMass
    }
    
    func allowedModifications() -> [Modification] {
        modificationLibrary.filter { mod in
            mod.specificities.contains { spec in
                spec.site == identifier
            }
        }
    }
}

public extension Residue {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.threeLetterCode == rhs.threeLetterCode
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(threeLetterCode)
    }
}
