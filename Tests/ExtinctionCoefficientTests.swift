//
//  ExtinctionCoefficientTests.swift
//  BioSwift
//
//  Copyright © 2026 Koen van der Drift. All rights reserved.
//

import Testing

@testable import BioSwift

struct ExtinctionCoefficientTests {
    @Test func calculatesWeightedMolarCoefficient() {
        let peptide = Peptide(sequence: "WWYYCCC")

        #expect(peptide.molarExtinctionCoefficient == 14_355)
    }

    @Test func combinesAllProteinChains() {
        let protein = Protein(sequences: ["WY", "CC"])

        #expect(protein.molarExtinctionCoefficient == 7_240)
    }

    @Test func calculatesConcentrationsUsingBeerLambertLaw() throws {
        let molarConcentration = try #require(
            ExtinctionCoefficientCalculator.molarConcentration(
                absorbance: 0.5,
                molarExtinctionCoefficient: 10_000,
                pathLength: 0.5
            )
        )
        let massConcentration = try #require(
            ExtinctionCoefficientCalculator.massConcentration(
                absorbance: 1.4,
                molarExtinctionCoefficient: 210_000,
                massContainer: MassContainer(averageMass: 150_000)
            )
        )

        #expect(molarConcentration == 0.0001)
        #expect(abs(massConcentration - 1.0) < 0.000_000_1)
    }

    @Test func rejectsUndefinedCalculations() {
        #expect(
            ExtinctionCoefficientCalculator.molarConcentration(
                absorbance: 1,
                molarExtinctionCoefficient: 0
            ) == nil
        )
        #expect(Peptide(sequence: "AAAA").massConcentration(absorbance: 1) == nil)
    }
}
