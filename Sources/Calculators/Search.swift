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

extension MassToleranceType {
    public var minValue: Double {
        return 0.0
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
    public var adducts: [Adduct]
    public var massType: MassType

    public init(searchValue: Double, tolerance: MassTolerance, searchType: SearchType, adducts: [Adduct], massType: MassType) {
        self.searchValue = searchValue
        self.tolerance = tolerance
        self.searchType = searchType
        self.adducts = adducts
        self.massType = massType
    }

    func massRange() -> ClosedRange<Dalton> {
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

extension BioSequence {
    public func searchSequence<T: RangedSequence>(searchString: String) -> [T] {
        var result = [T]()
        
        for nsrange in sequenceString.nsRanges(of: searchString) {
            if var sub: T = subSequence(with: nsrange) {
                sub.rangeInParent = nsrange.sequenceRange()
                result.append(sub)
            }
        }

        return result
    }
}

extension BioSequence where Self: Chargeable {
    public func searchMass<T: RangedSequence & Chargeable>(params: MassSearchParameters) -> [T] {
        var result = [T]()

        let massRange = params.massRange()
        let count = self.numberOfResidues()
        
        var start = 0
        
        // Nterm: 1102.3525
        // 807.9348
        // Cterm: 979.0476
        
        while start < count {
            for index in start...count {
                guard var sub: T = subSequence(from: start, to: index) else { break }
                sub.adducts = adducts
                sub.rangeInParent = start...index
                
                let chargedMass = sub.chargedMass()
                
                if chargedMass.averageMass > 1.05 * massRange.upperBound {
                    break
                }
                
                switch params.massType {
                case .monoisotopic:
                    if massRange.contains(chargedMass.monoisotopicMass) {
                        result.append(sub)
                    }
                case .average:
                    if massRange.contains(chargedMass.averageMass) {
                        result.append(sub)
                    }
                case .nominal:
                    if massRange.contains(Dalton(chargedMass.nominalMass)) {
                        result.append(sub)
                    }
                }
            }
            
            start += 1
        }

        return result
    }
}
