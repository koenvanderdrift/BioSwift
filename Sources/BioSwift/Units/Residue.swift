//
//  Residue.swift
//  BioSwift
//
//  Created by Koen van der Drift on 9/21/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public protocol Residue: Symbol, Structure, Modifiable {
    var oneLetterCode: String { get }
    var threeLetterCode: String { get }
}

extension Residue {
    public var identifier: String {
        return oneLetterCode
    }

    public func calculateMasses() -> MassContainer {
        return mass(of: formula.elements) + modificationMasses()
    }
}
