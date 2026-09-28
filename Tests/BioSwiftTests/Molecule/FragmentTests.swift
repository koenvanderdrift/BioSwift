//
//  FragmentTests.swift
//  BioSwiftTests
//
//  Created by Koen van der Drift on 9/28/26.
//

import Testing

@testable import BioSwift

struct FragmentTests {
    private enum TestFragmentType {
        case internalFragment
    }

    @Test func fragmentWrapsAChainAndMetadata() {
        let peptide = Peptide(sequence: "PEPTIDE")
        let fragment = Fragment(
            chain: peptide,
            fragmentType: TestFragmentType.internalFragment,
            index: 3
        )

        #expect(fragment.chain.sequenceString == "PEPTIDE")
        #expect(fragment.id == peptide.id)
        #expect(fragment.sequenceString == "PEPTIDE")
        #expect(fragment.fragmentType == .internalFragment)
        #expect(fragment.index == 3)
    }
}
