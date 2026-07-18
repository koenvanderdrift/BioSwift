//
//  ChemicalElement.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/15/18.
//  Copyright © 2018 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

public struct Isotope: Codable, Sendable {
    public let mass: String
    public let ordinalNumber: String
    public let abundance: String
}

/// ChemicalElement conforms to ``Symbol`` and is the building block for every chemical structure
public struct ChemicalElement: Codable, Symbol, Sendable {
    public let name: String
    public let symbol: String
    public let isotopes: [Isotope]
    public var cachedMasses: MassContainer = zeroMass

    public init(name: String, symbol: String, isotopes: [Isotope]) {
        self.name = name
        self.symbol = symbol
        self.isotopes = isotopes

        setUp()
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)
        symbol = try container.decode(String.self, forKey: .symbol)
        isotopes = try container.decode([Isotope].self, forKey: .isotopes)

        setUp()
    }

    public init(name: String, symbol: String, monoisotopicMass: Dalton, averageMass: Dalton) {
        // only called when loadElementsFromUnimod == true
        self.name = name
        self.symbol = symbol
        isotopes = []

        setUp()
    }

    private mutating func setUp() {
        cachedMasses = calculateMasses()
    }

    public var identifier: String {
        symbol
    }

    public var description: String {
        symbol
    }
}

extension ChemicalElement: Equatable, Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.symbol == rhs.symbol && lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

extension ChemicalElement: Mass {
    public var masses: MassContainer {
        cachedMasses
    }

    public func calculateMasses() -> MassContainer {
        var currentAbundance = Decimal(0.0)
        var monoisotopicMass = Dalton(0.0)
        var averageMass = Dalton(0.0)

        // The nominal mass for an element is the mass number of its most abundant naturally occurring stable isotope
        for i in isotopes {
            if let abundance = Decimal(string: i.abundance), let mass = Decimal(string: i.mass) {
                if abundance > currentAbundance {
                    monoisotopicMass = mass
                    currentAbundance = abundance
                }

                averageMass += abundance * mass
            }
        }
        
        let nominalMass = monoisotopicMass.roundedInt()

        return MassContainer(monoisotopicMass: monoisotopicMass, averageMass: averageMass / Decimal(100), nominalMass: nominalMass ?? 0)
    }
}
