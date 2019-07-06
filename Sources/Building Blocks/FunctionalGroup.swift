//
//  FunctionalGroup.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/9/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public let proton = FunctionalGroup(name: "proton", formula: "H", sites: [])
public let hydroxyl = FunctionalGroup(name: "hydroxyl", formula: "OH", sites: [])
public let ammonia = FunctionalGroup(name: "ammonia", formula: "NH3", sites: [])

public let water = FunctionalGroup(name: "water", formula: "H2O", sites: [])
public let nterm = FunctionalGroup(name: "N-term", formula: "H", sites: ["NTerminal"])
public let cterm = FunctionalGroup(name: "C-term", formula: "OH", sites: ["CTerminal"])

public var functionalGroupLibrary: [FunctionalGroup] = loadJSONFromBundle(fileName: "functionalgroups")


public class FunctionalGroup: Molecule, Codable {
    public let sites: [String]

    private enum CodingKeys: String, CodingKey {
        case name
        case formula
        case sites
    }

    public init(name: String, formula: Formula, sites: [String] = []) {
        self.sites = sites
        
        super.init(name: name, formula: formula)
    }
    
    convenience public init(name: String, masses: MassContainer, sites: [String] = []) {
        self.init(name: name, formula: "", sites: sites)

        self.masses = masses
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        sites = try values.decode([String].self, forKey: .sites)

        super.init(name: try values.decode(String.self, forKey: .name),
                   formula: try values.decode(Formula.self, forKey: .formula))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(formula, forKey: .formula)
        try container.encode(sites, forKey: .sites)
    }
}
