//
//  Searchable.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/12/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public enum SearchType: Int {
    case sequential
    case unique
    case exhaustive
}

public enum ToleranceType: String {
    case ppm
    case mDa
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
    public let sequenceType: SequenceType

    public init(searchValue: Double, tolerance: Tolerance, searchType: SearchType, charge: Int, massType: MassType, sequenceType: SequenceType) {
        self.searchValue = searchValue
        self.tolerance = tolerance
        self.searchType = searchType
        self.charge = charge
        self.massType = massType
        self.sequenceType = sequenceType
    }
}

public typealias SearchResult = Set<String>

protocol Searchable {
    var sequenceString: String { get }
    var symbolSequence: [BioSymbol] { get }
}

extension Searchable {
    public func searchMasses(params: SearchParameters) -> SearchResult? {
        var symbols = symbolSequence
        var result = SearchResult()

        let range = massRange(params: params)
        var start = 0

        while !symbols.isEmpty {
            var mass = water.masses

            symbols.enumerated().forEach { index, symbol in
                if let symbol = symbol as? Mass {
                    mass += symbol.masses

                    let s = String(sequenceString.substring(from: start, to: start + index) ?? "")

                    switch params.massType {
                    case .monoisotopic:
                        if range ~= mass.monoisotopicMass {
                            result.insert(s)
                        }

                    case .average:
                        if range ~= mass.averageMass {
                            result.insert(s)
                        }

                    case .nominal:
                        if range ~= mass.nominalMass {
                            result.insert(s)
                        }
                    }
                }
            }

            symbols.removeFirst()
            start += 1
        }

        return result
    }

    //    func searchSequences(params: SearchParameters) -> SearchResult {}

    private func massRange(params: SearchParameters) -> ClosedRange<Double> {
        var minMass = 0.0
        var maxMass = 0.0
        let toleranceValue = Double(params.tolerance.value)

        switch params.tolerance.type {
        case .ppm:
            let delta = toleranceValue / 1_000_000
            minMass = (1 - delta) * params.searchValue
            maxMass = (1 + delta) * params.searchValue
        case .mDa:
            minMass = params.searchValue - toleranceValue / 1000
            maxMass = params.searchValue + toleranceValue / 1000
        }

        return minMass ... maxMass
    }
}
