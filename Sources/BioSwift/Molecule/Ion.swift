//
//  Ion.swift
//  BioSwift
//

import Foundation

/// A charged form of a neutral molecular structure.
public struct Ion<StructureType: Structure>: Structure {
    public let structure: StructureType
    public var adducts: [Adduct]

    public init(structure: StructureType, adducts: [Adduct]) throws {
        guard adducts.isEmpty == false else {
            throw BioSwiftDiagnostics.logged(IonError.noAdducts)
        }

        guard adducts.totalCharge != 0 else {
            throw BioSwiftDiagnostics.logged(IonError.zeroCharge)
        }

        self.structure = structure
        self.adducts = adducts
    }

    public var name: String {
        structure.name
    }

    /// The formula of the underlying neutral structure.
    public var formula: Formula {
        structure.formula
    }

    public var charge: Charge {
        adducts.totalCharge
    }

    public var masses: MassContainer {
        structure.masses.applying(adducts: adducts)
    }
}

extension Ion: Codable where StructureType: Codable {}
extension Ion: Equatable where StructureType: Equatable {}
extension Ion: Sendable where StructureType: Sendable {}

public enum IonError: Error, Equatable, Sendable {
    case noAdducts
    case zeroCharge
}

extension Ion {
    /// Returns the unique subsets of adducts matching this ion's charge sign that
    /// do not exceed the requested absolute charge.
    func adductCombinations(maximumAbsoluteCharge: Int) -> [[Adduct]] {
        let ionChargeSign = charge.signum()
        let matchingAdducts = adducts.filter { $0.charge.signum() == ionChargeSign }
        var result: [[Adduct]] = []

        func appendCombinations(startingAt index: Int, current: [Adduct], charge: Charge) {
            for adductIndex in index..<matchingAdducts.count {
                let adduct = matchingAdducts[adductIndex]
                let updatedCharge = charge + adduct.charge

                guard abs(updatedCharge) <= maximumAbsoluteCharge else { continue }

                let combination = current + [adduct]
                if !result.contains(combination) {
                    result.append(combination)
                }

                appendCombinations(
                    startingAt: adductIndex + 1,
                    current: combination,
                    charge: updatedCharge)
            }
        }

        appendCombinations(startingAt: 0, current: [], charge: 0)
        return result.sorted { abs($0.totalCharge) < abs($1.totalCharge) }
    }
}

extension Structure {
    public func ionized(with adducts: [Adduct]) throws -> Ion<Self> {
        try Ion(structure: self, adducts: adducts)
    }
}

extension Array where Element == Adduct {
    var totalCharge: Charge {
        reduce(0) { $0 + $1.charge }
    }
}
