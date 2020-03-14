//
//  FunctionalGroup.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/9/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public let emptyGroup = FunctionalGroup(name: "empty", formula: Formula(""))
public let hydroxyl = FunctionalGroup(name: "hydroxyl", formula: Formula("OH"))
public let ammonia = FunctionalGroup(name: "ammonia", formula: Formula("NH3"))
public let water = FunctionalGroup(name: "water", formula: Formula("H2O"))
public let methyl = FunctionalGroup(name: "methyl", formula: Formula("CH3"))
public let acetyl = FunctionalGroup(name: "acetyl", formula: Formula("CH2CO"))
public let amide = FunctionalGroup(name: "amide", formula: Formula("NH2"))
public let carboxyl = FunctionalGroup(name: "carbonyl", formula: Formula("COOH"))
public let hydrogen = FunctionalGroup(name: "hydrogen", formula: Formula("H"))

public let proton = FunctionalGroup(name: "proton", formula: Formula("H"))
public let oxygen = FunctionalGroup(name: "oxygen", formula: Formula("O"))
public let sodium = FunctionalGroup(name: "sodium", formula: Formula("Na"))
public let ammonium = FunctionalGroup(name: "ammonium", formula: Formula("NH4"))

public let cysteinyl = FunctionalGroup(name: "cysteinyl", formula: Formula("C3H5NO2S"))

public struct FunctionalGroup: Molecule, Codable {
    public let name: String
    public let formula: Formula

    private(set) var _masses: MassContainer = zeroMass

    private enum CodingKeys: String, CodingKey {
        case name
        case formula
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)
        formula = Formula(try container.decode(String.self, forKey: .formula))

        _masses = calculateMasses()
    }
    
    public init(name: String, formula: Formula) {
        self.name = name
        self.formula = formula

        _masses = calculateMasses()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(formula.string, forKey: .formula)
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
        hasher.combine(formula.string)
    }
}

extension FunctionalGroup: Mass {
    public func calculateMasses() -> MassContainer {
        return mass(of: formula.elements)
    }
}
