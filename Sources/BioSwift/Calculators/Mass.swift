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
        switch type {
        case .monoisotopic:
            return contains(masses.monoisotopicMass)

        case .average:
            return contains(masses.averageMass)

        case .nominal:
            return false
        }
    }

    func lowerLimit(excludes masses: MassContainer) -> Bool {
        masses.monoisotopicMass < 0.99 * lowerBound
    }

    func upperLimit(excludes masses: MassContainer) -> Bool {
        masses.averageMass > 1.01 * upperBound
    }

    func isBelow(_ value: MassContainer, for type: MassType) -> Bool {
        switch type {
        case .monoisotopic:
            return value.monoisotopicMass < lowerBound

        case .average:
            return value.averageMass < lowerBound

        case .nominal:
            return false
        }
    }

    func isAbove(_ value: MassContainer, for type: MassType) -> Bool {
        switch type {
        case .monoisotopic:
            return value.monoisotopicMass > upperBound

        case .average:
            return value.averageMass > upperBound

        case .nominal:
            return false
        }
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

/// Internal storage for monoisotopic, average, and nominal mass calculations.

struct MassContainer: Codable, Sendable {
    var monoisotopicMass = Dalton(0.0)
    var averageMass = Dalton(0.0)
    var nominalMass = Int(0)
    
    init(monoisotopicMass: Dalton = Dalton(0.0), averageMass: Dalton = Dalton(0.0), nominalMass: Int = Int(0)) {
        self.monoisotopicMass = monoisotopicMass
        self.averageMass = averageMass
        self.nominalMass = nominalMass
    }
}

extension MassContainer {
    func applying(adducts: [Adduct]) -> Self {
        let charge = adducts.reduce(0) { $0 + $1.charge }
        guard charge > 0 else {
            return self
        }

        let adductMasses = adducts.reduce(zeroMass) {
            $0 + $1.group.neutralMasses - ($1.charge * electronMass)
        }

        return (self + adductMasses) / charge
    }

}

extension MassContainer: Equatable {
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

extension MassContainer: Comparable {
    static func < (lhs: MassContainer, rhs: MassContainer) -> Bool {
        return lhs.averageMass < rhs.averageMass
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
    var neutralMasses: MassContainer { get }
}

extension MassRepresentable {
    public var monoisotopicMass: Dalton {
        neutralMasses.monoisotopicMass
    }

    public var averageMass: Dalton {
        neutralMasses.averageMass
    }

    public var nominalMass: Int {
        neutralMasses.nominalMass
    }
}

/// Internal common interface for structures that can carry adducts.
protocol Ionizable: MassRepresentable {
    var adducts: [Adduct] {
        get set
    }
}

extension Ionizable {
    /// The monoisotopic mass for a neutral molecule, or m/z when adducts give it a charge.
    public var monoisotopicMass: Dalton {
        neutralMasses.applying(adducts: adducts).monoisotopicMass
    }

    /// The average mass for a neutral molecule, or m/z when adducts give it a charge.
    public var averageMass: Dalton {
        neutralMasses.applying(adducts: adducts).averageMass
    }

    /// The nominal mass for a neutral molecule, or nominal m/z when adducts give it a charge.
    public var nominalMass: Int {
        neutralMasses.applying(adducts: adducts).nominalMass
    }

    public var charge: Charge {
        adducts.reduce(0) {
            $0 + $1.charge
        }
    }

    public mutating func setAdducts(_ adducts: [Adduct]) {
        self.adducts = adducts
    }

    public mutating func setAdducts(type: Adduct, count: Int) {
        let adducts = Array(repeating: type, count: count)
        setAdducts(adducts)
    }

}

extension Dalton {
    public func formattedString(fractions: Int) -> String {
        formatted(fractionDigits: fractions)
    }
}

extension Array where Element: Chain {
    func charge(with range: ClosedRange<Charge>) -> [Element] {
        flatMap { sequence in
            range.map { charge in
                var chargedSequence = sequence
                chargedSequence.adducts.append(
                    contentsOf: repeatElement(protonAdduct, count: charge))

                return chargedSequence
            }
        }
    }
}
