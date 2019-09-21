//
//  Residue.swift
//  BioSwift
//
//  Created by Koen van der Drift on 9/21/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public class Residue: Molecule {
    public var groups: [FunctionalGroup] = []
    
    public override func calculateMasses() -> MassContainer {
        return super.calculateMasses() + modificationMasses()
    }
    
    private func modificationMasses() -> MassContainer {
        return groups.reduce(zeroMass, {$0 + $1.masses})
    }
}
