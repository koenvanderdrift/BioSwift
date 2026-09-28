//
//  NucleicAcidTests.swift
//  BioSwift
//

import Testing

@testable import BioSwift

@Suite struct NucleicAcidTests {
    @Test func parsesBundledDNAFasta() async throws {
        let records = try await FastaParser().parseBundleFile("nucleicacids")

        #expect(records.count == 3)
        #expect(records.map(\.fullName) == [
            "sequenceID-001 description",
            "sequenceID-002 description",
            "sequenceID-003 description",
        ])
        #expect(records.map(\.sequence.count) == [106, 154, 76])
    }

    @Test func transcribesBundledDNAFasta() async throws {
        let records = try await FastaParser().parseBundleFile("nucleicacids")
        let rnaSequences = records.map { DNA(fastaRecord: $0).transcribed().sequence() }

        #expect(rnaSequences == [
            "AAGUAGGAAUAAUAUCUUAUCAUUAUAGAUAAAAACCUUCUGAAUUUGCUUAGUGUGUAUACGACUAGACAUAUAUCAGCUCGCCGAUUAUUUGGAUUAUUCCCUG",
            "CAGUAAAGAGUGGAUGUAAGAACCGUCCGAUCUACCAGAUGUGAUAGAGGUUGCCAGUACAAAAAUUGCAUAAUAAUUGAUUAAUCCUUUAAUAUUGUUUAGAAUAUAUCCGUCAGAUAAUCCUAAAAAUAACGAUAUGAUGGCGGAAAUCGUC",
            "CUUCAAUUACCCUGCUGACGCGAGAUACCUUAUGCAUCGAAGGUAAAGCGAUGAAUUUAUCCAAGGUUUUAAUUUG",
        ])
    }

    @Test func translatesBundledDNAFasta() async throws {
        let records = try await FastaParser().parseBundleFile("nucleicacids")
        let dna = records.map(DNA.init(fastaRecord:))

        #expect(dna.map { $0.transcribed().translated().sequence() } == ["K", "Q", "LQLPC"])
        #expect(dna.map { $0.translated().sequence() } == ["K", "Q", "LQLPC"])
    }
}
