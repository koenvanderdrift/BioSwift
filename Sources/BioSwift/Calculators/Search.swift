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
        return 0.0
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

    func massRange() -> ClosedRange<Dalton> {
        var minMass = 0.0
        var maxMass = 0.0
        let toleranceValue = Double(tolerance.value)

        switch tolerance.type {
        case .ppm:
            let delta = toleranceValue / 1000000
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

        return Dalton(minMass)...Dalton(maxMass)
    }
}

public extension Chain {
    func searchSequence<T: RangedChain>(searchString: String) -> [T] {
        var result = [T]()

        for range in sequenceString.sequenceRanges(of: searchString) {
            if var sub: T = subChain(with: range) as? T {
                sub.rangeInParent = range
                result.append(sub)
            }
        }

        return result
    }
}

public extension Chain {
    func searchMass<T: RangedChain & ChargedMass>(params: MassSearchParameters) -> [T] {
        var result = [T]()

        let count = self.numberOfResidues()
       
        var start = 0
        var end = 0
        
        var masses: MassContainer = water.masses
        let massRange = params.massRange()

        while start < count {
            while end < count {
                guard let temp = self.residue(at: end)?.masses else { break }
                end += 1

                masses += temp

                if masses.averageMass > 1.05 * massRange.upperBound {
                    break
                }

                switch params.massType {
                case .monoisotopic:
                    if massRange.contains(masses.monoisotopicMass) {
                        guard var sub: T = subChain(from: start, to: end - 1) as? T else { break }

                        sub.adducts = adducts
                        sub.rangeInParent = start...end - 1
                        result.append(sub)
                        break
                    }
                case .average:
                    if massRange.contains(masses.averageMass) {
                        guard var sub: T = subChain(from: start, to: end - 1) as? T else { break }

                        sub.adducts = adducts
                        sub.rangeInParent = start...end - 1
                        result.append(sub)
                        break
                    }
                case .nominal:
                    if massRange.contains(Dalton(masses.nominalMass)) {
                        guard var sub: T = subChain(from: start, to: end - 1) as? T else { break }

                        sub.adducts = adducts
                        sub.rangeInParent = start...end - 1
                        result.append(sub)
                        break
                    }
                }
            }

            while start < end {
                guard let temp = self.residue(at: start)?.masses else { break }
                start += 1

                masses -= temp

                if masses.monoisotopicMass < 0.95 * massRange.lowerBound {
                    break
                }

                switch params.massType {
                case .monoisotopic:
                    if massRange.contains(masses.monoisotopicMass) {
                        guard var sub: T = subChain(from: start, to: end - 1) as? T else { break }

                        sub.adducts = adducts
                        sub.rangeInParent = start...end - 1
                        result.append(sub)
                        break
                    }
                case .average:
                    if massRange.contains(masses.averageMass) {
                        guard var sub: T = subChain(from: start, to: end - 1) as? T else { break }

                        sub.adducts = adducts
                        sub.rangeInParent = start...end - 1
                        result.append(sub)
                        break
                    }
                case .nominal:
                    if massRange.contains(Dalton(masses.nominalMass)) {
                        guard var sub: T = subChain(from: start, to: end - 1) as? T else { break }

                        sub.adducts = adducts
                        sub.rangeInParent = start...end - 1
                        result.append(sub)
                        break
                    }
                }
            }
        }

        return result
    }
}
