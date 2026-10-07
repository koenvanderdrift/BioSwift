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
        let charge = adducts.reduce(0) { $0 + $1.charge }
        guard charge != 0 else {
            return self
        }

        let adductMasses = adducts.reduce(zeroMass) {
            switch $1.operation {
            case .add:
                $0 + $1.group.masses
            case .remove:
                $0 - $1.group.masses
            }
        }

        return (self + adductMasses - (charge * electronMass)) / abs(charge)
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

/// Describes whether an adduct adds or removes its functional group.
public enum AdductOperation: String, Codable, Sendable {
    case add
    case remove
}

/// An adduct, its associated charge, and its effect on molecular composition.

public struct Adduct: Codable, Equatable, Sendable {
    public var group: FunctionalGroup
    public var charge: Charge
    public var operation: AdductOperation
    
    public init(
        group: FunctionalGroup,
        charge: Charge,
        operation: AdductOperation = .add
    ) {
        self.group = group
        self.charge = charge
        self.operation = operation
    }

    private enum CodingKeys: String, CodingKey {
        case group
        case charge
        case operation
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        group = try container.decode(FunctionalGroup.self, forKey: .group)
        charge = try container.decode(Charge.self, forKey: .charge)
        operation = try container.decodeIfPresent(AdductOperation.self, forKey: .operation) ?? .add
    }
}

public let protonAdduct = Adduct(group: hydrogen, charge: 1)
public let sodiumAdduct = Adduct(group: sodium, charge: 1)
public let ammoniumAdduct = Adduct(group: ammonium, charge: 1)
public let potassiumAdduct = Adduct(group: potassium, charge: 1)

public let negativeProtonAdduct = Adduct(group: hydrogen, charge: -1, operation: .remove)
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

extension Dalton {
    public func formattedString(fractions: Int) -> String {
        formatted(fractionDigits: fractions)
    }
}

extension Array where Element: Structure {
    public func protonated(chargeStates: ClosedRange<Charge>) throws -> [Ion<Element>] {
        guard chargeStates.lowerBound > 0 else {
            throw BioSwiftDiagnostics.logged(MassCalculationError.invalidChargeState(chargeStates.lowerBound))
        }
        return flatMap { sequence in
            chargeStates.map { charge in
                try! Ion(
                    structure: sequence,
                    adducts: [Adduct](repeating: protonAdduct, count: charge))
            }
        }
    }
}

public enum MassCalculationError: Error, Equatable, Sendable {
    case invalidChargeState(Charge)
}
