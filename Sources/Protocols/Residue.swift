//
//  Residue.swift
//  BioSwift
//
//  Created by Koen van der Drift on 9/21/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public protocol Residue: Molecule, Symbol, Mass {
    var oneLetterCode: String { get }
    var threeLetterCode: String { get }
    
    var modifications: [Modification] { get set }
}

extension Residue {
    public var identifier: String {
        return oneLetterCode
    }

    public func calculateMasses() -> MassContainer {
        return mass(of: formula.elements) + modificationMasses()
    }
    
    private func modificationMasses() -> MassContainer {
        return mass(of: modifications)
    }
    
    mutating func addModification(_ modification: Modification) {
        modifications.append(modification)
    }
    
    mutating func removeModification(_ modification: Modification) {
        guard let index = modifications.firstIndex(of: modification) else { return }
        modifications.remove(at: index)
     }
}
