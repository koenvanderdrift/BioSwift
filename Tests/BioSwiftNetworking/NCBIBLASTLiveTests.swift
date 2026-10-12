import BioSwift
import BioSwiftNetworking
import Foundation
import Testing

@Suite("NCBI BLAST live integration")
struct NCBIBLASTLiveTests {
    @Test(
        "A real ubiquitin query returns and logs protein alignments",
        .enabled(
            if: ProcessInfo.processInfo.environment["BIOSWIFT_RUN_LIVE_NCBI_BLAST"] == "1",
            "Set BIOSWIFT_RUN_LIVE_NCBI_BLAST=1 to run this live NCBI integration test."
        )
    )
    func ubiquitinProteinSearch() async throws {
        let environment = ProcessInfo.processInfo.environment
        let email = try #require(
            environment["BIOSWIFT_NCBI_EMAIL"],
            "Set BIOSWIFT_NCBI_EMAIL to the contact address required by NCBI."
        )
        let query = try BLASTQuery( // RID CTXP68MM014
            identifier: "human-ubiquitin",
            sequence: "MQIFVKTLTGKTITLEVEPSDTIENVKAKIQDKEGIPPDQQRLIFAGKQLEDGRTLSDYNIQKESTLHLVLRLRGG"
        )
        let configuration = try BLASTConfiguration(
            program: .blastp,
            database: "swissprot",
            expectationValue: 0.001,
            maximumHits: 5,
            filtersLowComplexityRegions: true,
            substitutionMatrix: "BLOSUM62"
        )
        let client = try NCBIBLASTClient(
            email: email,
            tool: "BioSwiftLiveTest",
            eventHandler: { print($0.description) }
        )

        printInput(query: query, configuration: configuration)
        let result = try await client.search(query: query, configuration: configuration)
        printOutput(result)

        #expect(result.program == .blastp)
        #expect(!result.hits.isEmpty)
        #expect(result.hits.allSatisfy { !$0.highScoringPairs.isEmpty })
    }

    private func printInput(query: BLASTQuery, configuration: BLASTConfiguration) {
        print("""

        ===== NCBI BLAST INPUT =====
        Program:  \(configuration.program.rawValue)
        Database: \(configuration.database)
        Query:    \(query.identifier ?? "unnamed") (\(query.sequence.count) residues)
        >\(query.identifier ?? "query")
        \(query.sequence)
        ============================
        """)
    }

    private func printOutput(_ result: BLASTResult) {
        print("""

        ===== NCBI BLAST OUTPUT =====
        Program:  \(result.program.rawValue)
        Database: \(result.database)
        Hits:     \(result.hits.count)
        """)

        for (hitIndex, hit) in result.hits.enumerated() {
            print("""

            Hit \(hitIndex + 1): \(hit.identifier)
              Accession:  \(hit.accession ?? "not provided")
              Definition: \(hit.definition ?? "not provided")
              Length:     \(hit.sequenceLength)
            """)

            for (pairIndex, pair) in hit.highScoringPairs.enumerated() {
                let identityPercentage = pair.identity * 100
                print("""
                  HSP \(pairIndex + 1): bit score \(pair.bitScore), E-value \(pair.expectationValue)
                    Identity:      \(pair.identityCount)/\(pair.alignmentLength) (\(String(format: "%.1f", identityPercentage))%)
                    Query range:   \(pair.queryRange)
                    Subject range: \(pair.subjectRange)
                    Query:         \(pair.querySequence)
                    Subject:       \(pair.subjectSequence)
                """)
            }
        }

        print("=============================\n")
    }
}
