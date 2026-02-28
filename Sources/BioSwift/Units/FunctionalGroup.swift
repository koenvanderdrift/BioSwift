//
//  FunctionalGroup.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/22/20.
//  Copyright © 2020 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

public let hydrogen = FunctionalGroup(name: "hydrogen", formula: "H")
public let oxygen = FunctionalGroup(name: "oxygen", formula: "O")

public let hydroxyl = FunctionalGroup(name: "hydroxyl", formula: "OH")
public let ammonia = FunctionalGroup(name: "ammonia", formula: "NH3")
public let carbonyl = FunctionalGroup(name: "carbonyl", formula: "CO")
public let water = FunctionalGroup(name: "water", formula: "H2O")
public let methyl = FunctionalGroup(name: "methyl", formula: "CH3")

public let ammonium = FunctionalGroup(name: "ammonium", formula: "NH4")
public let sodium = FunctionalGroup(name: "sodium", formula: "Na")
public let potassium = FunctionalGroup(name: "potassium", formula: "K")

public struct FunctionalGroup: Structure, Codable {
    public let name: String
    public let formula: Formula

    public init(name: String, formula: String) {
        self.name = name
        self.formula = Formula(formula)
    }

    public init(name: String, elements: [String: Int]) {
        // TODO: switch to [ChemicalElement: Int] ?
        self.name = name
        self.formula = Formula(elements)
    }

    public var masses: MassContainer {
        calculateMasses()
    }

    var description: String {
        name
    }
}

extension FunctionalGroup: Hashable {
    public static func == (lhs: FunctionalGroup, rhs: FunctionalGroup) -> Bool {
        lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(formula.formulaString)
    }
}
