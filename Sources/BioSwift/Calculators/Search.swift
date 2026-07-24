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
    func searchMass(params: MassSearchParameters) -> [Range<Int>] where Self: Chargeable {
        // prefixValues[i] is the sum of items[0..<i].
        var prefixValues = Array(
            repeating: zeroMass,
            count: residues.count + 1)

        for index in residues.indices {
            prefixValues[index + 1] =
                prefixValues[index] + residues[index].masses
        }

        func massContainer(from start: Int, to end: Int) -> MassContainer {
            let itemSum = prefixValues[end] - prefixValues[start]

            return (water.masses + itemSum).moverz(for: params.charge)
        }

        let count = residues.count
        let acceptableRange = params.massRange

        var results: [Range<Int>] = []

        // First end whose value is not below the acceptable range.
        var firstAcceptableEnd = 1

        // First end whose value is above the acceptable range.
        var firstAboveEnd = 1

        for start in 0 ..< count {
            firstAcceptableEnd = max(firstAcceptableEnd, start + 1)

            while firstAcceptableEnd <= count {
                if !acceptableRange.isBelow(massContainer(from: start, to: firstAcceptableEnd), for: params.massType) {
                    break
                }

                firstAcceptableEnd += 1
            }

            // No range beginning here can reach the lower bound.
            // With nonnegative contributions, no later start can either.
            guard firstAcceptableEnd <= count else {
                break
            }

            firstAboveEnd = max(firstAboveEnd, firstAcceptableEnd)

            while firstAboveEnd <= count {
                if acceptableRange.isAbove(massContainer(from: start, to: firstAboveEnd), for: params.massType) {
                    break
                }

                firstAboveEnd += 1
            }

            // firstAboveEnd may be count + 1. That intentionally includes
            // a valid range whose exclusive upper bound is `count`.
            for end in firstAcceptableEnd ..< firstAboveEnd {
                results.append(start ..< end)
            }
        }

        return results
    }

    func searchMassBruteForce(params: MassSearchParameters) -> [Self] where Self: Chargeable {
        var result: [Self] = []

        for start in residues.indices {
            for end in (start + 1) ..< residues.count {
                let subRange = start ..< end
                var sub = subChain(range: subRange)

                sub.range = subRange
                sub.setAdducts(type: protonAdduct, count: params.charge)

                let moverz = sub.massOverCharge()

                if params.massRange.upperLimit(excludes: moverz) {
                    break
                }

                if params.massRange.contains(moverz, for: params.massType) {
                    if (start ..< end).isValidRange {
                        result.append(sub)
                    }
                }
            }
        }

        return result
    }

    private func subChain(with range: Range<Int>, for masses: MassContainer, in massRange: MassRange, and type: MassType) -> Self?
        where Self: Chargeable
    {
        if massRange.contains(masses, for: type) {
            var sub = subChain(range: range)

            sub.range = range

            return sub
        }

        return nil
    }
}
