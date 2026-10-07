//
//  IonAdductCombinationTests.swift
//  BioSwift
//

import Testing

@testable import BioSwift

@Suite struct IonAdductCombinationTests {
    @Test func positiveCombinationsPreserveCompositionAndChargeLimit() throws {
        let ion = try water.ionized(with: [protonAdduct, sodiumAdduct, negativeProtonAdduct])
        let combinations = ion.adductCombinations(maximumAbsoluteCharge: 2)

        #expect(combinations.count == 3)
        #expect(combinations.contains([protonAdduct]))
        #expect(combinations.contains([sodiumAdduct]))
        #expect(combinations.contains([protonAdduct, sodiumAdduct]))
        #expect(combinations.allSatisfy { $0.totalCharge > 0 })
    }

    @Test func duplicateCombinationsAreGeneratedOnce() throws {
        let ion = try water.ionized(with: [protonAdduct, protonAdduct, protonAdduct])

        #expect(ion.adductCombinations(maximumAbsoluteCharge: 2) == [
            [protonAdduct],
            [protonAdduct, protonAdduct],
        ])
    }

    @Test func mixedPositiveCombinationsRemainDistinct() throws {
        let ion = try water.ionized(with: [
            protonAdduct,
            protonAdduct,
            sodiumAdduct,
            sodiumAdduct,
        ])
        let combinations = ion.adductCombinations(maximumAbsoluteCharge: 2)

        #expect(combinations.count == 5)
        #expect(combinations.contains([protonAdduct, protonAdduct]))
        #expect(combinations.contains([protonAdduct, sodiumAdduct]))
        #expect(combinations.contains([sodiumAdduct, sodiumAdduct]))
    }

    @Test func negativeCombinationsAreOrderedByAbsoluteCharge() throws {
        let ion = try water.ionized(with: [
            negativeProtonAdduct,
            negativeProtonAdduct,
            protonAdduct,
        ])

        #expect(ion.adductCombinations(maximumAbsoluteCharge: 2) == [
            [negativeProtonAdduct],
            [negativeProtonAdduct, negativeProtonAdduct],
        ])
    }
}
