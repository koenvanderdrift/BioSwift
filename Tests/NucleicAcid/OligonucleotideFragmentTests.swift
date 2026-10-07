//
//  OligonucleotideFragmentTests.swift
//  BioSwift
//

import Foundation
import Testing

@testable import BioSwift

@Suite struct OligonucleotideFragmentTests {
    @Test func fragmentTypeClassification() {
        #expect(OligonucleotideFragmentType.precursorIon.isPrecursor)
        #expect(OligonucleotideFragmentType.aIonMinusBase.isFivePrime)
        #expect(OligonucleotideFragmentType.dIon.isFivePrime)
        #expect(OligonucleotideFragmentType.wIon.isThreePrime)
        #expect(OligonucleotideFragmentType.zIon.isThreePrime)
    }

    @Test func reviewedMassAdjustments() throws {
        let chain = try DNAChain(sequence: "ACG")
        let neutral = chain.masses

        let dAdjustment = zeroMass - hydroxyl.masses
        let cAdjustment = dAdjustment - water.masses
        let phosphateBackboneAdjustment = phosphorus.masses + 2 * oxygen.masses
        let bAdjustment = cAdjustment - phosphateBackboneAdjustment + hydrogen.masses
        let aAdjustment = bAdjustment - water.masses

        #expect(fragment(chain, .aIon).masses == neutral + aAdjustment)
        #expect(fragment(chain, .bIon).masses == neutral + bAdjustment)
        #expect(fragment(chain, .cIon).masses == neutral + cAdjustment)
        #expect(fragment(chain, .dIon).masses == neutral + dAdjustment)
        #expect(fragment(chain, .wIon).masses == neutral + dAdjustment)
        #expect(fragment(chain, .xIon).masses == neutral + cAdjustment)
        #expect(fragment(chain, .yIon).masses == neutral + bAdjustment)
        #expect(fragment(chain, .zIon).masses == neutral + aAdjustment)
    }

    @Test func baseLossUsesTerminalNucleobaseComposition() throws {
        let dnaBases: [(Character, String)] = [
            ("A", "C5H5N5"),
            ("C", "C4H5N3O"),
            ("G", "C5H5N5O"),
            ("T", "C5H6N2O2"),
        ]

        for (base, formula) in dnaBases {
            let chain = try DNAChain(sequence: "A\(base)")
            let fragment = fragment(chain, .aIonMinusBase)
            #expect(fragment.lostBase?.oneLetterCode == String(base))
            let aIon = self.fragment(chain, .aIon)
            #expect(fragment.masses == aIon.masses - (try Formula(formula)).masses)
        }

        let rna = try RNAChain(sequence: "AU")
        #expect(fragment(rna, .aIonMinusBase).masses
            == fragment(rna, .aIon).masses - (try Formula("C4H4N2O2")).masses)
    }

    @Test func fragmentRetainsChainMetadataAndModification() throws {
        var chain = try RNAChain(sequence: "ACG", name: "RNA fragment")
        chain.residues[1].modification = lossOfWater
        chain.parentLength = 8

        let fragment = OligonucleotideFragment(
            chain: chain,
            fragmentType: .cIon,
            index: 3)

        #expect(fragment.sequenceString == "ACG")
        #expect(fragment.name == "RNA fragment")
        #expect(fragment.parentLength == 8)
        #expect(fragment.residues[1].modification == lossOfWater)
    }

    @Test func codableAndSendable() throws {
        let original = OligonucleotideFragment(
            chain: try DNAChain(sequence: "AC"),
            fragmentType: .aIonMinusBase,
            index: 2)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(
            OligonucleotideFragment<DNAChain>.self,
            from: data)

        #expect(decoded == original)
        requireSendable(original)
    }

    private func fragment<ChainType: NucleicAcidChain>(
        _ chain: ChainType,
        _ type: OligonucleotideFragmentType
    ) -> OligonucleotideFragment<ChainType> {
        OligonucleotideFragment(chain: chain, fragmentType: type)
    }

    private func requireSendable<T: Sendable>(_ value: T) {}
}
