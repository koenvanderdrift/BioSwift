import Foundation
import Testing
@testable import BioSwift

@Suite("BLAST models")
struct BLASTModelsTests {
    @Test("BLAST search implementations use the provider-neutral interface")
    func searching() async throws {
        let query = try BLASTQuery(identifier: "query-1", sequence: "ACGT")
        let configuration = try BLASTConfiguration(program: .blastn, database: "test")
        let searcher: any BLASTSearching = StubBLASTSearcher()

        let result = try await searcher.search(query: query, configuration: configuration)

        #expect(result.program == .blastn)
        #expect(result.database == "test")
        #expect(result.query == query)
        #expect(result.hits.isEmpty)
    }

    @Test("BLAST programs support iteration and Codable round trips")
    func programs() throws {
        #expect(BLASTProgram.allCases == [.blastn, .blastp, .blastx, .tblastn, .tblastx])

        let encoded = try JSONEncoder().encode(BLASTProgram.tblastn)
        let decoded = try JSONDecoder().decode(BLASTProgram.self, from: encoded)

        #expect(decoded == .tblastn)
    }

    @Test("Queries and configurations retain provider-independent values")
    func configuration() throws {
        let query = try BLASTQuery(identifier: "query-1", sequence: "MPEPTIDE")
        let configuration = try BLASTConfiguration(
            program: .blastp,
            database: "swissprot",
            expectationValue: 0.001,
            maximumHits: 25,
            filtersLowComplexityRegions: false,
            substitutionMatrix: "BLOSUM62"
        )

        #expect(query.identifier == "query-1")
        #expect(query.sequence == "MPEPTIDE")
        #expect(configuration.program == .blastp)
        #expect(configuration.database == "swissprot")
        #expect(configuration.expectationValue == 0.001)
        #expect(configuration.maximumHits == 25)
        #expect(!configuration.filtersLowComplexityRegions)
        #expect(configuration.substitutionMatrix == "BLOSUM62")
    }

    @Test("High-scoring pairs derive alignment statistics")
    func highScoringPairStatistics() throws {
        let pair = try makeHighScoringPair()

        #expect(pair.alignmentLength == 5)
        #expect(pair.identity == 0.6)
        #expect(pair.positives == 0.8)
        #expect(pair.queryRange == 2..<6)
        #expect(pair.subjectRange == 10..<14)
        #expect(pair.subjectStrand == .minus)
    }

    @Test("Complete results support Codable round trips")
    func resultCodable() throws {
        let query = try BLASTQuery(identifier: "query-1", sequence: "ACGT")
        let hit = try BLASTHit(
            identifier: "subject-1",
            accession: "ABC123",
            definition: "Example sequence",
            sequenceLength: 42,
            highScoringPairs: [makeHighScoringPair()]
        )
        let result = BLASTResult(
            program: .blastn,
            database: "core_nt",
            query: query,
            hits: [hit]
        )

        let encoded = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(BLASTResult.self, from: encoded)

        #expect(decoded == result)
    }

    @Test("Queries reject empty and whitespace-only sequences", arguments: ["", " \n\t"])
    func emptyQuery(sequence: String) {
        #expect(throws: BLASTError.emptyQuery) {
            try BLASTQuery(sequence: sequence)
        }
    }

    @Test("Configurations validate database, expectation value, and hit count")
    func invalidConfiguration() {
        #expect(throws: BLASTError.emptyDatabase) {
            try BLASTConfiguration(program: .blastn, database: " ")
        }
        #expect(throws: BLASTError.invalidExpectationValue(0)) {
            try BLASTConfiguration(program: .blastn, database: "core_nt", expectationValue: 0)
        }
        #expect(throws: BLASTError.invalidMaximumHits(0)) {
            try BLASTConfiguration(program: .blastn, database: "core_nt", maximumHits: 0)
        }
    }

    @Test("Hits reject negative sequence lengths")
    func invalidHitLength() {
        #expect(throws: BLASTError.invalidSequenceLength(-1)) {
            try BLASTHit(identifier: "subject", sequenceLength: -1, highScoringPairs: [])
        }
    }

    @Test("High-scoring pairs validate coordinates and aligned sequences")
    func invalidHighScoringPairShape() {
        #expect(throws: BLASTError.invalidRange(-1..<2)) {
            try makeHighScoringPair(queryRange: -1..<2)
        }
        #expect(throws: BLASTError.inconsistentAlignmentLengths(query: 5, subject: 4)) {
            try makeHighScoringPair(subjectSequence: "ACGT")
        }
        #expect(throws: BLASTError.invalidCount(name: "identity", value: 6, alignmentLength: 5)) {
            try makeHighScoringPair(identityCount: 6)
        }
        #expect(throws: BLASTError.invalidCount(name: "positive", value: 2, alignmentLength: 5)) {
            try makeHighScoringPair(identityCount: 3, positiveCount: 2)
        }
    }

    private func makeHighScoringPair(
        queryRange: Range<Int> = 2..<6,
        subjectSequence: String = "AC-GT",
        identityCount: Int = 3,
        positiveCount: Int = 4
    ) throws -> BLASTHighScoringPair {
        try BLASTHighScoringPair(
            rawScore: 21,
            bitScore: 17.3,
            expectationValue: 0.0002,
            queryRange: queryRange,
            subjectRange: 10..<14,
            querySequence: "ACG-T",
            subjectSequence: subjectSequence,
            identityCount: identityCount,
            positiveCount: positiveCount,
            gapCount: 2,
            queryStrand: .plus,
            subjectStrand: .minus
        )
    }
}

private struct StubBLASTSearcher: BLASTSearching {
    func search(
        query: BLASTQuery,
        configuration: BLASTConfiguration
    ) async throws -> BLASTResult {
        BLASTResult(
            program: configuration.program,
            database: configuration.database,
            query: query,
            hits: []
        )
    }
}
