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
    case ppm = "ppm"
    case dalton = "Da"
    case percent = "%"
    case mmu = "mmu"
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
    public var charge: Int
    public var massType: MassType
    
    public init(searchValue: Double, tolerance: Tolerance, searchType: SearchType, charge: Int, massType: MassType) {
        self.searchValue = searchValue
        self.tolerance = tolerance
        self.searchType = searchType
        self.charge = charge
        self.massType = massType
    }
    
    func massRange() -> ClosedRange<Decimal> {
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
            minMass = searchValue - ((toleranceValue * searchValue) / 100)
            maxMass = searchValue + ((toleranceValue * searchValue) / 100)

        case .mmu: //millimass units (that's units of .001 of a Dalton)
            minMass = searchValue - toleranceValue / 1000
            maxMass = searchValue + toleranceValue / 1000
        }
        
        return Decimal(minMass) ... Decimal(maxMass)
    }
}

public typealias SearchResult = Set<String>

public struct MassSearch {
    public let sequence: BioSequence
    public let params: SearchParameters
    
    public init(sequence: BioSequence, params: SearchParameters) {
        self.sequence = sequence
        self.params = params
    }
    
    public func searchMass() -> SearchResult {
        var result = SearchResult()
        
        let sequenceString = sequence.sequenceString
        var massSequence = sequence.residueSequence.map { $0.masses }
        
        let termini = sequence.termini
        
        let range = params.massRange()
        var start = 0
        
        // Nterm: 1102.3525
        // 807.9348
        // Cterm: 979.0476
        
        while !massSequence.isEmpty {
            var mass = hydrogen.masses + hydroxyl.masses
            
            if massSequence.count == sequenceString.count, let term = termini?.0 {
                mass += (term.masses - hydrogen.masses)
            }

            for index in 0...massSequence.count {
                let to = start + index + 1

                if let s = sequenceString.substring(from: start, to: to) {
                    mass += massSequence[index]

                    if to == sequenceString.count, let term = termini?.1 {
                        mass += (term.masses - hydroxyl.masses)
                    }
                    
                    let chargedMass = params.charge > 0 ? mass / params.charge : mass
                    
                    if chargedMass.averageMass > range.upperBound {
                        break
                    }
                    
                    switch params.massType {
                    case .monoisotopic:
                        if range.contains(chargedMass.monoisotopicMass) {
                            result.insert(String(s))
                        }
                    case .average:
                        if range.contains(chargedMass.averageMass) {
                            result.insert(String(s))
                        }
                    case .nominal:
                        if range.contains(Decimal(chargedMass.nominalMass)) {
                            result.insert(String(s))
                        }
                    }
                }
            }
            
            massSequence.removeFirst()
            start += 1
        }
        
        return result
    }
}
