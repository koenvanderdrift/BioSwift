//
//  DigestionTests.swift
//  BioSwift
//

import Foundation
import Testing

@testable import BioSwift

@Suite struct DigestionTests: BioSwiftTestSuite {
    var fixtures = BioSwiftTestFixtures()
    @Test func digest() throws {
        let digester = ProteinDigester(protein: testProtein)

        let missedCleavages = 0

        let trypsin = try (ReferenceLibraryDefaults.loadBundled().enzymes + [unspecifiedEnzyme]).first(where: {
            $0.name == "Trypsin"
        })

        if let enzyme = trypsin {
            let peptides: [Peptide] = try digester.peptides(using: enzyme, with: missedCleavages)

            #expect(peptides[0].sequenceString == "MPSSVSWGILLLAGLCCLVPVSLAEDPQGDAAQK")
            #expect(peptides[1].sequenceString == "TDTSHHDQDHPTFNK")
            #expect(peptides.map(\.sequenceString).contains("WERPFEVK"))
            #expect(!peptides.map(\.sequenceString).contains("WER"))
        }

        let lysC = try (ReferenceLibraryDefaults.loadBundled().enzymes + [unspecifiedEnzyme]).first(where: {
            $0.name == "Lys-C"
        })

        if let enzyme = lysC {
            let peptides: [Peptide] = try digester.peptides(using: enzyme, with: missedCleavages)

            #expect(peptides[0].sequenceString == "MPSSVSWGILLLAGLCCLVPVSLAEDPQGDAAQK")
            #expect(peptides[1].sequenceString == "TDTSHHDQDHPTFNK")
            #expect(peptides.map(\.sequenceString).contains("FNKPFVFMIEQNTK"))
            #expect(!peptides.map(\.sequenceString).contains("FNK"))
        }

        let aspN = try (ReferenceLibraryDefaults.loadBundled().enzymes + [unspecifiedEnzyme]).first(where: {
            $0.name == "Asp-N"
        })

        if let enzyme = aspN {
            let peptides: [Peptide] = try digester.peptides(using: enzyme, with: missedCleavages)

            #expect(peptides[0].sequenceString == "MPSSVSWGILLLAGLCCLVPVSLAE")
            #expect(peptides[1].sequenceString == "DPQG")
        }

        let pepsin1 = try (ReferenceLibraryDefaults.loadBundled().enzymes + [unspecifiedEnzyme]).first(where: {
            $0.name == "Pepsin (pH = 1.3)"
        })

        if let enzyme = pepsin1 {
            let peptides: [Peptide] = try digester.peptides(using: enzyme, with: missedCleavages)

            #expect(peptides[0].sequenceString == "MPSSVSWGIL")
            #expect(peptides[1].sequenceString == "L")
            #expect(peptides[2].sequenceString == "L")
            #expect(!peptides.map(\.sequenceString).contains("AEDPQGDAAQKTDTSHHDQDHPTF"))
            #expect(peptides.map(\.sequenceString).contains("NKITPNL"))
            #expect(peptides.map(\.sequenceString).contains("MGKVVNPTQK"))
        }

        let pepsin2 = try (ReferenceLibraryDefaults.loadBundled().enzymes + [unspecifiedEnzyme]).first(where: {
            $0.name == "Pepsin (pH > 2)"
        })

        if let enzyme = pepsin2 {
            let peptides: [Peptide] = try digester.peptides(using: enzyme, with: missedCleavages)

            #expect(peptides[0].sequenceString == "MPSSVS")
            #expect(peptides[1].sequenceString == "W")
            #expect(peptides[2].sequenceString == "GI")
            #expect(peptides.map(\.sequenceString).contains("AEDPQGDAAQKTDTSHHDQDHPTF"))
            #expect(peptides.map(\.sequenceString).contains("NKITPNL"))
            #expect(peptides.map(\.sequenceString).contains("MGKVVNPTQK"))
        }
    }

    @Test func digestUnspecified() throws {
        let unspecified = try (ReferenceLibraryDefaults.loadBundled().enzymes + [unspecifiedEnzyme]).first(where: {
            $0.name == "Unspecified"
        })
        #expect(unspecified?.name == "Unspecified")
    }

    @Test func digestMasses() throws {
        let digester = ProteinDigester(protein: testProtein)

        let missedCleavages = 1

        let trypsin = try (ReferenceLibraryDefaults.loadBundled().enzymes + [unspecifiedEnzyme]).first(where: {
            $0.name == "Trypsin"
        })

        if let enzyme = trypsin {
            let peptides: [Ion<Peptide>] = try digester.peptides(using: enzyme, with: missedCleavages)
                .protonated(chargeStates: 1...1)
            #expect(peptides[0].monoisotopicMass.rounded(scale: 4) == decimal("3468.7575"))  // 3467.7503
            #expect(peptides[2].monoisotopicMass.rounded(scale: 4) == decimal("1779.7681"))  // 1778.7608
        }
    }

    @Test func digestionRetainsSourceChainMetadata() throws {
        let alphaID = UUID()
        let betaID = UUID()
        let protein = Protein(chains: [
            try ProteinChain(sequence: "AKR", name: "alpha", id: alphaID),
            try ProteinChain(sequence: "MKR", name: "beta", id: betaID),
        ])
        let enzyme = try #require(try ReferenceLibraryDefaults.loadBundled().enzymes.first { $0.name == "Trypsin" })

        let peptides: [Peptide] = try ProteinDigester(protein: protein).peptides(using: enzyme)
        let alphaPeptides = peptides.filter { $0.id == alphaID }
        let betaPeptides = peptides.filter { $0.id == betaID }

        #expect(alphaPeptides.map(\.name) == ["alpha", "alpha"])
        #expect(alphaPeptides.map(\.sequenceString) == ["AK", "R"])
        #expect(alphaPeptides.map(\.range) == [0..<2, 2..<3])
        #expect(alphaPeptides.allSatisfy { $0.parentLength == 3 })

        #expect(betaPeptides.map(\.name) == ["beta", "beta"])
        #expect(betaPeptides.map(\.sequenceString) == ["MK", "R"])
        #expect(betaPeptides.map(\.range) == [0..<2, 2..<3])
        #expect(betaPeptides.allSatisfy { $0.parentLength == 3 })
    }

    @Test func invalidDigestionRegexThrows() throws {
        let chain = try ProteinChain(sequence: "PEPTIDE")

        #expect(throws: (any Error).self) {
            try chain.digest(using: "[")
        }
    }

}
