//
//  MassError.swift
//  BioSwift
//
//  Copyright © 2026 Koen van der Drift. All rights reserved.
//

import Foundation

/// The signed difference between an observed mass and a theoretical mass.
public struct MassError: Codable, Equatable, Sendable {
    public let observed: Dalton
    public let theoretical: Dalton
    public let massType: MassType

    public init(
        observed: Dalton,
        theoretical: Dalton,
        massType: MassType = .monoisotopic
    ) {
        self.observed = observed
        self.theoretical = theoretical
        self.massType = massType
    }

    public init(
        observed: any Structure,
        theoretical: any Structure,
        massType: MassType = .monoisotopic
    ) {
        self.init(
            observed: observed.mass(for: massType),
            theoretical: theoretical.mass(for: massType),
            massType: massType
        )
    }

    public init(
        observed: any Structure,
        theoretical: Dalton,
        massType: MassType = .monoisotopic
    ) {
        self.init(
            observed: observed.mass(for: massType),
            theoretical: theoretical,
            massType: massType
        )
    }

    public init(
        observed: Dalton,
        theoretical: any Structure,
        massType: MassType = .monoisotopic
    ) {
        self.init(
            observed: observed,
            theoretical: theoretical.mass(for: massType),
            massType: massType
        )
    }

    public var daltons: Dalton {
        observed - theoretical
    }

    public var absoluteDaltons: Dalton {
        abs(daltons)
    }

    public var mmu: Decimal {
        daltons * 1_000
    }

    public var absoluteMMU: Decimal {
        abs(mmu)
    }

    public func ppm() throws -> Decimal {
        guard theoretical != 0 else {
            throw BioSwiftDiagnostics.logged(MassToleranceError.zeroTheoreticalMass)
        }

        return daltons / abs(theoretical) * 1_000_000
    }

    public func percent() throws -> Decimal {
        guard theoretical != 0 else {
            throw BioSwiftDiagnostics.logged(MassToleranceError.zeroTheoreticalMass)
        }

        return daltons / abs(theoretical) * 100
    }

    public func isWithin(_ tolerance: MassTolerance) -> Bool {
        tolerance.contains(observed, relativeTo: theoretical)
    }
}
