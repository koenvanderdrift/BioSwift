//
//  OligonucleotideFragmenterTests.swift
//  BioSwift
//

import Foundation
import Testing

@testable import BioSwift

@Suite struct OligonucleotideFragmenterTests {
    @Test func generatesPrecursorAndTerminalSeries() throws {
        try assertFragmentCounts(for: DNAChain(sequence: "ACGT"))
        try assertFragmentCounts(for: RNAChain(sequence: "ACGU"))
    }

    private func assertFragmentCounts<ChainType: NucleicAcidChain>(
        for chain: ChainType
    ) throws {
        let fragmenter = OligonucleotideFragmenter(
            precursor: try chain.ionized(with: [negativeProtonAdduct]))
        #expect(fragmenter.precursorIons().count == 1)
        #expect(fragmenter.fivePrimeIons().count == 15)
        #expect(fragmenter.threePrimeIons().count == 12)
        #expect(fragmenter.fragments.count == 28)
    }

    @Test func usesMcLuckeyNumberingAndComplementarySlices() throws {
        let chain = try RNAChain(sequence: "ACGU")
        let precursor = try chain.ionized(with: [negativeProtonAdduct])
        let fragmenter = OligonucleotideFragmenter(precursor: precursor)

        let complementaryTypes: [(OligonucleotideFragmentType, OligonucleotideFragmentType)] = [
            (OligonucleotideFragmentType.aIon, .wIon),
            (.bIon, .xIon),
            (.cIon, .yIon),
            (.dIon, .zIon),
        ]
        for (fivePrime, threePrime) in complementaryTypes {
            let fivePrimeIon = try #require(fragmenter.fragment(at: 2, for: fivePrime))
            let threePrimeIon = try #require(fragmenter.fragment(at: 2, for: threePrime))

            #expect(fivePrimeIon.structure.sequenceString == "AC")
            #expect(threePrimeIon.structure.sequenceString == "GU")
            #expect(fivePrimeIon.structure.index == 2)
            #expect(threePrimeIon.structure.index == 2)
        }
    }

    @Test func generatesAvailableNegativeChargeStates() throws {
        let chain = try DNAChain(sequence: "ACGT")
        let precursor = try chain.ionized(with: [
            negativeProtonAdduct,
            negativeProtonAdduct,
        ])
        let fragmenter = OligonucleotideFragmenter(precursor: precursor)

        let singlyCharged = try #require(fragmenter.fragment(at: 2, for: .wIon, with: -1))
        let doublyCharged = try #require(fragmenter.fragment(at: 2, for: .wIon, with: -2))

        #expect(singlyCharged.monoisotopicMass.rounded(scale: 4) == decimal("633.0991"))
        #expect(doublyCharged.monoisotopicMass.rounded(scale: 4) == decimal("316.0459"))
        #expect(fragmenter.fragment(at: 1, for: .aIon, with: 1) == nil)
    }

    @Test func emptyAndSingleResidueChainsHaveNoTerminalFragments() throws {
        try assertNoTerminalFragments(for: DNAChain(sequence: ""))
        try assertNoTerminalFragments(for: DNAChain(sequence: "A"))
        try assertNoTerminalFragments(for: RNAChain(sequence: ""))
        try assertNoTerminalFragments(for: RNAChain(sequence: "A"))
    }

    private func assertNoTerminalFragments<ChainType: NucleicAcidChain>(
        for chain: ChainType
    ) throws {
        let fragmenter = OligonucleotideFragmenter(
            precursor: try chain.ionized(with: [negativeProtonAdduct]))
        #expect(fragmenter.precursorIons().count == 1)
        #expect(fragmenter.fivePrimeIons().isEmpty)
        #expect(fragmenter.threePrimeIons().isEmpty)
    }

    @Test func modificationsFollowTheirNucleotide() throws {
        var chain = try RNAChain(sequence: "ACGU")
        chain.residues[1].modification = lossOfWater
        let fragmenter = OligonucleotideFragmenter(
            precursor: try chain.ionized(with: [negativeProtonAdduct]))

        let a1 = try #require(fragmenter.fragment(at: 1, for: .aIon))
        let a2 = try #require(fragmenter.fragment(at: 2, for: .aIon))
        let w2 = try #require(fragmenter.fragment(at: 2, for: .wIon))
        let w3 = try #require(fragmenter.fragment(at: 3, for: .wIon))

        #expect(a1.structure.residues.allSatisfy { $0.modification == nil })
        #expect(a2.structure.residues[1].modification == lossOfWater)
        #expect(w2.structure.residues.allSatisfy { $0.modification == nil })
        #expect(w3.structure.residues[0].modification == lossOfWater)
    }

    @Test func fragmentIonsAreCodableAndSendable() throws {
        try assertCodableAndSendable(
            try DNAChain(sequence: "ACGT"), fragmentType: .aIonMinusBase)
        try assertCodableAndSendable(
            try RNAChain(sequence: "ACGU"), fragmentType: .yIon)
    }

    private func assertCodableAndSendable<ChainType: NucleicAcidChain & Codable & Equatable & Sendable>(
        _ chain: ChainType,
        fragmentType: OligonucleotideFragmentType
    ) throws {
        let fragmenter = OligonucleotideFragmenter(
            precursor: try chain.ionized(with: [negativeProtonAdduct]))
        let original = try #require(fragmenter.fragment(at: 2, for: fragmentType))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(
            Ion<OligonucleotideFragment<ChainType>>.self,
            from: data)

        #expect(decoded == original)
        requireSendable(original)
    }

    /// Mongo Oligo Mass Calculator v2.07 monoisotopic negative-mode fixtures.
    /// `c` is also Mongo's `d−H2O`, since d−c = H2O.
    @Test func matchesMongoOligoCIDMasses() throws {
        let dna = OligonucleotideFragmenter(precursor:
            try DNAChain(sequence: "ACGT").ionized(with: [negativeProtonAdduct]))
        try expectMass(dna.fragment(at: 2, for: .aIonMinusBase), "393.08")
        try expectMass(dna.fragment(at: 2, for: .wIon), "633.10")
        try expectMass(dna.fragment(at: 2, for: .yIon), "553.13")
        try expectMass(dna.fragment(at: 2, for: .cIon), "584.09")

        let rna = OligonucleotideFragmenter(precursor:
            try RNAChain(sequence: "ACGU").ionized(with: [negativeProtonAdduct]))
        try expectMass(rna.fragment(at: 3, for: .aIonMinusBase), "730.12")
        try expectMass(rna.fragment(at: 3, for: .wIon), "956.11")
        try expectMass(rna.fragment(at: 3, for: .yIon), "876.15")
        try expectMass(rna.fragment(at: 3, for: .cIon), "961.13")
    }

    private func expectMass<ChainType: NucleicAcidChain>(
        _ ion: Ion<OligonucleotideFragment<ChainType>>?,
        _ expected: String
    ) throws {
        let ion = try #require(ion)
        #expect(ion.monoisotopicMass.rounded(scale: 2) == decimal(expected))
    }

    private func requireSendable<T: Sendable>(_ value: T) {
    }
}
