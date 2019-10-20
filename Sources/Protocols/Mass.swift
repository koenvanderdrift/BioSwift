//
//  Mass.swift
//  BioSwift
//
//  Created by Koen van der Drift on 1/31/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public let zeroMass = MassContainer(monoisotopicMass: 0.0, averageMass: 0.0, nominalMass: 0.0)

public protocol Mass {
    var masses: MassContainer { get }
    
    func calculateMasses() -> MassContainer
}

public enum MassType: String {
    case average = "Average"
    case monoisotopic = "Monoisotopic"
    case nominal = "Nominal"
}

public struct MassContainer {
    public var monoisotopicMass = 0.0
    public var averageMass = 0.0
    public var nominalMass = 0.0
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
        return MassContainer(monoisotopicMass: Double(lhs) * rhs.monoisotopicMass, averageMass: Double(lhs) * rhs.averageMass, nominalMass: Double(lhs) * rhs.nominalMass)
    }
    
    public static func / (lhs: MassContainer, rhs: Int) -> MassContainer {
        return MassContainer(monoisotopicMass: lhs.monoisotopicMass / Double(rhs), averageMass: lhs.averageMass / Double(rhs), nominalMass: lhs.nominalMass / Double(rhs))
    }
}
