//
//  ExtinctionCoefficientTests.swift
//  BioSwift
//
//  Copyright © 2026 Koen van der Drift. All rights reserved.
//

import Testing

@testable import BioSwift

struct ExtinctionCoefficientTests {
    @Test func calculatesWeightedMolarCoefficient() throws {
        let peptide = try Peptide(sequence: "WWYYCCC")

        #expect(peptide.molarExtinctionCoefficient == 13_980)
        #expect(peptide.molarExtinctionCoefficient(disulfideCount: 1) == 14_105)
    }

    @Test func usesExplicitDisulfideCountForP01009Composition() throws {
        let peptide = try Peptide(sequence: "WWWYYYYYYCCC")

        #expect(peptide.molarExtinctionCoefficient == 25_440)
        #expect(peptide.molarExtinctionCoefficient(disulfideCount: 1) == 25_565)
    }

    @Test func combinesAllProteinChains() throws {
        let protein = try Protein(sequences: ["WY", "CC"])

        #expect(protein.molarExtinctionCoefficient == 6_990)
        #expect(protein.molarExtinctionCoefficient(disulfideCount: 1) == 7_115)
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

    @Test func rejectsUndefinedCalculations() throws {
        #expect(
            ExtinctionCoefficientCalculator.molarConcentration(
                absorbance: 1,
                molarExtinctionCoefficient: 0
            ) == nil
        )
        #expect(try Peptide(sequence: "AAAA").massConcentration(absorbance: 1) == nil)
    }
}
