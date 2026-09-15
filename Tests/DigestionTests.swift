//
//  DigestionTests.swift
//  BioSwift
//

import Foundation
import Testing

@testable import BioSwift

@Suite struct DigestionTests: BioSwiftTestSuite {
    var fixtures = BioSwiftTestFixtures()
    @Test func digest() {
        let digester = ProteinDigester(protein: testProtein)

        let missedCleavages = 0

        let trypsin = enzymeLibrary.first(where: {
            $0.name == "Trypsin"
        })

        if let enzyme = trypsin {
            let peptides: [Peptide] = digester.peptides(using: enzyme, with: missedCleavages)

            #expect(peptides[0].sequenceString == "MPSSVSWGILLLAGLCCLVPVSLAEDPQGDAAQK")
            #expect(peptides[1].sequenceString == "TDTSHHDQDHPTFNK")
            #expect(peptides.map(\.sequenceString).contains("WERPFEVK"))
            #expect(!peptides.map(\.sequenceString).contains("WER"))
        }

        let lysC = enzymeLibrary.first(where: {
            $0.name == "Lys-C"
        })

        if let enzyme = lysC {
            let peptides: [Peptide] = digester.peptides(using: enzyme, with: missedCleavages)

            #expect(peptides[0].sequenceString == "MPSSVSWGILLLAGLCCLVPVSLAEDPQGDAAQK")
            #expect(peptides[1].sequenceString == "TDTSHHDQDHPTFNK")
            #expect(peptides.map(\.sequenceString).contains("FNKPFVFMIEQNTK"))
            #expect(!peptides.map(\.sequenceString).contains("FNK"))
        }

        let aspN = enzymeLibrary.first(where: {
            $0.name == "Asp-N"
        })

        if let enzyme = aspN {
            let peptides: [Peptide] = digester.peptides(using: enzyme, with: missedCleavages)

            #expect(peptides[0].sequenceString == "MPSSVSWGILLLAGLCCLVPVSLAE")
            #expect(peptides[1].sequenceString == "DPQG")
        }

        let pepsin1 = enzymeLibrary.first(where: {
            $0.name == "Pepsin (pH = 1.3)"
        })

        if let enzyme = pepsin1 {
            let peptides: [Peptide] = digester.peptides(using: enzyme, with: missedCleavages)

            #expect(peptides[0].sequenceString == "MPSSVSWGIL")
            #expect(peptides[1].sequenceString == "L")
            #expect(peptides[2].sequenceString == "L")
            #expect(!peptides.map(\.sequenceString).contains("AEDPQGDAAQKTDTSHHDQDHPTF"))
            #expect(peptides.map(\.sequenceString).contains("NKITPNL"))
            #expect(peptides.map(\.sequenceString).contains("MGKVVNPTQK"))
        }

        let pepsin2 = enzymeLibrary.first(where: {
            $0.name == "Pepsin (pH > 2)"
        })

        if let enzyme = pepsin2 {
            let peptides: [Peptide] = digester.peptides(using: enzyme, with: missedCleavages)

            #expect(peptides[0].sequenceString == "MPSSVS")
            #expect(peptides[1].sequenceString == "W")
            #expect(peptides[2].sequenceString == "GI")
            #expect(peptides.map(\.sequenceString).contains("AEDPQGDAAQKTDTSHHDQDHPTF"))
            #expect(peptides.map(\.sequenceString).contains("NKITPNL"))
            #expect(peptides.map(\.sequenceString).contains("MGKVVNPTQK"))
        }
    }

    @Test func digestUnspecified() {
        let unspecified = enzymeLibrary.first(where: {
            $0.name == "Unspecified"
        })
        #expect(unspecified?.name == "Unspecified")
    }

    @Test func digestMasses() {
        let digester = ProteinDigester(protein: testProtein)

        let missedCleavages = 1

        let trypsin = enzymeLibrary.first(where: {
            $0.name == "Trypsin"
        })

        if let enzyme = trypsin {
            let peptides: [Peptide] = digester.peptides(using: enzyme, with: missedCleavages)
                .charge(with: 1...1)
            #expect(peptides[0].monoisotopicMass.rounded(scale: 4) == decimal("3468.7575"))  // 3467.7503
            #expect(peptides[2].monoisotopicMass.rounded(scale: 4) == decimal("1779.7681"))  // 1778.7608
        }
    }

}
