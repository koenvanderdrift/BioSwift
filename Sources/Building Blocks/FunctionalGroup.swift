//
//  FunctionalGroup.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/9/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public let proton = FunctionalGroup(name: "proton", formula: "H", site: [])
public let hydroxyl = FunctionalGroup(name: "hydroxyl", formula: "OH", site: [])
public let ammonia = FunctionalGroup(name: "ammonia", formula: "NH3", site: [])

public let water = FunctionalGroup(name: "water", formula: "H2O", site: [])
public let nterm = FunctionalGroup(name: "N-term", formula: "H", site: ["NTerminal"])
public let cterm = FunctionalGroup(name: "C-term", formula: "OH", site: ["CTerminal"])

public var functionalGroupLibrary: [FunctionalGroup] = loadJSONFromBundle(fileName: "functionalgroups")


public class FunctionalGroup: Molecule, Codable {
    public let site: [String]

    private enum CodingKeys: String, CodingKey {
        case name
        case formula
        case site
    }

    public init(name: String, formula: Formula, site: [String] = []) {
        self.site = site
        
        super.init(name: name, formula: formula)
    }
    
    convenience public init(name: String, masses: MassContainer, site: [String] = []) {
        self.init(name: name, formula: "", site: site)

        self.masses = masses
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        site = try values.decode([String].self, forKey: .site)

        super.init(name: try values.decode(String.self, forKey: .name),
                   formula: try values.decode(Formula.self, forKey: .formula))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(formula, forKey: .formula)
        try container.encode(site, forKey: .site)
    }
}
