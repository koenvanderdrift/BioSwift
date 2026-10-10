//
//  MassTolerance.swift
//  BioSwift
//
//  Copyright © 2026 Koen van der Drift. All rights reserved.
//

import Foundation

/// A validated, nonnegative tolerance used when comparing masses.
public struct MassTolerance: Equatable, Sendable {
    public enum Unit: String, CaseIterable, Codable, Identifiable, Sendable {
        case dalton
        case ppm
        case percent
        case mmu

        public var id: Self {
            self
        }

        public var symbol: String {
            switch self {
            case .dalton:
                "Da"
            case .ppm:
                "ppm"
            case .percent:
                "%"
            case .mmu:
                "mmu"
            }
        }
    }

    public let value: Decimal
    public let unit: Unit

    public init(_ value: Decimal, unit: Unit) throws {
        guard !value.isNaN, value >= 0 else {
            throw BioSwiftDiagnostics.logged(MassToleranceError.invalidValue(value))
        }

        self.value = value
        self.unit = unit
    }

    public static func daltons(_ value: Dalton) throws -> Self {
        try Self(value, unit: .dalton)
    }

    public static func ppm(_ value: Decimal) throws -> Self {
        try Self(value, unit: .ppm)
    }

    public static func percent(_ value: Decimal) throws -> Self {
        try Self(value, unit: .percent)
    }

    public static func mmu(_ value: Decimal) throws -> Self {
        try Self(value, unit: .mmu)
    }

    /// Returns the distance in daltons from the reference to either tolerance boundary.
    public func daltonRadius(at reference: Dalton) -> Dalton {
        switch unit {
        case .dalton:
            value
        case .ppm:
            abs(reference) * value / 1_000_000
        case .percent:
            abs(reference) * value / 100
        case .mmu:
            value / 1_000
        }
    }

    /// Returns an inclusive tolerance range centered on the reference mass.
    public func range(around reference: Dalton) -> MassRange {
        let radius = daltonRadius(at: reference)
        return (reference - radius)...(reference + radius)
    }

    /// Returns whether an observed mass is within tolerance of a theoretical mass.
    public func contains(_ observed: Dalton, relativeTo theoretical: Dalton) -> Bool {
        range(around: theoretical).contains(observed)
    }

    /// Returns the tolerance radius for a structure's requested mass representation.
    public func daltonRadius(
        at structure: any Structure,
        massType: MassType = .monoisotopic
    ) -> Dalton {
        daltonRadius(at: structure.mass(for: massType))
    }

    /// Returns an inclusive tolerance range centered on a structure's requested mass.
    public func range(
        around structure: any Structure,
        massType: MassType = .monoisotopic
    ) -> MassRange {
        range(around: structure.mass(for: massType))
    }

    /// Compares the requested mass representation of any two structures.
    public func contains(
        _ observed: any Structure,
        relativeTo theoretical: any Structure,
        massType: MassType = .monoisotopic
    ) -> Bool {
        contains(
            observed.mass(for: massType),
            relativeTo: theoretical.mass(for: massType)
        )
    }

    /// Compares a structure's requested mass representation with a numeric theoretical mass.
    public func contains(
        _ observed: any Structure,
        relativeTo theoretical: Dalton,
        massType: MassType = .monoisotopic
    ) -> Bool {
        contains(observed.mass(for: massType), relativeTo: theoretical)
    }

    /// Compares a numeric observed mass with a structure's requested mass representation.
    public func contains(
        _ observed: Dalton,
        relativeTo theoretical: any Structure,
        massType: MassType = .monoisotopic
    ) -> Bool {
        contains(observed, relativeTo: theoretical.mass(for: massType))
    }

    /// Converts this tolerance to another unit at a particular reference mass.
    public func converted(to targetUnit: Unit, at reference: Dalton) throws -> Self {
        guard targetUnit != unit else {
            return self
        }

        let radius = daltonRadius(at: reference)
        let convertedValue: Decimal

        switch targetUnit {
        case .dalton:
            convertedValue = radius
        case .mmu:
            convertedValue = radius * 1_000
        case .ppm:
            guard reference != 0 else {
                throw BioSwiftDiagnostics.logged(MassToleranceError.zeroReferenceMass)
            }
            convertedValue = radius / abs(reference) * 1_000_000
        case .percent:
            guard reference != 0 else {
                throw BioSwiftDiagnostics.logged(MassToleranceError.zeroReferenceMass)
            }
            convertedValue = radius / abs(reference) * 100
        }

        return try Self(convertedValue, unit: targetUnit)
    }
}

extension MassTolerance: Codable {
    private enum CodingKeys: String, CodingKey {
        case value
        case unit
    }

    public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let value = try container.decode(Decimal.self, forKey: .value)
            let unit = try container.decode(Unit.self, forKey: .unit)
            try self.init(value, unit: unit)
        } catch {
            throw BioSwiftDiagnostics.loggedDecodingFailure(error, from: decoder)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)
        try container.encode(unit, forKey: .unit)
    }
}

public enum MassToleranceError: Error, Equatable, Sendable {
    case invalidValue(Decimal)
    case zeroReferenceMass
    case zeroTheoreticalMass
}
