//
//  Structure.swift
//  BioSwift
//
//  Created by Koen van der Drift on 9/21/19.
//  Copyright © 2019 - 2024 Koen van der Drift. All rights reserved.
//

import Foundation

// TODO: rethink Structure, Mass, ChargedMass

public protocol Structure: Mass {
    var name: String { get }
    var formula: Formula { get }
}

public extension Structure {
    func calculateMasses() -> MassContainer {
        formula.masses
    }
}
