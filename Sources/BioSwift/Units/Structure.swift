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
}

extension Structure {
    var neutralMasses: MassContainer {
        formula.neutralMasses
    }

    public var monoisotopicMass: Dalton {
        neutralMasses.monoisotopicMass
    }

    public var averageMass: Dalton {
        neutralMasses.averageMass
    }

    public var nominalMass: Int {
        neutralMasses.nominalMass
    }
}
