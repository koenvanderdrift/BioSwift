//
//  Search.swift
//  BioSwift
//
//  Created by Koen van der Drift on 4/28/18.
//  Copyright © 2018 - 2026 Koen van der Drift. All rights reserved.
//

import Foundation

public enum SearchType: Int, Codable, Identifiable, Equatable, Sendable {
    case sequential
    case unique
    case exhaustive

    public var id: Self {
        self
    }
}

public enum MassToleranceType: String, CaseIterable, Codable, Identifiable, Equatable, Sendable {
    case ppm
    case dalton = "Da"
    case percent = "%"
    case mmu

    public var id: Self {
        self
    }
}

extension MassToleranceType {
    public var minValue: Double {
        0.0
    }

    public var maxValue: Double {
        switch self {
        case .ppm:
            return 10000.0

        case .dalton:
            return 10.0

        case .percent:
            return 1.0

        case .mmu:
            return 10000.0
        }
    }
}

public struct MassTolerance: Codable, Equatable, Sendable {
    public var type: MassToleranceType
    public var value: Double

    public init(type: MassToleranceType, value: Double) {
        self.type = type
        self.value = value
    }
}

public struct MassSearchParameters: Codable, Equatable, Sendable {
    public var searchValue: Dalton
    public var tolerance: MassTolerance
    public let searchType: SearchType
    public var massType: MassType
    public var charge: Int

    public init(
        searchValue: Dalton, tolerance: MassTolerance, searchType: SearchType, massType: MassType,
        charge: Int
    ) {
        self.searchValue = searchValue
        self.tolerance = tolerance
        self.searchType = searchType
        self.massType = massType
        self.charge = charge
    }

    public var massRange: MassRange {
        var minMass = Dalton(0.0)
        var maxMass = Dalton(0.0)
        let toleranceValue = Dalton(tolerance.value)

        switch tolerance.type {
        case .ppm:
            let delta = toleranceValue / 1_000_000
            minMass = (1 - delta) * searchValue
            maxMass = (1 + delta) * searchValue

        case .dalton:
            minMass = searchValue - toleranceValue
            maxMass = searchValue + toleranceValue

        case .percent:
            minMass = searchValue - (toleranceValue * searchValue) / 100
            maxMass = searchValue + (toleranceValue * searchValue) / 100

        case .mmu:
            minMass = searchValue - toleranceValue / 1000
            maxMass = searchValue + toleranceValue / 1000
        }

        return minMass...maxMass
    }
}
