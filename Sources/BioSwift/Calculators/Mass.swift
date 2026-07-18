//
//  Mass.swift
//  BioSwift
//
//  Created by Koen van der Drift on 1/31/19.
//  Copyright © 2019 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

// https://pnnl-comp-mass-spec.github.io/Molecular-Weight-Calculator-VB6/

public typealias Charge = Int
public typealias Dalton = Decimal

public typealias MassRange = ClosedRange<Dalton>

extension MassRange {
    public func contains(_ masses: MassContainer, for type: MassType) -> Bool {
        switch type {
        case .monoisotopic:
            return contains(masses.monoisotopicMass)
        case .average:
            return contains(masses.averageMass)
        case .nominal:
            return false
        }
    }

    public func lowerLimit(excludes masses: MassContainer) -> Bool {
        masses.monoisotopicMass < 0.95 * lowerBound
    }

    public func upperLimit(excludes masses: MassContainer) -> Bool {
        masses.averageMass > 1.05 * upperBound
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

/// MassContainer is a wrapper around the calculated ``Mass`` for each ``MassType``
/// Monoisotopic and average masses are calculated and stored as Dalton, a Decimal typealias. The nominal mass is calculated and store as an Int.

public struct MassContainer: Codable, Sendable {
    public var monoisotopicMass = Dalton(0.0)
    public var averageMass = Dalton(0.0)
    public var nominalMass = Int(0)
}

extension MassContainer: Equatable {
    public static func + (lhs: MassContainer, rhs: MassContainer) -> MassContainer {
        MassContainer(monoisotopicMass: lhs.monoisotopicMass + rhs.monoisotopicMass, averageMass: lhs.averageMass + rhs.averageMass, nominalMass: lhs.nominalMass + rhs.nominalMass)
    }

    public static func += (lhs: inout MassContainer, rhs: MassContainer) {
        lhs = lhs + rhs
    }

    public static func - (lhs: MassContainer, rhs: MassContainer) -> MassContainer {
        MassContainer(monoisotopicMass: lhs.monoisotopicMass - rhs.monoisotopicMass, averageMass: lhs.averageMass - rhs.averageMass, nominalMass: lhs.nominalMass - rhs.nominalMass)
    }

    public static func -= (lhs: inout MassContainer, rhs: MassContainer) {
        lhs = lhs - rhs
    }

    public static func * (lhs: Int, rhs: MassContainer) -> MassContainer {
        MassContainer(monoisotopicMass: Dalton(lhs) * rhs.monoisotopicMass, averageMass: Dalton(lhs) * rhs.averageMass, nominalMass: lhs * rhs.nominalMass)
    }

    public static func / (lhs: MassContainer, rhs: Int) -> MassContainer {
        MassContainer(monoisotopicMass: lhs.monoisotopicMass / Dalton(rhs), averageMass: lhs.averageMass / Dalton(rhs), nominalMass: Int(lhs.nominalMass / rhs))
    }
}

extension MassContainer: Comparable {
    public static func < (lhs: MassContainer, rhs: MassContainer) -> Bool {
        return lhs.averageMass < rhs.averageMass
    }
}

/// Adducts can be added to any ``Structure`` which conforms to the ``Chargeable`` protocol

public struct Adduct: Codable, Equatable, Sendable {
    public var group: FunctionalGroup
    public var charge: Charge
}

public let protonAdduct = Adduct(group: hydrogen, charge: 1)
public let sodiumAdduct = Adduct(group: sodium, charge: 1)
public let ammoniumAdduct = Adduct(group: ammonium, charge: 1)
public let potassiumAdduct = Adduct(group: potassium, charge: 1)

public let zeroMass = MassContainer(monoisotopicMass: 0.0, averageMass: 0.0, nominalMass: 0)
public let electronMass = MassContainer(monoisotopicMass: Dalton(0.000549), averageMass: Dalton(0.000549), nominalMass: 0)

/// Types conforming to ``Mass`` must provide ``calculateMasses()``.
/// All  calculations use the values provided in https://physics.nist.gov/cgi-bin/Compositions/stand_alone.pl

public protocol Mass {
    var masses: MassContainer { get }

    func calculateMasses() -> MassContainer
}

public extension Mass {
    var monoisotopicMass: Dalton {
        masses.monoisotopicMass
    }

    var averageMass: Dalton {
        masses.averageMass
    }

    var nominalMass: Int {
        masses.nominalMass
    }
}

/// Types conforming to Chargeable must provide one or more``Adduct``  values.
/// In this case, ``MassContainer`` will contain the mass-over-charge ratios

public protocol Chargeable: Mass, Codable {
    var adducts: [Adduct] { get set }
}

public extension Chargeable {
    var charge: Charge {
        adducts.reduce(0) { $0 + $1.charge }
    }

    mutating func setAdducts(type: Adduct, count: Int) {
        adducts = [Adduct](repeating: type, count: count)
    }

    func pseudomolecularIon() -> MassContainer {
        massOverCharge()
    }

    func massOverCharge() -> MassContainer {
        let masses = calculateMasses() + adductMasses()
        let charge = charge > 0 ? charge : 1

        return masses / charge
    }

    func adductMasses() -> MassContainer {
        return adducts.map { $0.group.masses - ($0.charge * electronMass) }
            .reduce(zeroMass) { $0 + $1 }
    }
}

public extension Array where Element: Chain & Chargeable {
    func charge(with range: ClosedRange<Charge>) -> [Element] {
        flatMap { sequence in
            range.map { charge in
                var chargedSequence = sequence
                chargedSequence.adducts.append(contentsOf: repeatElement(protonAdduct, count: charge))

                return chargedSequence
            }
        }
    }
}
