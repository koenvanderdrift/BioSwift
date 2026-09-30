//
//  ExtinctionCoefficient.swift
//  BioSwift
//
//  Copyright © 2026 Koen van der Drift. All rights reserved.
//

import Foundation

/// Calculates protein absorbance properties at 280 nm.
///
/// The molar extinction coefficient is calculated as:
/// `ε = (nW × 5500) + (nY × 1490) + (disulfideCount × 125)`.
public enum ExtinctionCoefficientCalculator {
    public static func molarExtinctionCoefficient(
        for aminoAcids: [AminoAcid],
        disulfideCount: Int = 0
    ) -> Double {
        precondition(disulfideCount >= 0, "Disulfide count cannot be negative")

        let aromaticContribution = aminoAcids.reduce(into: 0.0) { coefficient, aminoAcid in
            switch aminoAcid.oneLetterCode {
            case "W":
                coefficient += 5_500
            case "Y":
                coefficient += 1_490
            default:
                break
            }
        }

        return aromaticContribution + Double(disulfideCount) * 125
    }

    /// Returns the extinction coefficient for a 1% (10 mg/mL) solution.
    public static func percentExtinctionCoefficient(
        molarExtinctionCoefficient: Double,
        massContainer: MassContainer
    ) -> Double? {
        guard molarExtinctionCoefficient >= 0, massContainer.averageMass > 0 else {
            return nil
        }

        let molecularWeight = NSDecimalNumber(decimal: massContainer.averageMass).doubleValue
        return molarExtinctionCoefficient * 10 / molecularWeight
    }

    /// Returns molar concentration in mol/L using Beer-Lambert's law.
    public static func molarConcentration(
        absorbance: Double,
        molarExtinctionCoefficient: Double,
        pathLength: Double = 1
    ) -> Double? {
        guard absorbance >= 0, molarExtinctionCoefficient > 0, pathLength > 0 else {
            return nil
        }

        return absorbance / (molarExtinctionCoefficient * pathLength)
    }

    /// Returns protein concentration in mg/mL.
    public static func massConcentration(
        absorbance: Double,
        molarExtinctionCoefficient: Double,
        massContainer: MassContainer,
        pathLength: Double = 1
    ) -> Double? {
        guard absorbance >= 0, molarExtinctionCoefficient > 0,
              massContainer.averageMass > 0, pathLength > 0
        else {
            return nil
        }

        let molecularWeight = NSDecimalNumber(decimal: massContainer.averageMass).doubleValue
        return absorbance * molecularWeight / (molarExtinctionCoefficient * pathLength)
    }
}

extension AminoAcidChain {
    /// The molar extinction coefficient at 280 nm in M⁻¹ cm⁻¹, assuming no disulfide bonds.
    public var molarExtinctionCoefficient: Double {
        molarExtinctionCoefficient(disulfideCount: 0)
    }

    /// Returns the molar extinction coefficient at 280 nm in M⁻¹ cm⁻¹.
    public func molarExtinctionCoefficient(disulfideCount: Int) -> Double {
        ExtinctionCoefficientCalculator.molarExtinctionCoefficient(
            for: residues,
            disulfideCount: disulfideCount
        )
    }

    /// The extinction coefficient for a 1% (10 mg/mL) solution at 280 nm.
    public var percentExtinctionCoefficient: Double? {
        ExtinctionCoefficientCalculator.percentExtinctionCoefficient(
            molarExtinctionCoefficient: molarExtinctionCoefficient,
            massContainer: masses
        )
    }

    /// Calculates concentration in mg/mL from absorbance at 280 nm.
    public func massConcentration(absorbance: Double, pathLength: Double = 1) -> Double? {
        ExtinctionCoefficientCalculator.massConcentration(
            absorbance: absorbance,
            molarExtinctionCoefficient: molarExtinctionCoefficient,
            massContainer: masses,
            pathLength: pathLength
        )
    }
}

extension BioMolecule where ChainType.ResidueType == AminoAcid {
    /// The combined molar extinction coefficient at 280 nm in M⁻¹ cm⁻¹, assuming no disulfide bonds.
    public var molarExtinctionCoefficient: Double {
        molarExtinctionCoefficient(disulfideCount: 0)
    }

    /// Returns the combined molar extinction coefficient at 280 nm in M⁻¹ cm⁻¹.
    public func molarExtinctionCoefficient(disulfideCount: Int) -> Double {
        ExtinctionCoefficientCalculator.molarExtinctionCoefficient(
            for: chains.flatMap(\.residues),
            disulfideCount: disulfideCount
        )
    }

    /// The extinction coefficient for a 1% (10 mg/mL) solution at 280 nm.
    public var percentExtinctionCoefficient: Double? {
        ExtinctionCoefficientCalculator.percentExtinctionCoefficient(
            molarExtinctionCoefficient: molarExtinctionCoefficient,
            massContainer: masses
        )
    }

    /// Calculates concentration in mg/mL from absorbance at 280 nm.
    public func massConcentration(absorbance: Double, pathLength: Double = 1) -> Double? {
        ExtinctionCoefficientCalculator.massConcentration(
            absorbance: absorbance,
            molarExtinctionCoefficient: molarExtinctionCoefficient,
            massContainer: masses,
            pathLength: pathLength
        )
    }
}
