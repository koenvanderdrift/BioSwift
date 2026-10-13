import Foundation
import Testing
@testable import BioSwift

@Suite("BLAST models")
struct BLASTModelsTests {
    @Test("BLAST programs support iteration and Codable round trips")
    func programs() throws {
        #expect(BLASTProgram.allCases == [.blastn, .blastp, .blastx, .tblastn, .tblastx])
        let data = try JSONEncoder().encode(BLASTProgram.tblastn)
        #expect(try JSONDecoder().decode(BLASTProgram.self, from: data) == .tblastn)
    }

    @Test("Queries and protein configurations retain their options")
    func proteinConfiguration() throws {
        let query = try BLASTQuery(identifier: "query-1", sequence: "MPEPTIDE")
        let configuration = try BLASTConfiguration(
            program: .blastp,
            database: "swissprot",
            expectationValue: 0.001,
            maximumHits: 25,
            filtersLowComplexityRegions: false,
            substitutionMatrix: "BLOSUM62",
            wordSize: 3,
            adjustsForShortQuery: true
        )

        #expect(query.identifier == "query-1")
        #expect(query.sequence == "MPEPTIDE")
        #expect(configuration.program == .blastp)
        #expect(configuration.database == "swissprot")
        #expect(configuration.expectationValue == 0.001)
        #expect(configuration.maximumHits == 25)
        #expect(!configuration.filtersLowComplexityRegions)
        #expect(configuration.substitutionMatrix == "BLOSUM62")
        #expect(configuration.wordSize == 3)
        #expect(configuration.adjustsForShortQuery == true)
    }

    @Test("Nucleotide configurations retain scoring options")
    func nucleotideConfiguration() throws {
        let configuration = try BLASTConfiguration(
            program: .blastn,
            database: "core_nt",
            nucleotideMatchReward: 2,
            nucleotideMismatchPenalty: -3
        )

        #expect(configuration.nucleotideMatchReward == 2)
        #expect(configuration.nucleotideMismatchPenalty == -3)
    }

    @Test("Queries reject empty and whitespace-only sequences", arguments: ["", " \n\t"])
    func emptyQuery(sequence: String) {
        #expect(throws: BLASTError.emptyQuery) {
            try BLASTQuery(sequence: sequence)
        }
    }

    @Test("Configurations validate common values")
    func invalidCommonConfiguration() {
        #expect(throws: BLASTError.emptyDatabase) {
            try BLASTConfiguration(program: .blastn, database: " ")
        }
        #expect(throws: BLASTError.invalidExpectationValue(0)) {
            try BLASTConfiguration(program: .blastn, database: "core_nt", expectationValue: 0)
        }
        #expect(throws: BLASTError.invalidMaximumHits(0)) {
            try BLASTConfiguration(program: .blastn, database: "core_nt", maximumHits: 0)
        }
        #expect(throws: BLASTError.invalidWordSize(0)) {
            try BLASTConfiguration(program: .blastn, database: "core_nt", wordSize: 0)
        }
    }

    @Test("Configurations reject options unsupported by a program")
    func unsupportedOptions() {
        #expect(throws: BLASTError.unsupportedOption("substitutionMatrix", program: .blastn)) {
            try BLASTConfiguration(
                program: .blastn,
                database: "core_nt",
                substitutionMatrix: "BLOSUM62"
            )
        }
        #expect(throws: BLASTError.unsupportedOption("adjustsForShortQuery", program: .blastx)) {
            try BLASTConfiguration(
                program: .blastx,
                database: "swissprot",
                adjustsForShortQuery: true
            )
        }
        #expect(throws: BLASTError.unsupportedOption("nucleotideScoring", program: .blastp)) {
            try BLASTConfiguration(
                program: .blastp,
                database: "swissprot",
                nucleotideMatchReward: 1
            )
        }
    }

    @Test("Nucleotide scoring signs are validated")
    func invalidNucleotideScoring() {
        #expect(throws: BLASTError.invalidNucleotideMatchReward(0)) {
            try BLASTConfiguration(
                program: .blastn,
                database: "core_nt",
                nucleotideMatchReward: 0
            )
        }
        #expect(throws: BLASTError.invalidNucleotideMismatchPenalty(1)) {
            try BLASTConfiguration(
                program: .blastn,
                database: "core_nt",
                nucleotideMismatchPenalty: 1
            )
        }
    }
}
