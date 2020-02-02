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

public let nterm = FunctionalGroup(name: "N-term", formula: Formula("H"), sites: ["NTerminal"])
public let cterm = FunctionalGroup(name: "C-term", formula: Formula("OH"), sites: ["CTerminal"])

public let proton = FunctionalGroup(name: "proton", formula: Formula("H"))
public let sodium = FunctionalGroup(name: "Sodium", formula: Formula("Na"))
public let ammonium = FunctionalGroup(name: "Ammonium", formula: Formula("NH4"))

public var functionalGroupLibrary: [FunctionalGroup] = loadJSONFromBundle(fileName: "functionalgroups")

public struct FunctionalGroup: Molecule, Codable {
    public let name: String
    public let formula: Formula
    public let sites: [String]

    private(set) var _masses: MassContainer = zeroMass

    private enum CodingKeys: String, CodingKey {
        case name
        case formula
        case sites
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)
        sites = try container.decode([String].self, forKey: .sites)
        formula = Formula(try container.decode(String.self, forKey: .formula))

        _masses = calculateMasses()
    }
    
    public init(name: String, formula: Formula, sites: [String] = []) {
        self.name = name
        self.formula = formula
        self.sites = sites

        _masses = calculateMasses()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(formula.string, forKey: .formula)
        try container.encode(sites, forKey: .sites)
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
