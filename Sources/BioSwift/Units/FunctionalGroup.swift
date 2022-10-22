//
//  FunctionalGroup.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/22/20.
//

import Foundation

public let hydroxyl = FunctionalGroup(name: "hydroxyl", formula: "OH")
public let ammonia = FunctionalGroup(name: "ammonia", formula: "NH3")
public let water = FunctionalGroup(name: "water", formula: "H2O")
public let hydrogen = FunctionalGroup(name: "hydrogen", formula: "H")
public let methyl = FunctionalGroup(name: "methyl", formula: "CH3")

public let proton = FunctionalGroup(name: "proton", formula: "H")
public let sodium = FunctionalGroup(name: "sodium", formula: "Na")
public let ammonium = FunctionalGroup(name: "ammonium", formula: "NH4")

public struct FunctionalGroup: Structure, Codable {
    public let name: String
    public let formula: Formula
    public var adducts: [Adduct]

    private(set) var _masses: MassContainer = zeroMass

    private enum CodingKeys: String, CodingKey {
        case name
        case formula
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)
        formula = Formula(try container.decode(String.self, forKey: .formula))
        adducts = []

        _masses = calculateMasses()
    }

    public init(name: String, formula: String) {
        self.name = name
        self.formula = Formula(formula)
        adducts = []

        _masses = calculateMasses()
    }

    public init(name: String, formula: [String: Int]) {
        self.name = name
        self.formula = Formula(formula)
        adducts = []

        _masses = calculateMasses()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(formula.formulaString, forKey: .formula)
    }

    public var masses: MassContainer {
        return _masses
    }

    var description: String {
        return name
    }
}

extension FunctionalGroup: Hashable {
    public static func == (lhs: FunctionalGroup, rhs: FunctionalGroup) -> Bool {
        return lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(formula.formulaString)
    }
}

extension FunctionalGroup: Mass {
    public func calculateMasses() -> MassContainer {
        return mass(of: formula.elements)
    }
}
