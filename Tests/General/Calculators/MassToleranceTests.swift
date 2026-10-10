//
//  MassToleranceTests.swift
//  BioSwift
//

import Foundation
import Testing

@testable import BioSwift

@Suite struct MassToleranceTests {
    @Test func rejectsInvalidValues() {
        #expect(throws: MassToleranceError.invalidValue(-1)) {
            try MassTolerance.ppm(-1)
        }
    }

    @Test func createsRangesForEveryUnit() throws {
        let cases: [(MassTolerance, Dalton, Dalton)] = [
            (try .ppm(10), decimal("99.999"), decimal("100.001")),
            (try .daltons(decimal("0.25")), decimal("99.75"), decimal("100.25")),
            (try .percent(decimal("0.5")), decimal("99.5"), decimal("100.5")),
            (try .mmu(250), decimal("99.75"), decimal("100.25")),
        ]

        for (tolerance, expectedLowerBound, expectedUpperBound) in cases {
            let range = tolerance.range(around: 100)
            #expect(range.lowerBound == expectedLowerBound)
            #expect(range.upperBound == expectedUpperBound)
        }
    }

    @Test func negativeReferenceProducesOrderedSymmetricRange() throws {
        let tolerance = try MassTolerance.ppm(10)
        let positive = tolerance.range(around: 1_000)
        let negative = tolerance.range(around: -1_000)

        #expect(negative.lowerBound == -positive.upperBound)
        #expect(negative.upperBound == -positive.lowerBound)
    }

    @Test func rangeBoundariesAreIncluded() throws {
        let tolerance = try MassTolerance.daltons(1)
        let range = tolerance.range(around: 100)

        #expect(tolerance.contains(range.lowerBound, relativeTo: 100))
        #expect(tolerance.contains(range.upperBound, relativeTo: 100))
        #expect(!tolerance.contains(decimal("98.999"), relativeTo: 100))
        #expect(!tolerance.contains(decimal("101.001"), relativeTo: 100))
    }

    @Test func convertsUnitsUsingReferenceMass() throws {
        let ppm = try MassTolerance.ppm(10)
        let daltons = try ppm.converted(to: .dalton, at: 1_000)
        let roundTrip = try daltons.converted(to: .ppm, at: 1_000)

        #expect(daltons.value == decimal("0.01"))
        #expect(roundTrip == ppm)
        #expect(throws: MassToleranceError.zeroReferenceMass) {
            try daltons.converted(to: .ppm, at: 0)
        }
    }

    @Test func structureOperationsUseRequestedMassType() throws {
        let peptide = try Peptide(sequence: "PEPTIDE")
        let tolerance = try MassTolerance.daltons(0)

        #expect(
            tolerance.range(around: peptide, massType: .monoisotopic)
                == tolerance.range(around: peptide.monoisotopicMass)
        )
        #expect(
            tolerance.contains(
                peptide,
                relativeTo: peptide.monoisotopicMass,
                massType: .monoisotopic
            )
        )
    }

    @Test func comparesDifferentStructureTypes() throws {
        let peptide = try Peptide(sequence: "PEPTIDE")
        let tolerance = try MassTolerance.daltons(10_000)

        #expect(
            tolerance.contains(
                water,
                relativeTo: peptide,
                massType: .monoisotopic
            )
        )
    }

    @Test func codableRoundTripPreservesValidatedTolerance() throws {
        let original = try MassTolerance.ppm(decimal("0.1000000000000000001"))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MassTolerance.self, from: data)

        #expect(decoded == original)
    }

    @Test func massErrorIsSignedAndWorksWithStructures() throws {
        let positive = MassError(observed: 1_000.01, theoretical: 1_000)
        let negative = MassError(observed: 999.99, theoretical: 1_000)
        let peptide = try Peptide(sequence: "PEPTIDE")
        let structureError = MassError(
            observed: water,
            theoretical: peptide,
            massType: .average
        )

        #expect(positive.daltons == decimal("0.01"))
        #expect(try positive.ppm() == 10)
        #expect(negative.daltons == decimal("-0.01"))
        #expect(try negative.ppm() == -10)
        #expect(structureError.observed == water.averageMass)
        #expect(structureError.theoretical == peptide.averageMass)
    }

    @Test func relativeMassErrorRejectsZeroTheoreticalMass() {
        let error = MassError(observed: 1, theoretical: 0)

        #expect(throws: MassToleranceError.zeroTheoreticalMass) {
            try error.ppm()
        }
        #expect(throws: MassToleranceError.zeroTheoreticalMass) {
            try error.percent()
        }
    }
}
