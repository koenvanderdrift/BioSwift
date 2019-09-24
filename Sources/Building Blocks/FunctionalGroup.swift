//
//  FunctionalGroup.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/9/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public let emptyGroup = FunctionalGroup(name: "empty", formula: "", sites: [])
public let proton = FunctionalGroup(name: "proton", formula: "H", sites: [])
public let hydroxyl = FunctionalGroup(name: "hydroxyl", formula: "OH", sites: [])
public let ammonia = FunctionalGroup(name: "ammonia", formula: "NH3", sites: [])

public let water = FunctionalGroup(name: "water", formula: "H2O", sites: [])
public let nterm = FunctionalGroup(name: "N-term", formula: "H", sites: ["NTerminal"])
public let cterm = FunctionalGroup(name: "C-term", formula: "OH", sites: ["CTerminal"])

public var functionalGroupLibrary: [FunctionalGroup] = loadJSONFromBundle(fileName: "functionalgroups")

public struct FunctionalGroup: Molecule, Codable {
    public let sites: [String]
    public var name: String
    public var formula: Formula

    private enum CodingKeys: String, CodingKey {
        case name
        case formula
        case sites
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        self.sites = try values.decode([String].self, forKey: .sites)
        self.name = try values.decode(String.self, forKey: .name)
        self.formula = try values.decode(Formula.self, forKey: .formula)
    }
    
    public init(name: String, formula: Formula, sites: [String] = []) {
        self.sites = sites
        self.name = name
        self.formula = formula
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(formula, forKey: .formula)
        try container.encode(sites, forKey: .sites)
    }
}

extension FunctionalGroup: Mass {
    public var masses: MassContainer {
        return calculateMasses()
    }
    
    public var charge: Int {
        return 0
    }

    public func calculateMasses() -> MassContainer {
        return formula.components(separatedBy: formulaSeparator)
            .reduce(zeroMass, {$0 + $1.masses})
    }
}
