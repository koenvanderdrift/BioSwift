//
//  Mass.swift
//  BioSwift
//
//  Created by Koen van der Drift on 1/31/19.
//  Copyright © 2019 - 2026 Koen van der Drift. All rights reserved.
//

import Foundation

// https://pnnl-comp-mass-spec.github.io/Molecular-Weight-Calculator-VB6/

public typealias Charge = Int
public typealias Dalton = Decimal

public typealias MassRange = ClosedRange<Dalton>

extension MassRange {
    func contains(_ masses: MassContainer, for type: MassType) -> Bool {
        contains(masses.value(for: type))
    }

    func upperLimit(excludes masses: MassContainer, for type: MassType) -> Bool {
        masses.value(for: type) > upperBound
    }

    func isBelow(_ value: MassContainer, for type: MassType) -> Bool {
        value.value(for: type) < lowerBound
    }

    func isAbove(_ value: MassContainer, for type: MassType) -> Bool {
        value.value(for: type) > upperBound
    }
}

/// MassType is an enum defining three different mass types: average, monoisotopic, and nominal
public enum MassType: String, CaseIterable, Codable, Identifiable, Equatable, Sendable {
    case average
    case monoisotopic
    case nominal

    public var id: Self {
        self
    }
}

/// Storage for monoisotopic, average, and nominal mass calculations.

public struct MassContainer: Codable, Sendable, Equatable {
    public private(set) var monoisotopicMass = Dalton(0.0)
    public private(set) var averageMass = Dalton(0.0)
    public private(set) var nominalMass = Int(0)
    
    public init(monoisotopicMass: Dalton = Dalton(0.0), averageMass: Dalton = Dalton(0.0), nominalMass: Int = Int(0)) {
        self.monoisotopicMass = monoisotopicMass
        self.averageMass = averageMass
        self.nominalMass = nominalMass
    }
}

extension MassContainer {
    func value(for type: MassType) -> Dalton {
        switch type {
        case .monoisotopic:
            monoisotopicMass
        case .average:
            averageMass
        case .nominal:
            Dalton(nominalMass)
        }
    }

    func applying(adducts: [Adduct]) -> Self {
    
    // TODO: Negative-ion calculations are not yet supported.
    
        let charge = adducts.reduce(0) { $0 + $1.charge }
        guard charge > 0 else {
            return self
        }

        let adductMasses = adducts.reduce(zeroMass) {
            $0 + $1.group.masses - ($1.charge * electronMass)
        }

        return (self + adductMasses) / charge
    }

}

extension MassContainer {
    static func + (lhs: MassContainer, rhs: MassContainer) -> MassContainer {
        MassContainer(
            monoisotopicMass: lhs.monoisotopicMass + rhs.monoisotopicMass,
            averageMass: lhs.averageMass + rhs.averageMass,
            nominalMass: lhs.nominalMass + rhs.nominalMass)
    }

    static func += (lhs: inout MassContainer, rhs: MassContainer) {
        lhs = lhs + rhs
    }

    static func - (lhs: MassContainer, rhs: MassContainer) -> MassContainer {
        MassContainer(
            monoisotopicMass: lhs.monoisotopicMass - rhs.monoisotopicMass,
            averageMass: lhs.averageMass - rhs.averageMass,
            nominalMass: lhs.nominalMass - rhs.nominalMass)
    }

    static func -= (lhs: inout MassContainer, rhs: MassContainer) {
        lhs = lhs - rhs
    }

    static func * (lhs: Int, rhs: MassContainer) -> MassContainer {
        MassContainer(
            monoisotopicMass: Dalton(lhs) * rhs.monoisotopicMass,
            averageMass: Dalton(lhs) * rhs.averageMass, nominalMass: lhs * rhs.nominalMass)
    }

    static func / (lhs: MassContainer, rhs: Int) -> MassContainer {
        MassContainer(
            monoisotopicMass: lhs.monoisotopicMass / Dalton(rhs),
            averageMass: lhs.averageMass / Dalton(rhs), nominalMass: Int(lhs.nominalMass / rhs))
    }
}

/// An adduct and its associated charge.

public struct Adduct: Codable, Equatable, Sendable {
    public var group: FunctionalGroup
    public var charge: Charge
    
    public init(group: FunctionalGroup, charge: Charge) {
        self.group = group
        self.charge = charge
    }
}

public let protonAdduct = Adduct(group: hydrogen, charge: 1)
public let sodiumAdduct = Adduct(group: sodium, charge: 1)
public let ammoniumAdduct = Adduct(group: ammonium, charge: 1)
public let potassiumAdduct = Adduct(group: potassium, charge: 1)

public let negativeProtonAdduct = Adduct(group: hydrogen, charge: -1)
public let chlorineAdduct = Adduct(group: chloride, charge: -1)

let zeroMass = MassContainer(monoisotopicMass: 0.0, averageMass: 0.0, nominalMass: 0)
let electronMass = MassContainer(
    monoisotopicMass: Dalton(0.000549), averageMass: Dalton(0.000549), nominalMass: 0)

/// Internal common interface for calculating neutral molecular masses.
/// Elemental masses use the bundled NIST isotope data.
protocol MassRepresentable {
    var masses: MassContainer { get }
}

extension MassRepresentable {
    public var monoisotopicMass: Dalton {
        masses.monoisotopicMass
    }

    public var averageMass: Dalton {
        masses.averageMass
    }

    public var nominalMass: Int {
        masses.nominalMass
    }
}

/// Internal common interface for structures that can carry adducts.
protocol Ionizable {
    var masses: MassContainer { get }

    var adducts: [Adduct] {
        get set
    }
}

extension Dalton {
    public func formattedString(fractions: Int) -> String {
        formatted(fractionDigits: fractions)
    }
}

extension Array where Element: Chain {
    public func protonated(chargeStates: ClosedRange<Charge>) -> [Element] {
        flatMap { sequence in
            chargeStates.compactMap { charge -> Element? in
                guard charge >= 0 else {
                    return nil
                }

                var chargedSequence = sequence
                chargedSequence.adducts = [Adduct](repeating: protonAdduct, count: charge)

                return chargedSequence
            }
        }
    }
}
