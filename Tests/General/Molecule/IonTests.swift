//
//  IonTests.swift
//  BioSwift
//

import Foundation
import Testing

@testable import BioSwift

@Suite struct IonTests {
    @Test func peptideIonPreservesConcreteStructureType() throws {
        let peptide = try Peptide(sequence: "SAMPLER")
        let ion: Ion<Peptide> = try peptide.ionized(with: [protonAdduct, sodiumAdduct])

        #expect(ion.structure.sequenceString == "SAMPLER")
        #expect(ion.name == peptide.name)
        #expect(ion.charge == 2)
        #expect(ion.monoisotopicMass.rounded(scale: 4) == decimal("413.1986"))
    }

    @Test func dnaAndFunctionalGroupCanFormIons() throws {
        let dna = try DNA(sequence: "ATCG")
        let dnaIon: Ion<DNA> = try dna.ionized(with: [
            negativeProtonAdduct,
            negativeProtonAdduct,
        ])
        let chlorideIon: Ion<FunctionalGroup> = try water.ionized(with: [chlorineAdduct])

        #expect(dnaIon.charge == -2)
        #expect(dnaIon.monoisotopicMass < dna.monoisotopicMass)
        #expect(chlorideIon.charge == -1)
        #expect(chlorideIon.monoisotopicMass > water.monoisotopicMass)
    }

    @Test func negativeIonMasses() throws {
        let deprotonated = try water.ionized(with: [negativeProtonAdduct])
        let doublyDeprotonated = try water.ionized(with: [
            negativeProtonAdduct,
            negativeProtonAdduct,
        ])
        let chlorideAdduct = try water.ionized(with: [chlorineAdduct])

        #expect(deprotonated.monoisotopicMass.rounded(scale: 6) == decimal("17.003289"))
        #expect(doublyDeprotonated.monoisotopicMass.rounded(scale: 6) == decimal("7.998006"))
        #expect(chlorideAdduct.monoisotopicMass.rounded(scale: 6) == decimal("52.979966"))
    }

    @Test func ionRequiresNonzeroCharge() throws {
        #expect(throws: IonError.noAdducts) {
            try water.ionized(with: [])
        }

        #expect(throws: IonError.zeroCharge) {
            try water.ionized(with: [protonAdduct, negativeProtonAdduct])
        }
    }

    @Test func decodingValidatesAdducts() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let validIon = try water.ionized(with: [protonAdduct])
        let encodedIon = try encoder.encode(validIon)
        let decodedIon = try decoder.decode(Ion<FunctionalGroup>.self, from: encodedIon)

        #expect(decodedIon == validIon)

        var payload = try #require(
            JSONSerialization.jsonObject(with: encodedIon) as? [String: Any]
        )
        payload["adducts"] = []

        #expect(throws: IonError.noAdducts) {
            try decoder.decode(
                Ion<FunctionalGroup>.self,
                from: JSONSerialization.data(withJSONObject: payload)
            )
        }

        payload["adducts"] = try JSONSerialization.jsonObject(
            with: encoder.encode([protonAdduct, negativeProtonAdduct])
        )

        #expect(throws: IonError.zeroCharge) {
            try decoder.decode(
                Ion<FunctionalGroup>.self,
                from: JSONSerialization.data(withJSONObject: payload)
            )
        }
    }
}
