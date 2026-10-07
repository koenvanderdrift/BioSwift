//
//  Structure.swift
//  BioSwift
//
//  Created by Koen van der Drift on 9/21/19.
//  Copyright © 2019 - 2026 Koen van der Drift. All rights reserved.
//

import Foundation

// Structure is the basic building block with a name and ``Formula``

public protocol Structure {
    var name: String {
        get
    }

    var formula: Formula {
        get
    }

    var masses: MassContainer {
        get
    }
}

extension Structure {
    public var masses: MassContainer {
        formula.masses
    }

    /// The molecular formula formatted using Hill-system element ordering.
    public var formulaString: String {
        formula.formulaString
    }

    public var monoisotopicMass: Dalton {
        masses.monoisotopicMass
    }

    public var averageMass: Dalton {
        masses.averageMass
    }

    public var nominalMass: Int {
        masses.nominalMass
    }
}
