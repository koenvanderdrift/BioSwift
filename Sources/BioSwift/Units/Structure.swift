//
//  Structure.swift
//  BioSwift
//
//  Created by Koen van der Drift on 9/21/19.
//  Copyright © 2019 - 2026 Koen van der Drift. All rights reserved.
//

import Foundation

// Structure is the basic building block with a name and ``Formula``

public protocol Structure: MassRepresentable {
    var name: String {
        get
    }

    var formula: Formula {
        get
    }
}

extension Structure {
    public func calculateMasses() -> MassContainer {
        formula.masses
    }
}
