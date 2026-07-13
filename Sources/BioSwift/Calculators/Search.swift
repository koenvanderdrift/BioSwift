//
//  Search.swift
//  BioSwift
//
//  Created by Koen van der Drift on 4/28/18.
//  Copyright © 2018 - 2025 Koen van der Drift. All rights reserved.
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

public extension MassToleranceType {
    var minValue: Double {
        0.0
    }

    var maxValue: Double {
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

    public init(searchValue: Dalton, tolerance: MassTolerance, searchType: SearchType, massType: MassType, charge: Int) {
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

        return minMass ... maxMass
    }
}

public extension Chain {
    func searchSequence(searchString: String) -> [Self] {
        var result: [Self] = []
        for range in sequenceString.sequenceRanges(of: searchString) {
            var sub = subChain(range: range)
            sub.range = range

            result.append(sub)
        }

        return result
    }
}

public extension Chain {
    func searchMass(params: MassSearchParameters) -> [Self] where Self: Chargeable {
        var result: [Self] = []

        let ranges = searchMass(using: params)
        
        for range in ranges {
            let sub = subChain(range: range)
            result.append(sub)
        }
        
        return result
    }
    
    func searchMass(using params: MassSearchParameters) -> [Range<Int>] {
        var matchingRanges: [Range<Int>] = []
        let massRange = params.massRange
        
        for startIndex in residues.indices {
            var summedMasses: MassContainer = water.masses

            for endIndex in startIndex..<residues.count {
                summedMasses += residues[endIndex].masses
                
                if massRange.upperLimit(excludes: summedMasses) {
                    break
                }
                
                if massRange.contains(summedMasses, for: params.massType) {
                    let range = startIndex ..< (endIndex + 1)
                    
                    if range.isValidRange {
                        matchingRanges.append(range)
                    }
                }
            }
        }
        
        return matchingRanges
    }

    private func subChain(with range: Range<Int>, for masses: MassContainer, in massRange: MassRange, and type: MassType) -> Self? where Self: Chargeable {
        if massRange.contains(masses, for: type) {
            var sub = subChain(range: range)

            sub.range = range

            return sub
        }

        return nil
    }
}
