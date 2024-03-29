//
//  Residue.swift
//  BioSwift
//
//  Created by Koen van der Drift on 9/21/19.
//  Copyright © 2019 - 2024 Koen van der Drift. All rights reserved.
//

import Foundation

public protocol Residue: Symbol, Structure, Modifiable {
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
}
