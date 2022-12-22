//
//  Mass.swift
//  BioSwift
//
//  Created by Koen van der Drift on 1/31/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public typealias Dalton = Double
public typealias MassRange = ClosedRange<Dalton>

extension MassRange {
    func contains(_ masses: MassContainer) -> Bool {
        contains(masses.monoisotopicMass) ||
            contains(masses.averageMass) ||
            contains(Dalton(masses.nominalMass))
    }

    func lowerLimit(excludes masses: MassContainer) -> Bool {
        masses.monoisotopicMass < 0.95 * lowerBound
    }

    func upperLimit(excludes masses: MassContainer) -> Bool {
        masses.averageMass > 1.05 * upperBound
    }
}

public let zeroMass = MassContainer(monoisotopicMass: 0.0, averageMass: 0.0, nominalMass: 0)

public protocol Mass {
    var masses: MassContainer { get }

    func calculateMasses() -> MassContainer
}

// all masses from https://physics.nist.gov/cgi-bin/Compositions/stand_alone.pl

public extension Mass {
    // TO DO rename function calls
    func mass(of symbols: [Symbol]?) -> MassContainer {
        var result = zeroMass

        if let massSymbols = symbols?.compactMap({ $0 as? Mass }) {
            result = mass(of: massSymbols)
        }

        return result
    }

    func mass(of mass: [Mass]) -> MassContainer {
        mass.reduce(zeroMass) { $0 + $1.masses }
    }

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

public enum MassType: String {
    case average = "Average"
    case monoisotopic = "Monoisotopic"
    case nominal = "Nominal"
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
