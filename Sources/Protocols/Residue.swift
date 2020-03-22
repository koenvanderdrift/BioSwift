//
//  Residue.swift
//  BioSwift
//
//  Created by Koen van der Drift on 9/21/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public protocol Residue: Structure, Symbol, Mass {
    var oneLetterCode: String { get }
    var threeLetterCode: String { get }
    
    var modification: Modification? { get set }
    
    func allowedModifications() -> [Modification]
}

extension Residue {
    public var identifier: String {
        return oneLetterCode
    }

    public func calculateMasses() -> MassContainer {
        return mass(of: formula.elements) + modificationMasses()
    }
    
    private func modificationMasses() -> MassContainer {
        return self.modification?.masses ?? zeroMass
    }
    
    mutating func setModification(_ modification: Modification?) {
        self.modification = modification
    }

    mutating func removeModification() {
        self.modification = nil
    }
}
