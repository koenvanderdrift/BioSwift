//
//  MassSearch.swift
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

public enum ToleranceType: String {
    case ppm
    case dalton = "Da"
    case percent = "%"
    case mmu
}

extension ToleranceType {
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

public struct Tolerance {
    public var type: ToleranceType
    public var value: Double

    public init(type: ToleranceType, value: Double) {
        self.type = type
        self.value = value
    }
}

public struct SearchParameters {
    public var searchValue: Double
    public var tolerance: Tolerance
    public let searchType: SearchType
    public var adducts: [Adduct]
    public var massType: MassType

    public init(searchValue: Double, tolerance: Tolerance, searchType: SearchType, adducts: [Adduct], massType: MassType) {
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

public typealias SearchResult = Set<String>

public struct MassSearch <T:BioSequence & Chargeable> {
    public let sequence: T
    public let params: SearchParameters

    public init(sequence: T, params: SearchParameters) {
        self.sequence = sequence
        self.params = params
    }

    public func searchMass() -> SearchResult {
        var result = SearchResult()
        let range = params.massRange()
        let count = sequence.numberOfResidues()
        
        var start = 0
        
        // Nterm: 1102.3525
        // 807.9348
        // Cterm: 979.0476
        
        while start < count {
            for index in start+1...count {
                var sub: T = sequence.subSequence(from: start, to: index)
                sub.adducts = sequence.adducts
                
                let chargedMass = sub.chargedMass()
    
                if chargedMass.averageMass > 1.05 * range.upperBound {
                    break
                }
                
                switch params.massType {
                case .monoisotopic:
                    if range.contains(chargedMass.monoisotopicMass) {
                        result.insert(sub.sequenceString)
                    }
                case .average:
                    if range.contains(chargedMass.averageMass) {
                        result.insert(sub.sequenceString)
                    }
                case .nominal:
                    if range.contains(Dalton(chargedMass.nominalMass)) {
                        result.insert(sub.sequenceString)
                    }
                }
            }
            
            start += 1
        }

        return result
    }
}
