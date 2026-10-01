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

public enum MassTolerance: Codable, Equatable, Sendable {
    case ppm(Decimal)
    case dalton(Dalton)
    case percent(Decimal)
    case mmu(Decimal)
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
        let minMass: Dalton
        let maxMass: Dalton

        switch tolerance {
        case .ppm(let value):
            let delta = value / 1_000_000
            minMass = (1 - delta) * searchValue
            maxMass = (1 + delta) * searchValue

        case .dalton(let value):
            minMass = searchValue - value
            maxMass = searchValue + value

        case .percent(let value):
            minMass = searchValue - (value * searchValue) / 100
            maxMass = searchValue + (value * searchValue) / 100

        case .mmu(let value):
            minMass = searchValue - value / 1000
            maxMass = searchValue + value / 1000
        }

        return minMass...maxMass
    }
}
