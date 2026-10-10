//
//  ProFormaTests.swift
//  BioSwift
//

import Testing

@testable import BioSwift

@Suite struct ProFormaTests {
    private let parser = ProFormaParser()

    @Test func parsesAndRoundTripsCoreNotation() throws {
        let text = "[Acetyl]-EM[UNIMOD:35]E[+15.9949]K-[Methyl]/2"
        let result = try parser.parse(text)

        #expect(result.sequence == "EMEK")
        #expect(result.charge == 2)
        #expect(result.modifications == [
            .init(value: "Acetyl", location: .nTerminal),
            .init(value: "UNIMOD:35", location: .residue(1)),
            .init(value: "+15.9949", location: .residue(2)),
            .init(value: "Methyl", location: .cTerminal),
        ])
        #expect(result.proFormaString == text)
    }

    @Test func convertsToPeptideUsingCallerResolver() throws {
        let result = try parser.parse("PEP[Phospho]TIDE")
        let peptide = try result.peptide { annotation in
            #expect(annotation.value == "Phospho")
            return hydrogenModification
        }

        #expect(peptide.sequenceString == "PEPTIDE")
        #expect(peptide.modification(at: 2) == hydrogenModification)
    }

    @Test func rejectsUnsupportedAdvancedSyntaxExplicitly() {
        #expect(throws: ProFormaError.self) { try parser.parse("[Phospho]?PEPTIDE") }
        #expect(throws: ProFormaError.self) { try parser.parse("PEP[Phospho#g1]TIDE") }
        #expect(throws: ProFormaError.self) { try parser.parse("PEP[Phospho|info:test]TIDE") }
        #expect(throws: ProFormaError.self) { try parser.parse("PEPTIDE+OTHER") }
    }
}

