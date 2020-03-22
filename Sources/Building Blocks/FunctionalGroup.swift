//
//  FunctionalGroup.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/9/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public typealias FunctionalGroup = Molecule

public let hydroxyl = FunctionalGroup(name: "hydroxyl", formula: Formula("OH"))
public let ammonia = FunctionalGroup(name: "ammonia", formula: Formula("NH3"))
public let water = FunctionalGroup(name: "water", formula: Formula("H2O"))
public let hydrogen = FunctionalGroup(name: "hydrogen", formula: Formula("H"))

public let proton = FunctionalGroup(name: "proton", formula: Formula("H"))
public let sodium = FunctionalGroup(name: "sodium", formula: Formula("Na"))
public let ammonium = FunctionalGroup(name: "ammonium", formula: Formula("NH4"))
