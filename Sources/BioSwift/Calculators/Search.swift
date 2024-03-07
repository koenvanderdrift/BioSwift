//
//  Search.swift
//  BioSwift
//
//  Created by Koen van der Drift on 4/28/18.
//  Copyright © 2018 Koen van der Drift. All rights reserved.
//

import Foundation

public enum SearchType: Int {
    case sequential
    case unique
    case exhaustive
}

public enum MassToleranceType: String {
    case ppm
    case dalton = "Da"
    case percent = "%"
    case mmu
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

public struct MassTolerance {
    public var type: MassToleranceType
    public var value: Double

    public init(type: MassToleranceType, value: Double) {
        self.type = type
        self.value = value
    }
}

public struct MassSearchParameters {
    public var searchValue: Double
    public var tolerance: MassTolerance
    public let searchType: SearchType
    public var massType: MassType

    public init(searchValue: Double, tolerance: MassTolerance, searchType: SearchType, massType: MassType) {
        self.searchValue = searchValue
        self.tolerance = tolerance
        self.searchType = searchType
        self.massType = massType
    }

    public var massRange: MassRange {
        var minMass = 0.0
        var maxMass = 0.0
        let toleranceValue = Double(tolerance.value)

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

        return Dalton(minMass) ... Dalton(maxMass)
    }
}

public extension Chain {
    func searchSequence(searchString: String) -> [Self] {
        var result: [Self] = []
        for range in sequenceString.sequenceRanges(of: searchString) {
            if var sub = subChain(with: range) {
                sub.rangeInParent = range

                result.append(sub)
            }
        }

        return result
    }
}

public extension Chain {
    func searchMass(params: MassSearchParameters) -> [Self] where Self: ChargedMass {
        var result: [Self] = []

        let count = numberOfResidues
        let massRange = params.massRange

        var start = 0
        var end = 0

        var masses: MassContainer = water.masses

        while start < count {
            while end < count {
                guard let temp = residue(at: end)?.masses else { break }
                end += 1

                masses += temp

                if massRange.upperLimit(excludes: masses) {
                    break
                }

                if end > start, let sub = subChain(with: start ... (end - 1), for: masses, in: massRange) {
                    result.append(sub)
                    break
                }
            }

            while start < end {
                guard let temp = residue(at: start)?.masses else { break }
                start += 1

                masses -= temp

                if massRange.lowerLimit(excludes: masses) {
                    break
                }

                if end > start, let sub = subChain(with: start ... (end - 1), for: masses, in: massRange) {
                    result.append(sub)
                    break
                }
            }
        }

        return result
    }

    private func subChain(with chainRange: ChainRange, for masses: MassContainer, in massRange: MassRange) -> Self? where Self: ChargedMass {
        if massRange.contains(masses), var sub = subChain(with: chainRange) {
            sub.rangeInParent = chainRange

            return sub
        }

        return nil
    }
}
