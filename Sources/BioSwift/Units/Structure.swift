//
//  Structure.swift
//  BioSwift
//
//  Created by Koen van der Drift on 9/21/19.
//  Copyright © 2019 - 2024 Koen van der Drift. All rights reserved.
//

import Foundation

public protocol Structure: ChargedMass {
    var name: String { get }
    var formula: Formula { get }
    var adducts: [Adduct] { get set }
}

public extension Structure {
    func calculateMasses() -> MassContainer {
        mass(of: formula.elements)
    }
}
