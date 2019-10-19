//
//  FunctionalGroup.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/9/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public let emptyGroup = FunctionalGroup(name: "empty", formula: Formula(stringValue: ""))
public let hydroxyl = FunctionalGroup(name: "hydroxyl", formula: Formula(stringValue: "OH"))
public let ammonia = FunctionalGroup(name: "ammonia", formula: Formula(stringValue: "NH3"))
public let water = FunctionalGroup(name: "water", formula: Formula(stringValue: "H2O"))

public let nterm = FunctionalGroup(name: "N-term", formula: Formula(stringValue: "H"), sites: ["NTerminal"])
public let cterm = FunctionalGroup(name: "C-term", formula: Formula(stringValue: "OH"), sites: ["CTerminal"])

public let proton = FunctionalGroup(name: "proton", formula: Formula(stringValue: "H"))
public let sodium = FunctionalGroup(name: "Sodium", formula: Formula(stringValue: "Na"))
public let ammonium = FunctionalGroup(name: "Ammonium", formula: Formula(stringValue: "NH4"))

public var functionalGroupLibrary: [FunctionalGroup] = loadJSONFromBundle(fileName: "functionalgroups")

public class FunctionalGroup: Molecule, Codable {
    public let sites: [String]
    public var name: String
    public var formula: Formula

    private enum CodingKeys: String, CodingKey {
        case name
        case formula
        case sites
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        sites = try container.decode([String].self, forKey: .sites)
        name = try container.decode(String.self, forKey: .name)
        formula = Formula(stringValue: try container.decode(String.self, forKey: .formula))
    }
    
    public init(name: String, formula: Formula, sites: [String] = []) {
        self.sites = sites
        self.name = name
        self.formula = formula
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(formula.stringValue, forKey: .formula)
        try container.encode(sites, forKey: .sites)
    }
    
    public lazy var masses: MassContainer = {
        return calculateMasses()
    }()
}

extension FunctionalGroup: Hashable {
    public static func == (lhs: FunctionalGroup, rhs: FunctionalGroup) -> Bool {
        return lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(formula.stringValue)
    }
}

extension FunctionalGroup: Mass {
    public func calculateMasses() -> MassContainer {
        return formula.masses
    }
}
