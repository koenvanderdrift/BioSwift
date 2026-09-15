//
//  PeptideFragmenterTests.swift
//  BioSwift
//

import Foundation
import Testing

@testable import BioSwift

@Suite struct PeptideFragmenterTests: BioSwiftTestSuite {
    var fixtures = BioSwiftTestFixtures()
    @Test func fragmentCount() {
        var peptide = Peptide(sequence: "SAMPLER")
        peptide.setAdducts(type: protonAdduct, count: 1)

        let fragmenter = PeptideFragmenter(peptide: peptide)
        let fragments = fragmenter.fragments

        let precursors = fragments.filter {
            $0.fragmentType == .precursorIon
        }
        #expect(precursors.count == 1)

        let immoniumIons = fragments.filter {
            $0.fragmentType == .immoniumIon
        }
        #expect(immoniumIons.count == 7)

        let bIons = fragments.filter {
            $0.fragmentType == .bIon
        }
        #expect(bIons.count == 5)

        let yIons = fragments.filter {
            $0.fragmentType == .yIon
        }
        #expect(yIons.count == 6)
    }

    @Test func fragmenterHandlesShortPeptides() {
        var emptyPeptide = Peptide(sequence: "")
        emptyPeptide.setAdducts(type: protonAdduct, count: 1)

        let emptyFragmenter = PeptideFragmenter(peptide: emptyPeptide)
        #expect(emptyFragmenter.fragments.filter {
            $0.isNterminal() || $0.isCterminal()
        }.isEmpty)
        #expect(emptyFragmenter.fragment(at: 1, for: .cIon) == nil)

        var singleResiduePeptide = Peptide(sequence: "A")
        singleResiduePeptide.setAdducts(type: protonAdduct, count: 1)

        let singleResidueFragmenter = PeptideFragmenter(peptide: singleResiduePeptide)
        #expect(singleResidueFragmenter.fragments.filter {
            $0.isCterminal()
        }.isEmpty)
        #expect(singleResidueFragmenter.fragment(at: 1, for: .cIon) != nil)
    }

    @Test func fragmentMass1() {
        // theoretical masses via https://prospector.ucsf.edu/prospector/cgi-bin/msform.cgi?form=msproduct

        var peptide = Peptide(sequence: "SAMPLER")
        peptide.setAdducts(type: protonAdduct, count: 1)

        #expect(peptide.monoisotopicMass.rounded(scale: 4) == decimal("803.4080"))
        #expect(peptide.monoisotopicMass.rounded(scale: 4) == decimal("803.4080"))

        let fragmenter = PeptideFragmenter(peptide: peptide)
        let fragments = fragmenter.fragments

        let precursors = fragments.filter {
            $0.isPrecursor()
        }
        #expect(precursors[0].monoisotopicMass.rounded(scale: 4) == decimal("803.4080"))
        #expect(precursors[1].monoisotopicMass.rounded(scale: 4) == decimal("785.3974"))
        #expect(precursors[2].monoisotopicMass.rounded(scale: 4) == decimal("786.3815"))

        if let a1 = fragmenter.fragment(at: 1, for: .aIon) {
            #expect(a1.monoisotopicMass.rounded(scale: 4) == decimal("131.0815"))  // a1
        }

        if let b2 = fragmenter.fragment(at: 2, for: .bIon) {
            #expect(b2.monoisotopicMass.rounded(scale: 4) == decimal("159.0764"))  // b2
        }

        if let b2minH2O = fragmenter.fragment(at: 2, for: .bIonMinusWater) {
            #expect(b2minH2O.monoisotopicMass.rounded(scale: 4) == decimal("141.0659"))  // b2-H2O
        }

        if let b3minH2O = fragmenter.fragment(at: 3, for: .bIonMinusWater) {
            #expect(b3minH2O.monoisotopicMass.rounded(scale: 4) == decimal("272.1063"))  // b3-H2O
        }

        if let x1 = fragmenter.fragment(at: 1, for: .xIon) {
            #expect(x1.monoisotopicMass.rounded(scale: 4) == decimal("201.0982"))  // x1
        }

        if let y1 = fragmenter.fragment(at: 1, for: .yIon) {
            #expect(y1.monoisotopicMass.rounded(scale: 4) == decimal("175.1190"))  // y1
        }

        if let y1minNH3 = fragmenter.fragment(at: 1, for: .yIonMinusAmmonia) {
            #expect(y1minNH3.monoisotopicMass.rounded(scale: 4) == decimal("158.0924"))  // y1-NH3
        }

        if let y2minH2O = fragmenter.fragment(at: 2, for: .yIonMinusWater) {
            #expect(y2minH2O.monoisotopicMass.rounded(scale: 4) == decimal("286.1510"))  // y2-H2O
        }
    }

    @Test func fragmentMass2() {
        var peptide = Peptide(sequence: "SAMPLEVAAAGQTHR")
        peptide.setAdducts(type: protonAdduct, count: 1)

        #expect(peptide.monoisotopicMass.rounded(scale: 4) == decimal("1538.7744"))

        let fragmenter = PeptideFragmenter(peptide: peptide)
        let fragments = fragmenter.fragments

        let bIons = fragments.filter {
            $0.fragmentType == .bIon
        }
        #expect(bIons.count == 13)

        if let b2 = fragmenter.fragment(at: 2, for: .bIon) {
            #expect(b2.monoisotopicMass.rounded(scale: 4) == decimal("159.0764"))  // b2
        }

        if let b12 = fragmenter.fragment(at: 12, for: .bIon) {
            #expect(b12.monoisotopicMass.rounded(scale: 4) == decimal("1126.5561"))  // b12
        }

        if let b12minH2O = fragmenter.fragment(at: 12, for: .bIonMinusWater) {
            #expect(b12minH2O.monoisotopicMass.rounded(scale: 4) == decimal("1108.5456"))  // b12 - H2O
        }

        if let b12minNH3 = fragmenter.fragment(at: 12, for: .bIonMinusAmmonia) {
            #expect(b12minNH3.monoisotopicMass.rounded(scale: 4) == decimal("1109.5296"))  // b12 - NH3
        }


        let zIons = fragments.filter {
            $0.fragmentType == .zIon
        }
        #expect(zIons.count == 13)

        let cIons = fragments.filter {
            $0.fragmentType == .cIon
        }
        #expect(cIons.count == 13)

        if let c1 = fragmenter.fragment(at: 1, for: .cIon) {
            #expect(c1.monoisotopicMass.rounded(scale: 4) == decimal("105.0659"))  // c1
        }
    }

    @Test func fragmentMass3() throws {
        for modification in try modifications(
            unimodName: "Oxidation", psiModAccession: "MOD:00719",
            uniProtPTMAccession: "PTM-0469") {
            var peptide = Peptide(sequence: "SAMPLEVAMAAGQTHR")
            peptide.setAdducts(type: protonAdduct, count: 1)
            peptide.addModification(modification, at: 8)
            #expect(peptide.monoisotopicMass.rounded(scale: 4) == decimal("1685.8098"))

            let fragmenter = PeptideFragmenter(peptide: peptide)
            let fragments = fragmenter.fragments

            let aIonsMinusWater = fragments.filter {
                $0.fragmentType == .aIonMinusWater
            }
            #expect(aIonsMinusWater.count == 14)

            let aIonsMinusAmmonia = fragments.filter {
                $0.fragmentType == .aIonMinusAmmonia
            }
            #expect(aIonsMinusAmmonia.count == 3)

            let bIons = fragments.filter {
                $0.fragmentType == .bIon
            }
            #expect(!bIons.contains(where: {
                $0.index == 1
            }))

            let yIons = fragments.filter {
                $0.fragmentType == .yIonMinusWater
            }
            #expect(!yIons.contains(where: {
                $0.index == 1
            }))
            #expect(!yIons.contains(where: {
                $0.index == 2
            }))

            if let b8 = fragmenter.fragment(at: 8, for: .bIon) {
                #expect(b8.monoisotopicMass.rounded(scale: 4) == decimal("799.4019"))  // b8 M-ox
            }

            if let y9 = fragmenter.fragment(at: 9, for: .yIon) {
                #expect(y9.monoisotopicMass.rounded(scale: 4) == decimal("958.4523"))  // y9 M-ox
            }

            if let x9 = fragmenter.fragment(at: 9, for: .xIon) {
                #expect(x9.monoisotopicMass.rounded(scale: 4) == decimal("984.4316"))  // x9 M-ox
            }

            let zIons = fragments.filter {
                $0.fragmentType == .zIon
            }
            #expect(!zIons.contains(where: {
                $0.index == 13
            }))

            if let z12 = fragmenter.fragment(at: 12, for: .zIon) {
                #expect(z12.monoisotopicMass.rounded(scale: 4) == decimal("1283.6287"))  // z12 M-ox
            }
        }
    }

    @Test func fragmentMass4() {
        var peptide = Peptide(sequence: "AWRKQNWSTEDWWSTEDWQPRTYSAMPLER")
        peptide.setAdducts(type: protonAdduct, count: 1)

        let fragmenter = PeptideFragmenter(peptide: peptide)
        let fragments = fragmenter.fragments

        let bIonsMinusWater = fragments.filter {
            $0.fragmentType == .bIonMinusWater
        }
        #expect(!bIonsMinusWater.contains(where: {
            $0.index == 1
        }))
        #expect(!bIonsMinusWater.contains(where: {
            $0.index == 2
        }))
        #expect(!bIonsMinusWater.contains(where: {
            $0.index == 3
        }))
        #expect(!bIonsMinusWater.contains(where: {
            $0.index == 4
        }))
        #expect(!bIonsMinusWater.contains(where: {
            $0.index == 5
        }))
        #expect(!bIonsMinusWater.contains(where: {
            $0.index == 6
        }))
        #expect(!bIonsMinusWater.contains(where: {
            $0.index == 7
        }))
        #expect(bIonsMinusWater.contains(where: {
            $0.index == 8
        }))

        if let b8MinusWater = fragmenter.fragment(at: 8, for: .bIonMinusWater) {
            #expect(b8MinusWater.monoisotopicMass.rounded(scale: 4) == decimal("1039.5221"))  // b8-H20
        }
    }

    @Test func fragmentMass5() {
        var peptide = Peptide(sequence: "SAMPLEVAAAGQTHR")
        peptide.setAdducts(type: protonAdduct, count: 2)

        #expect(peptide.monoisotopicMass.rounded(scale: 4) == decimal("769.8908"))

        let fragmenter = PeptideFragmenter(peptide: peptide)
        let fragments = fragmenter.fragments

        let bIons = fragments.filter {
            $0.fragmentType == .bIon
        }
        #expect(bIons.count == 14)

        if let b2 = fragmenter.fragment(at: 2, for: .bIon) {
            #expect(b2.monoisotopicMass.rounded(scale: 4) == decimal("159.0764"))  // b2
        }

        if let b12 = fragmenter.fragment(at: 12, for: .bIon) {
            #expect(b12.monoisotopicMass.rounded(scale: 4) == decimal("1126.5561"))  // b12
        }

        let bIonsMinusWater = fragments.filter {
            $0.fragmentType == .bIonMinusWater
        }
        #expect(bIonsMinusWater.count == 14)

        if let b12MinusWater = fragmenter.fragment(at: 12, for: .bIonMinusWater) {
            #expect(b12MinusWater.monoisotopicMass.rounded(scale: 4) == decimal("1108.5456"))  // b12 - H2O
        }

        if let b12MinusAmmonia = fragmenter.fragment(at: 12, for: .bIonMinusAmmonia) {
            #expect(b12MinusAmmonia.monoisotopicMass.rounded(scale: 4) == decimal("1109.5296"))  // b12 - NH3
        }

        let zIons = fragments.filter {
            $0.fragmentType == .zIon
        }
        #expect(zIons.count == 26)

        let cIons = fragments.filter {
            $0.fragmentType == .cIon
        }
        #expect(cIons.count == 14)

        if let c1 = fragmenter.fragment(at: 1, for: .cIon) {
            #expect(c1.monoisotopicMass.rounded(scale: 4) == decimal("105.0659"))  // c1
        }
    }

    @Test func chargedResidues() {
        let fragment = PeptideFragment(sequence: "AWRKQNWSTEDWWSHTEDWQPRTYSAMPLER")

        let numOfCharges = fragment.maxNumberOfCharges()
        #expect(numOfCharges == 5)
    }

    @Test func allFragmentCases() {
        let allCases = PeptideFragmentType.allCases
        #expect(allCases.count == 17)
    }

}
