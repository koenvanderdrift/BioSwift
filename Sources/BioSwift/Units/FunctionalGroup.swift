//
//  FunctionalGroup.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/22/20.
//  Copyright © 2020 - 2026 Koen van der Drift. All rights reserved.
//

import Foundation

public let hydrogen = makeBuiltInFunctionalGroup(name: "hydrogen", formula: "H")
public let oxygen = makeBuiltInFunctionalGroup(name: "oxygen", formula: "O")
public let phosphorus = makeBuiltInFunctionalGroup(name: "phosphorus", formula: "P")

public let hydroxyl = makeBuiltInFunctionalGroup(name: "hydroxyl", formula: "OH")
public let ammonia = makeBuiltInFunctionalGroup(name: "ammonia", formula: "NH3")
public let carbonyl = makeBuiltInFunctionalGroup(name: "carbonyl", formula: "CO")
public let water = makeBuiltInFunctionalGroup(name: "water", formula: "H2O")
public let methyl = makeBuiltInFunctionalGroup(name: "methyl", formula: "CH3")

public let ammonium = makeBuiltInFunctionalGroup(name: "ammonium", formula: "NH4")
public let sodium = makeBuiltInFunctionalGroup(name: "sodium", formula: "Na")
public let potassium = makeBuiltInFunctionalGroup(name: "potassium", formula: "K")

public let chloride = makeBuiltInFunctionalGroup(name: "chloride", formula: "Cl")

public let adenine = makeBuiltInFunctionalGroup(name: "adenine", formula: "C5H5N5")
public let cytosine = makeBuiltInFunctionalGroup(name: "cytosine", formula: "C4H5N3O")
public let guanine = makeBuiltInFunctionalGroup(name: "guanine", formula: "C5H5N5O")
public let thymine = makeBuiltInFunctionalGroup(name: "thymine", formula: "C5H6N2O2")
public let uracil = makeBuiltInFunctionalGroup(name: "uracil", formula: "C4H4N2O2")

private func makeBuiltInFunctionalGroup(name: String, formula: String) -> FunctionalGroup {
    do {
        return FunctionalGroup(name: name, formula: try Formula(formula))
    } catch {
        preconditionFailure("Invalid built-in formula \(formula): \(error)")
    }
}

public struct FunctionalGroup: Structure, Codable, Sendable {
    public let name: String
    public let formula: Formula

    public init(name: String, formula: Formula) {
        self.name = name
        self.formula = formula
    }

    public init(name: String, formula: String) throws {
        self.name = name
        self.formula = try Formula(formula)
    }

    public init(name: String, elements: [String: Int]) throws {
        self.name = name
        formula = try Formula(elements: elements)
    }

    public var description: String {
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
