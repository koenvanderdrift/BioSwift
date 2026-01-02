//
//  Mass.swift
//  BioSwift
//
//  Created by Koen van der Drift on 1/31/19.
//  Copyright © 2019 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

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
        masses.monoisotopicMass < 0.95 * lowerBound
    }

    func upperLimit(excludes masses: MassContainer) -> Bool {
        masses.averageMass > 1.05 * upperBound
    }
}

public enum MassType: String, CaseIterable {
    case average
    case monoisotopic
    case nominal
}

public struct MassContainer {
    public var monoisotopicMass = Dalton(0.0)
    public var averageMass = Dalton(0.0)
    public var nominalMass = 0
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

public struct Adduct: Codable {
    var group: FunctionalGroup
    var charge: Int
}

public let protonAdduct = Adduct(group: hydrogen, charge: 1)
public let sodiumAdduct = Adduct(group: sodium, charge: 1)
public let ammoniumAdduct = Adduct(group: ammonium, charge: 1)
public let potassiumAdduct = Adduct(group: potassium, charge: 1)

public let zeroMass = MassContainer(monoisotopicMass: 0.0, averageMass: 0.0, nominalMass: 0)
public let electronMass = MassContainer(monoisotopicMass: Dalton(0.000549), averageMass: Dalton(0.000549), nominalMass: 0)

public protocol Mass {
    var masses: MassContainer { get }

    func calculateMasses() -> MassContainer
}

// all masses from https://physics.nist.gov/cgi-bin/Compositions/stand_alone.pl

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

public protocol Chargeable: Mass {
    var adducts: [Adduct] { get set }
}

public extension Chargeable {
    var charge: Int {
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

public extension Collection where Element: Chargeable {
    func charge(minCharge: Int, maxCharge: Int) -> [Element] {
        flatMap { sequence in
            (minCharge ... maxCharge).map { charge in
                var chargedSequence = sequence
                chargedSequence.adducts.append(contentsOf: repeatElement(protonAdduct, count: charge))

                return chargedSequence
            }
        }
    }
}
