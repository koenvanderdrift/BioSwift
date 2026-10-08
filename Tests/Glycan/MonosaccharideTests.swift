//
//  MonosaccharideTests.swift
//  BioSwift
//

import Foundation
import Testing

@testable import BioSwift

@Suite struct MonosaccharideTests {
    @Test func commonAldohexosesShareAFormulaButRemainDistinct() {
        let aldohexoses: Set<Monosaccharide> = [.glucose, .galactose, .mannose]

        #expect(aldohexoses.count == 3)
        #expect(aldohexoses.allSatisfy { $0.formula.formulaString == "C6H12O6" })
        #expect(aldohexoses.allSatisfy { $0.type == .hexose })
        #expect(aldohexoses.allSatisfy { $0.carbonylType == .aldose })
    }

    @Test func commonDefinitionsHaveExpectedClassifications() {
        #expect(Monosaccharide.fructose.carbonylType == .ketose)
        #expect(Monosaccharide.ribose.type == .pentose)
        #expect(Monosaccharide.deoxyribose.formula.formulaString == "C5H10O4")
        #expect(Monosaccharide.fucose.configuration == .l)
        #expect(Monosaccharide.nAcetylglucosamine.abbreviation == "GlcNAc")
        #expect(Monosaccharide.nAcetylneuraminicAcid.type == .nonose)
    }

    @Test func structureProvidesCalculatedProperties() {
        #expect(Monosaccharide.glucose.formulaString == "C6H12O6")
        #expect(
            Monosaccharide.glucose.monoisotopicMass.rounded(scale: 6)
                == decimal("180.063388")
        )
        #expect(Monosaccharide.glucose.nominalMass == 180)

        #expect(
            Monosaccharide.nAcetylglucosamine.monoisotopicMass.rounded(scale: 6)
                == decimal("221.089937")
        )
        #expect(Monosaccharide.nAcetylglucosamine.nominalMass == 221)

        #expect(
            Monosaccharide.nAcetylneuraminicAcid.monoisotopicMass.rounded(scale: 6)
                == decimal("309.105981")
        )
        #expect(Monosaccharide.nAcetylneuraminicAcid.nominalMass == 309)
    }

    @Test func codableRoundTripPreservesIdentity() throws {
        let encoded = try JSONEncoder().encode(Monosaccharide.galactose)
        let decoded = try JSONDecoder().decode(Monosaccharide.self, from: encoded)

        #expect(decoded == .galactose)
        #expect(decoded != .glucose)
    }

    @Test func descriptionIncludesConfiguredCyclicForm() {
        let alphaGlucopyranose = Monosaccharide.glucose.form(
            anomer: .alpha,
            ring: .pyranose
        )
        let betaRibofuranose = Monosaccharide.ribose.form(
            anomer: .beta,
            ring: .furanose
        )

        #expect(Monosaccharide.glucose.description == "D-Glucose")
        #expect(alphaGlucopyranose.description == "α-D-Glucopyranose")
        #expect(betaRibofuranose.description == "β-D-Ribofuranose")
        #expect(alphaGlucopyranose != .glucose)
    }
}
