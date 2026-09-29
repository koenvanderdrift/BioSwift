//
//  NucleicAcidTests.swift
//  BioSwift
//

import Testing

@testable import BioSwift

@Suite struct NucleicAcidTests {
    @Test func dnaSequenceFormulaAndComplement() throws {
        let dna = DNA(sequence: "ATCG")
        let chain = try #require(dna.chains.first)

        #expect(chain.sequenceString == "ATCG")
        #expect(chain.complement.sequenceString == "TAGC")
        #expect(chain.reverseComplement.sequenceString == "CGAT")
        #expect(dna.formula.formulaString == "C39H51N15O25P4")
    }

    @Test func rnaSequenceFormulaAndComplement() throws {
        let rna = RNA(sequence: "AUCG")
        let chain = try #require(rna.chains.first)

        #expect(chain.sequenceString == "AUCG")
        #expect(chain.complement.sequenceString == "UAGC")
        #expect(chain.reverseComplement.sequenceString == "CGAU")
        #expect(rna.formula.formulaString == "C38H49N15O29P4")
    }

    @Test func nucleicAcidAPIParallelsProteinAPI() throws {
        let nucleotide = Nucleotide(
            name: "Adenine",
            oneLetterCode: "A",
            threeLetterCode: "dAMP",
            formula: Formula("C10H12N5O5P"),
            nucleicAcidType: .dna
        )
        let dna = DNA(residues: [nucleotide])

        #expect(dna.nucleotide(at: 0) == nucleotide)
        #expect(dna.nucleotides == [nucleotide])
        #expect(DNA(sequence: "ATCG").truncate(by: 1..<3).sequence == "AG")
        #expect(RNA(sequence: "AUCG").truncate(by: 1..<3).sequence == "AG")
    }

    @Test func nucleicAcidsAccessChainsByName() {
        let codingDNA = DNAChain(sequence: "GATTACA", name: "coding")
        let dna = DNA(chains: [codingDNA])

        let messengerRNA = RNAChain(sequence: "GAUUACA", name: "messenger")
        let rna = RNA(chains: [messengerRNA])

        #expect(dna.sequence(chainName: "coding") == "GATTACA")
        #expect(dna.nucleotides(chainName: "coding")?.count == 7)
        #expect(dna.nucleotide(at: 1, chainName: "coding")?.identifier == "A")
        #expect(rna.sequence(chainName: "messenger") == "GAUUACA")
        #expect(rna.nucleotides(chainName: "messenger")?.count == 7)
        #expect(rna.nucleotide(at: 2, chainName: "messenger")?.identifier == "U")
        #expect(rna.sequence(chainName: "missing") == nil)
    }

    @Test func nucleicAcidTransformationsPreserveChainNames() throws {
        let dna = DNA(chains: [DNAChain(sequence: "ATGGCT", name: "coding")])
        let rna = RNA(chains: [RNAChain(sequence: "AUGGCU", name: "messenger")])

        #expect(dna.complement.sequence(chainName: "coding") == "TACCGA")
        #expect(dna.reverse.sequence(chainName: "coding") == "TCGGTA")
        #expect(dna.reverseComplement.sequence(chainName: "coding") == "AGCCAT")
        #expect(rna.complement.sequence(chainName: "messenger") == "UACCGA")
        #expect(rna.reverse.sequence(chainName: "messenger") == "UCGGUA")
        #expect(rna.reverseComplement.sequence(chainName: "messenger") == "AGCCAU")
        #expect(dna.transcribed().sequence(chainName: "coding") == "AUGGCU")
        #expect(rna.translated().sequence(chainName: "messenger") == "MA")
        #expect(dna.translated().sequence(chainName: "coding") == "MA")
    }

    @Test func transcribesDNAIntoRNA() {
        #expect(DNA(sequence: "ATGGCTTAA").transcribed().sequence == "AUGGCUUAA")
    }

    @Test func translatesRNAAndDNAIntoProtein() {
        #expect(RNA(sequence: "AUGGCUUAAUGG").translated().sequence == "MA")
        #expect(DNA(sequence: "ATGGCTTAA").translated().sequence == "MA")
        #expect(RNA(sequence: "AUGGC").translated().sequence == "M")
    }

    @Test func parsesBundledDNAFasta() async throws {
        let records = try await FastaParser().parseBundleFile("dna-sequences")

        #expect(records.count == 3)
        #expect(records.map(\.fullName) == [
            "sequenceID-001 description",
            "sequenceID-002 description",
            "sequenceID-003 description",
        ])
        #expect(records.map(\.sequence.count) == [106, 154, 76])
    }

    @Test func transcribesBundledDNAFasta() async throws {
        let records = try await FastaParser().parseBundleFile("dna-sequences")
        let rnaSequences = records.map { DNA(fastaRecord: $0).transcribed().sequence }

        #expect(rnaSequences == [
            "AAGUAGGAAUAAUAUCUUAUCAUUAUAGAUAAAAACCUUCUGAAUUUGCUUAGUGUGUAUACGACUAGACAUAUAUCAGCUCGCCGAUUAUUUGGAUUAUUCCCUG",
            "CAGUAAAGAGUGGAUGUAAGAACCGUCCGAUCUACCAGAUGUGAUAGAGGUUGCCAGUACAAAAAUUGCAUAAUAAUUGAUUAAUCCUUUAAUAUUGUUUAGAAUAUAUCCGUCAGAUAAUCCUAAAAAUAACGAUAUGAUGGCGGAAAUCGUC",
            "CUUCAAUUACCCUGCUGACGCGAGAUACCUUAUGCAUCGAAGGUAAAGCGAUGAAUUUAUCCAAGGUUUUAAUUUG",
        ])
    }

    @Test func translatesBundledDNAFasta() async throws {
        let records = try await FastaParser().parseBundleFile("dna-sequences")
        let dna = records.map(DNA.init(fastaRecord:))

        #expect(dna.map { $0.transcribed().translated().sequence } == ["K", "Q", "LQLPC"])
        #expect(dna.map { $0.translated().sequence } == ["K", "Q", "LQLPC"])
    }
}
