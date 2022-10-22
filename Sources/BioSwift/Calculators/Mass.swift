//
//  Mass.swift
//  BioSwift
//
//  Created by Koen van der Drift on 1/31/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public typealias Dalton = Double
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
        return mass.reduce(zeroMass) { $0 + $1.masses }
    }

    var monoisotopicMass: Dalton {
        return masses.monoisotopicMass
    }

    var averageMass: Dalton {
        return masses.averageMass
    }

    var nominalMass: Int {
        return masses.nominalMass
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
        return MassContainer(monoisotopicMass: lhs.monoisotopicMass + rhs.monoisotopicMass, averageMass: lhs.averageMass + rhs.averageMass, nominalMass: lhs.nominalMass + rhs.nominalMass)
    }

    public static func += (lhs: inout MassContainer, rhs: MassContainer) {
        lhs = lhs + rhs
    }

    public static func - (lhs: MassContainer, rhs: MassContainer) -> MassContainer {
        return MassContainer(monoisotopicMass: lhs.monoisotopicMass - rhs.monoisotopicMass, averageMass: lhs.averageMass - rhs.averageMass, nominalMass: lhs.nominalMass - rhs.nominalMass)
    }

    public static func -= (lhs: inout MassContainer, rhs: MassContainer) {
        lhs = lhs - rhs
    }

    public static func * (lhs: Int, rhs: MassContainer) -> MassContainer {
        return MassContainer(monoisotopicMass: Dalton(lhs) * rhs.monoisotopicMass, averageMass: Dalton(lhs) * rhs.averageMass, nominalMass: lhs * rhs.nominalMass)
    }

    public static func / (lhs: MassContainer, rhs: Int) -> MassContainer {
        return MassContainer(monoisotopicMass: lhs.monoisotopicMass / Dalton(rhs), averageMass: lhs.averageMass / Dalton(rhs), nominalMass: Int(lhs.nominalMass / rhs))
    }
}
