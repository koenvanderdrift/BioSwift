//
//  Mass.swift
//  BioSwift
//
//  Created by Koen van der Drift on 1/31/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public let zeroMass = MassContainer(monoisotopicMass: 0.0, averageMass: 0.0, nominalMass: 0)

public protocol Mass {
    var masses: MassContainer { get }
    
    func calculateMasses() -> MassContainer
}

// all masses from https://physics.nist.gov/cgi-bin/Compositions/stand_alone.pl


extension Mass {
    // TO DO rename function calls
    public func mass(of symbols: [Symbol]?) -> MassContainer {
        var result = zeroMass
        
        if let massSymbols = symbols?.compactMap({ $0 as? Mass }) {
            result = mass(of: massSymbols)
        }
            
        return result
    }
    
    public func mass(of mass: [Mass]) -> MassContainer {
        return mass.reduce(zeroMass, { $0 + $1.masses })
    }
    
    public var monoisotopicMass: Decimal {
        return masses.monoisotopicMass
    }

    public var averageMass: Decimal {
        return masses.averageMass
    }

    public var nominalMass: Int {
        return masses.nominalMass
    }
}

public enum MassType: String {
    case average = "Average"
    case monoisotopic = "Monoisotopic"
    case nominal = "Nominal"
}

public struct MassContainer {
    public var monoisotopicMass = Decimal(0.0)
    public var averageMass = Decimal(0.0)
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
        return MassContainer(monoisotopicMass: Decimal(lhs) * rhs.monoisotopicMass, averageMass: Decimal(lhs) * rhs.averageMass, nominalMass: lhs * rhs.nominalMass)
    }
    
    public static func / (lhs: MassContainer, rhs: Int) -> MassContainer {
        return MassContainer(monoisotopicMass: lhs.monoisotopicMass / Decimal(rhs), averageMass: lhs.averageMass / Decimal(rhs), nominalMass: Int(lhs.nominalMass / rhs))
    }
}


extension Decimal {
    public func roundedString(_ round: Int) -> String {
        var rounded = Decimal()
        var selfCopy = self
        
        NSDecimalRound(&rounded, &selfCopy, round, .plain)

        return "\(rounded)"
    }
    
    public func doubleValue() -> Double {
        return Double(truncating: self as NSNumber)
    }
}
