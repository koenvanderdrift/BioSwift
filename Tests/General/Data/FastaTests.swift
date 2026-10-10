//
//  FastaTests.swift
//  BioSwift
//

import Foundation
import Testing

@testable import BioSwift

@Suite struct FastaTests {
    private let parser = FastaParser()

    @Test func parsesUniProtHeadersWithOptionalMetadata() {
        let swissProt = parser.parseString(
            ">sp|P02919|PBPB_ECOLI Penicillin-binding protein 1B OS=Escherichia coli (strain K12) OX=83333 PE=1 SV=1"
        )
        let trembl = parser.parseString(
            ">tr|Q8ADX7|Q8ADX7_9HIV1 Envelope glycoprotein gp160"
        )

        #expect(swissProt.accession == "P02919")
        #expect(swissProt.headerFormat == .uniProt)
        #expect(swissProt.shortName == "PBPB_ECOLI")
        #expect(swissProt.fullName == "Penicillin-binding protein 1B")
        #expect(swissProt.organism == "Escherichia coli (strain K12)")
        #expect(trembl.accession == "Q8ADX7")
        #expect(trembl.headerFormat == .uniProt)
        #expect(trembl.shortName == "Q8ADX7_9HIV1")
        #expect(trembl.fullName == "Envelope glycoprotein gp160")
        #expect(trembl.organism.isEmpty)
    }

    @Test func parsesKnownNonUniProtHeaders() {
        let ups = parser.parseString(
            ">P02768ups|ALBU_HUMAN_UPS Serum albumin - Homo sapiens (Human)"
        )
        let ipi = parser.parseString(
            ">IPI00300415 IPI:IPI00300415.9|SWISS-PROT:Q8N431-1"
        )
        let ensembl = parser.parseString(
            ">ENSP00000391493 pep:known chromosome:GRCh37:2"
        )

        #expect(ups.accession == "P02768")
        #expect(ups.headerFormat == .ups)
        #expect(ups.shortName == "ALBU_HUMAN_UPS")
        #expect(ups.fullName == "Serum albumin")
        #expect(ups.organism == "Homo sapiens (Human)")
        #expect(ipi.accession == "IPI00300415")
        #expect(ipi.headerFormat == .ipi)
        #expect(ipi.fullName == "IPI:IPI00300415.9|SWISS-PROT:Q8N431-1")
        #expect(ensembl.accession == "ENSP00000391493")
        #expect(ensembl.headerFormat == .ensembl)
        #expect(ensembl.fullName == "pep:known chromosome:GRCh37:2")
    }

    @Test func parsesNCBICompoundHeaders() {
        let legacyRefSeq = parser.parseString(
            ">gi|16760827|ref|NP_456444.1| ATP synthase subunit [Escherichia coli]"
        )
        let genBank = parser.parseString(
            ">gb|M73307|AGMA13GT genomic sequence [Arabidopsis thaliana]"
        )

        #expect(legacyRefSeq.headerFormat == .ncbi)
        #expect(legacyRefSeq.accession == "NP_456444.1")
        #expect(legacyRefSeq.organism == "Escherichia coli")
        #expect(genBank.headerFormat == .ncbi)
        #expect(genBank.accession == "M73307")
        #expect(genBank.shortName == "AGMA13GT")
        #expect(genBank.organism == "Arabidopsis thaliana")
    }

    @Test func parsesModernRefSeqAndNCBIDefinitionLines() {
        let refSeq = parser.parseString(
            ">NM_002111.8 huntingtin mRNA [Homo sapiens]"
        )
        let submission = parser.parseString(
            ">Seq1 [organism=Mus musculus] [strain=C57BL/6]"
        )

        #expect(refSeq.headerFormat == .ncbi)
        #expect(refSeq.accession == "NM_002111.8")
        #expect(refSeq.fullName == "huntingtin mRNA")
        #expect(refSeq.organism == "Homo sapiens")
        #expect(submission.headerFormat == .ncbi)
        #expect(submission.accession == "Seq1")
        #expect(submission.organism == "Mus musculus")
    }

    @Test func expandsEnsemblHeaderRecognition() {
        let gencodeStyle = parser.parseString(
            ">ENST00000332235.7|ENSG00000183186.7|OTTHUMG00000180534 transcript"
        )
        let genomicCoordinate = parser.parseString(
            ">chromosome:GRCh37:3:129246883:129254612:1"
        )

        #expect(gencodeStyle.headerFormat == .ensembl)
        #expect(gencodeStyle.accession == "ENST00000332235.7")
        #expect(gencodeStyle.fullName == "transcript")
        #expect(genomicCoordinate.headerFormat == .ensembl)
        #expect(genomicCoordinate.accession == "chromosome:GRCh37:3:129246883:129254612:1")
    }

    @Test func ambiguousSimpleAccessionsRemainGeneric() {
        let record = parser.parseString(
            ">CM000663.2 Homo sapiens chromosome 1"
        )

        #expect(record.headerFormat == .generic)
        #expect(record.accession == "CM000663.2")
    }

    @Test func genericFallbackPreservesUnknownHeaders() {
        let record = parser.parseString(
            ">custom-001 description containing ups| and transport markers"
        )

        #expect(record.header == "custom-001 description containing ups| and transport markers")
        #expect(record.headerFormat == .generic)
        #expect(record.accession == "custom-001")
        #expect(record.fullName == "custom-001 description containing ups| and transport markers")
        #expect(record.shortName.isEmpty)
        #expect(record.organism.isEmpty)
    }

    @Test func minimallyAnnotatedRecordRemainsUsable() async throws {
        let records = try await parser.parseFasta(">sequence-1\nACGT")
        let record = try #require(records.first)

        #expect(record.header == "sequence-1")
        #expect(record.accession == "sequence-1")
        #expect(record.fullName == "sequence-1")
        #expect(record.sequence == "ACGT")
    }

    @Test func parsingIsSequenceTypeAgnostic() async throws {
        let proteinRecord = try #require(
            try await parser.parseFasta(">protein example\nPEPTIDE").first
        )
        let dnaRecord = try #require(
            try await parser.parseFasta(">dna example\nATCG").first
        )
        let rnaRecord = try #require(
            try await parser.parseFasta(">rna example\nAUCG").first
        )

        #expect(try Protein(fastaRecord: proteinRecord).sequence == "PEPTIDE")
        #expect(try DNA(fastaRecord: dnaRecord).sequence == "ATCG")
        #expect(try RNA(fastaRecord: rnaRecord).sequence == "AUCG")
    }

    @Test func codableRoundTripPreservesHeader() throws {
        let original = parser.parseString(">record-1 description")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FastaRecord.self, from: encoded)

        #expect(decoded == original)
        #expect(decoded.header == "record-1 description")
    }

    @Test func decodingOlderRecordDefaultsMissingHeader() throws {
        let original = parser.parseString(">record-1 description")
        var payload = try #require(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any]
        )
        payload.removeValue(forKey: "header")
        payload.removeValue(forKey: "headerFormat")

        let decoded = try JSONDecoder().decode(
            FastaRecord.self,
            from: JSONSerialization.data(withJSONObject: payload)
        )

        #expect(decoded.header.isEmpty)
        #expect(decoded.headerFormat == .generic)
        #expect(decoded.accession == original.accession)
        #expect(decoded.sequence == original.sequence)
    }
}
