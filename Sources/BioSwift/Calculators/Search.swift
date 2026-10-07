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

extension MassTolerance {
    public enum Unit: String, CaseIterable, Codable, Identifiable, Sendable {
        case ppm
        case dalton = "Da"
        case percent = "%"
        case mmu

        public var id: Self {
            self
        }
    }

    public var value: Decimal {
        get {
            switch self {
            case .ppm(let value), .dalton(let value), .percent(let value), .mmu(let value):
                value
            }
        }
        set {
            switch self {
            case .ppm:
                self = .ppm(newValue)
            case .dalton:
                self = .dalton(newValue)
            case .percent:
                self = .percent(newValue)
            case .mmu:
                self = .mmu(newValue)
            }
        }
    }

    public var unit: Unit {
        get {
            switch self {
            case .ppm:
                .ppm
            case .dalton:
                .dalton
            case .percent:
                .percent
            case .mmu:
                .mmu
            }
        }
        set {
            switch newValue {
            case .ppm:
                self = .ppm(value)
            case .dalton:
                self = .dalton(value)
            case .percent:
                self = .percent(value)
            case .mmu:
                self = .mmu(value)
            }
        }
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
