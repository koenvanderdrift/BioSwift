//
//  MassTests.swift
//  BioSwift
//

import Testing

@testable import BioSwift

@Suite struct MassTests {
    private let neutralMass = MassContainer(
        monoisotopicMass: decimal("100"),
        averageMass: decimal("100"),
        nominalMass: 100
    )

    @Test func singlyDeprotonatedMass() {
        let ion = neutralMass.applying(adducts: [negativeProtonAdduct])

        #expect(ion.monoisotopicMass.rounded(scale: 6) == decimal("98.992724"))
        #expect(ion.nominalMass == 99)
    }

    @Test func doublyDeprotonatedMassToChargeRatio() {
        let ion = neutralMass.applying(
            adducts: [negativeProtonAdduct, negativeProtonAdduct]
        )

        #expect(ion.monoisotopicMass.rounded(scale: 6) == decimal("48.992724"))
        #expect(ion.nominalMass == 49)
    }

    @Test func chlorideAdductMass() {
        let ion = neutralMass.applying(adducts: [chlorineAdduct])

        #expect(ion.monoisotopicMass.rounded(scale: 6) == decimal("134.969402"))
        #expect(ion.nominalMass == 135)
    }

    @Test func mixedProtonAndSodiumAdductMassToChargeRatio() {
        let ion = neutralMass.applying(adducts: [protonAdduct, sodiumAdduct])

        #expect(ion.monoisotopicMass.rounded(scale: 6) == decimal("61.998247"))
        #expect(ion.nominalMass == 62)
    }
}
