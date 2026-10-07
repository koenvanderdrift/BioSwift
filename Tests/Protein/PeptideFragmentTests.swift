//
//  PeptideFragmentTests.swift
//  BioSwift
//

import Testing

@testable import BioSwift

@Suite struct PeptideFragmentTests {
    @Test func chargedResidues() throws {
        let fragment = try PeptideFragment(sequence: "AWRKQNWSTEDWWSHTEDWQPRTYSAMPLER")

        #expect(fragment.maximumChargeCount == 5)
    }

    @Test func fragmentComposesPeptideStorage() throws {
        let fragment = PeptideFragment(
            residues: try Peptide(sequence: "SAM").residues,
            fragmentType: .bIon,
            index: 3)

        #expect(fragment.sequenceString == "SAM")
        #expect(fragment.residues.count == 3)
        #expect(fragment.nTerminal == zeroModification)
        #expect(fragment.cTerminal == zeroModification)
    }

    @Test func allFragmentCases() {
        #expect(PeptideFragmentType.allCases.count == 17)
    }
}
