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
        tolerance.range(around: searchValue)
    }
}
