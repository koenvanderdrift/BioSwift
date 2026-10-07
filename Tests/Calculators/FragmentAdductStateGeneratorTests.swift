//
//  FragmentAdductStateGeneratorTests.swift
//  BioSwift
//

import Testing

@testable import BioSwift

@Suite struct FragmentAdductStateGeneratorTests {
    @Test func positiveStatesPreserveCompositionAndChargeLimit() {
        let states = FragmentAdductStateGenerator(
            adducts: [protonAdduct, sodiumAdduct, negativeProtonAdduct],
            polarity: .positive,
            maximumAbsoluteCharge: 2
        ).states()

        #expect(states.count == 3)
        #expect(states.contains([protonAdduct]))
        #expect(states.contains([sodiumAdduct]))
        #expect(states.contains([protonAdduct, sodiumAdduct]))
        #expect(states.allSatisfy { state in
            state.reduce(0) { $0 + $1.charge } > 0
        })
    }

    @Test func duplicateAdductStatesAreGeneratedOnce() {
        let states = FragmentAdductStateGenerator(
            adducts: [protonAdduct, protonAdduct, protonAdduct],
            polarity: .positive,
            maximumAbsoluteCharge: 2
        ).states()

        #expect(states == [
            [protonAdduct],
            [protonAdduct, protonAdduct],
        ])
    }

    @Test func mixedPositiveAdductStatesRemainDistinct() {
        let states = FragmentAdductStateGenerator(
            adducts: [protonAdduct, protonAdduct, sodiumAdduct, sodiumAdduct],
            polarity: .positive,
            maximumAbsoluteCharge: 2
        ).states()

        #expect(states.count == 5)
        #expect(states.contains([protonAdduct, protonAdduct]))
        #expect(states.contains([protonAdduct, sodiumAdduct]))
        #expect(states.contains([sodiumAdduct, sodiumAdduct]))
    }

    @Test func negativeStatesAreOrderedByAbsoluteCharge() {
        let states = FragmentAdductStateGenerator(
            adducts: [negativeProtonAdduct, negativeProtonAdduct, protonAdduct],
            polarity: .negative,
            maximumAbsoluteCharge: 2
        ).states()

        #expect(states == [
            [negativeProtonAdduct],
            [negativeProtonAdduct, negativeProtonAdduct],
        ])
    }
}
