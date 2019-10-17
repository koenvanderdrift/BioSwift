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
//        self.formula = try values.decode(Formula.self, forKey: .formula)
        self.formula = Formula(stringValue: "C3H5O")
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
    
    //    public lazy var masses: MassContainer = {
    //        return calculateMasses()
    //    }()

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
    public var masses: MassContainer {
        return calculateMasses()
    }
    
    public func calculateMasses() -> MassContainer {
        let components = formula.stringValue.components(separatedBy: formulaSeparator)
        
        let result = components.indices.map { index in
            var f = Formula(stringValue: components[index])
            return f.masses
        }.reduce(zeroMass, +)
        
        return result
    }
}
