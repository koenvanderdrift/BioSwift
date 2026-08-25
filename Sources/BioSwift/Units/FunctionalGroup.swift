//
//  FunctionalGroup.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/22/20.
//  Copyright © 2020 - 2026 Koen van der Drift. All rights reserved.
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

public let chloride = FunctionalGroup(name: "chloride", formula: "Cl")

public struct FunctionalGroup: Structure, Codable, Sendable {
    public let name: String
    public let formula: Formula

    public init(
        name: String, formula: String,
        elements: ElementReferences = ElementReferenceDefaults.bundled
    ) {
        self.name = name
        self.formula = Formula(formula, elements: elements)
    }

    public init(
        name: String, elements: [String: Int],
        elementReferences: ElementReferences = ElementReferenceDefaults.bundled
    ) {
        self.name = name
        formula = Formula(from: elements, elements: elementReferences)
    }

    public var masses: MassContainer {
        calculateMasses()
    }

    public var description: String {
        name
    }

    public var chemicalString: String {
        formula.chemicalString
    }
}

extension FunctionalGroup: Hashable {
    public static func == (lhs: FunctionalGroup, rhs: FunctionalGroup) -> Bool {
        lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(formula.string)
    }
}
