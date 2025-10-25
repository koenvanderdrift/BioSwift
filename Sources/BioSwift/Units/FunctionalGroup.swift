//
//  FunctionalGroup.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/22/20.
//  Copyright © 2020 - 2024 Koen van der Drift. All rights reserved.
//

import Foundation

public let hydroxyl = FunctionalGroup(name: "hydroxyl", formula: "OH")
public let ammonia = FunctionalGroup(name: "ammonia", formula: "NH3")
public let carbonyl = FunctionalGroup(name: "carbonyl", formula: "CO")
public let water = FunctionalGroup(name: "water", formula: "H2O")
public let hydrogen = FunctionalGroup(name: "hydrogen", formula: "H")
public let oxygen = FunctionalGroup(name: "oxygen", formula: "O")
public let methyl = FunctionalGroup(name: "methyl", formula: "CH3")

public let proton = FunctionalGroup(name: "proton", formula: "H")
public let sodium = FunctionalGroup(name: "sodium", formula: "Na")
public let ammonium = FunctionalGroup(name: "ammonium", formula: "NH4")

public struct FunctionalGroup: Structure, Codable {
    public let name: String
    public let formula: Formula
    public var adducts: [Adduct]

    public init(name: String, formula: String) {
        self.name = name
        self.formula = Formula(formula)
        adducts = []
    }

    public init(name: String, formula: [String: Int]) {
        self.name = name
        self.formula = Formula(formula)
        adducts = []
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
