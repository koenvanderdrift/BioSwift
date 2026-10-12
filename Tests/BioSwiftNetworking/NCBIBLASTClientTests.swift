import BioSwift
import Foundation
import Testing
@testable import BioSwiftNetworking

@Suite("NCBI BLAST client")
struct NCBIBLASTClientTests {
    @Test("A completed blastn search maps submission and JSON2 results")
    func completedSearch() async throws {
        let transport = BLASTRecordingTransport(responses: [
            HTTPResponse(data: submissionData(rtoe: 12), statusCode: 200),
            HTTPResponse(data: readyData, statusCode: 200),
            HTTPResponse(data: blastnResultData, statusCode: 200),
        ])
        let sleeper = RecordingPollingSleeper()
        let client = try NCBIBLASTClient(
            email: "researcher@example.org",
            tool: "BioSwiftTests",
            transport: transport,
            pollingPolicy: .ncbiDefault,
            sleeper: sleeper
        )
        let query = try BLASTQuery(identifier: "query-1", sequence: "ACGT")
        let configuration = try BLASTConfiguration(
            program: .blastn,
            database: "core_nt",
            expectationValue: 0.001,
            maximumHits: 25,
            filtersLowComplexityRegions: false
        )

        let result = try await client.search(query: query, configuration: configuration)

        #expect(result.program == .blastn)
        #expect(result.database == "core_nt")
        #expect(result.hits.count == 1)
        let hit = try #require(result.hits.first)
        #expect(hit.identifier == "ref|ABC123.1|")
        #expect(hit.accession == "ABC123")
        let pair = try #require(hit.highScoringPairs.first)
        #expect(pair.queryRange == 0..<4)
        #expect(pair.subjectRange == 28..<32)
        #expect(pair.queryStrand == .plus)
        #expect(pair.subjectStrand == .minus)
        #expect(pair.identityCount == 3)
        #expect(pair.positiveCount == 3)

        #expect(await sleeper.durations == [.seconds(60)])
        let requests = await transport.requests
        #expect(requests.count == 3)
        let submission = try #require(requests.first)
        #expect(submission.httpMethod == "POST")
        let fields = formFields(in: try #require(submission.httpBody))
        #expect(fields["CMD"] == "Put")
        #expect(fields["QUERY"] == ">query-1\nACGT")
        #expect(fields["DATABASE"] == "core_nt")
        #expect(fields["PROGRAM"] == "blastn")
        #expect(fields["EXPECT"] == "0.001")
        #expect(fields["HITLIST_SIZE"] == "25")
        #expect(fields["FILTER"] == "F")
        #expect(fields["EMAIL"] == "researcher@example.org")
        #expect(fields["TOOL"] == "BioSwiftTests")

        let statusURL = try #require(requests[1].url)
        let status = try #require(URLComponents(
            url: statusURL,
            resolvingAgainstBaseURL: false
        ))
        #expect(status.queryItems?.first(where: { $0.name == "RID" })?.value == "TEST-RID")
        #expect(status.queryItems?.first(where: { $0.name == "FORMAT_OBJECT" })?.value == "SearchInfo")
        #expect(status.queryItems?.contains(where: { $0.name == "FORMAT_TYPE" }) == false)

        let retrievalURL = try #require(requests[2].url)
        let retrieval = try #require(URLComponents(
            url: retrievalURL,
            resolvingAgainstBaseURL: false
        ))
        #expect(retrieval.queryItems?.first(where: { $0.name == "RID" })?.value == "TEST-RID")
        #expect(retrieval.queryItems?.first(where: { $0.name == "FORMAT_TYPE" })?.value == "JSON2_S")
        #expect(retrieval.queryItems?.contains(where: { $0.name == "FORMAT_OBJECT" }) == false)
    }

    @Test("Waiting searches sleep before polling again")
    func waitingSearch() async throws {
        let transport = BLASTRecordingTransport(responses: [
            HTTPResponse(data: submissionData(), statusCode: 200),
            HTTPResponse(data: Data("Status=WAITING\n".utf8), statusCode: 200),
            HTTPResponse(data: readyData, statusCode: 200),
            HTTPResponse(data: blastnResultData, statusCode: 200),
        ])
        let sleeper = RecordingPollingSleeper()
        let client = try NCBIBLASTClient(
            email: "researcher@example.org",
            tool: "BioSwiftTests",
            transport: transport,
            pollingPolicy: .ncbiDefault,
            sleeper: sleeper
        )

        _ = try await client.search(
            query: try BLASTQuery(sequence: "ACGT"),
            configuration: try BLASTConfiguration(program: .blastn, database: "core_nt")
        )

        #expect(await sleeper.durations == [.seconds(60), .seconds(60)])
    }

    @Test("A waiting search times out at its attempt limit")
    func pollingTimeout() async throws {
        let transport = BLASTRecordingTransport(responses: [
            HTTPResponse(data: submissionData(), statusCode: 200),
            HTTPResponse(data: Data("Status=WAITING\n".utf8), statusCode: 200),
        ])
        let policy = try NCBIBLASTPollingPolicy(maximumAttempts: 1)
        let client = try NCBIBLASTClient(
            email: "researcher@example.org",
            tool: "BioSwiftTests",
            transport: transport,
            pollingPolicy: policy,
            sleeper: RecordingPollingSleeper()
        )

        await #expect(throws: NCBIBLASTError.pollingTimedOut) {
            try await client.search(
                query: BLASTQuery(sequence: "ACGT"),
                configuration: BLASTConfiguration(program: .blastn, database: "core_nt")
            )
        }
    }

    @Test("Failed and expired requests produce typed errors", arguments: [
        ("Status=FAILED\nMessage=Invalid database\n", NCBIBLASTError.searchFailed("Invalid database")),
        ("Status=UNKNOWN\n", NCBIBLASTError.requestExpired),
    ])
    func unsuccessfulStatus(text: String, expectedError: NCBIBLASTError) async throws {
        let transport = BLASTRecordingTransport(responses: [
            HTTPResponse(data: submissionData(), statusCode: 200),
            HTTPResponse(data: Data(text.utf8), statusCode: 200),
        ])
        let client = try NCBIBLASTClient(
            email: "researcher@example.org",
            transport: transport,
            sleeper: RecordingPollingSleeper()
        )

        await #expect(throws: expectedError) {
            try await client.search(
                query: BLASTQuery(sequence: "ACGT"),
                configuration: BLASTConfiguration(program: .blastn, database: "core_nt")
            )
        }
    }

    @Test("Client identification is required")
    func identification() {
        #expect(throws: NCBIBLASTError.emptyEmail) {
            try NCBIBLASTClient(email: " ")
        }
        #expect(throws: NCBIBLASTError.emptyToolName) {
            try NCBIBLASTClient(email: "researcher@example.org", tool: "")
        }
    }

    @Test("A persisted submission resumes without being submitted again")
    func resumeSubmission() async throws {
        let transport = BLASTRecordingTransport(responses: [
            HTTPResponse(data: readyData, statusCode: 200),
            HTTPResponse(data: blastnResultData, statusCode: 200),
        ])
        let client = try NCBIBLASTClient(
            email: "researcher@example.org",
            transport: transport,
            sleeper: RecordingPollingSleeper()
        )
        let submission = NCBIBLASTSubmission(
            requestIdentifier: "SAVED-RID",
            estimatedCompletionTime: .zero,
            submittedAt: .distantPast,
            query: try BLASTQuery(identifier: "query-1", sequence: "ACGT"),
            configuration: try BLASTConfiguration(program: .blastn, database: "core_nt")
        )

        let encoded = try JSONEncoder().encode(submission)
        let restored = try JSONDecoder().decode(NCBIBLASTSubmission.self, from: encoded)
        let result = try await client.result(for: restored)

        #expect(result.hits.count == 1)
        let requests = await transport.requests
        #expect(requests.count == 2)
        #expect(requests.allSatisfy { $0.httpMethod != "POST" })
        #expect(requests.allSatisfy { $0.url?.absoluteString.contains("SAVED-RID") == true })
    }

    private func submissionData(rtoe: Int = 5) -> Data {
        Data("RID = TEST-RID\nRTOE = \(rtoe)\n".utf8)
    }

    private var readyData: Data {
        Data("Status=READY\nThereAreHits=yes\n".utf8)
    }

    private func formFields(in data: Data) -> [String: String] {
        var components = URLComponents()
        components.percentEncodedQuery = String(decoding: data, as: UTF8.self)
        return Dictionary(
            components.queryItems?.compactMap { item in
                item.value.map { (item.name, $0) }
            } ?? [],
            uniquingKeysWith: { _, latest in latest }
        )
    }

    private var blastnResultData: Data {
        Data(#"""
        {
          "BlastOutput2": {
            "report": {
              "program": "blastn",
              "search_target": { "db": "core_nt" },
              "results": {
                "search": {
                  "query_id": "query-1",
                  "query_len": 4,
                  "hits": [
                    {
                      "num": 1,
                      "description": [
                        {
                          "id": "ref|ABC123.1|",
                          "accession": "ABC123",
                          "title": "Example nucleotide"
                        }
                      ],
                      "len": 100,
                      "hsps": [
                        {
                          "num": 1,
                          "bit_score": 12.5,
                          "score": 18,
                          "evalue": 0.0001,
                          "identity": 3,
                          "query_from": 1,
                          "query_to": 4,
                          "query_strand": "Plus",
                          "hit_from": 32,
                          "hit_to": 29,
                          "hit_strand": "Minus",
                          "align_len": 4,
                          "gaps": 0,
                          "qseq": "ACGT",
                          "hseq": "ACCT"
                        }
                      ]
                    }
                  ]
                }
              }
            }
          }
        }
        """#.utf8)
    }
}

private actor BLASTRecordingTransport: HTTPTransport {
    private var responses: [HTTPResponse]
    private(set) var requests: [URLRequest] = []

    init(responses: [HTTPResponse]) {
        self.responses = responses
    }

    func data(for request: URLRequest) async throws -> HTTPResponse {
        requests.append(request)
        guard !responses.isEmpty else {
            throw BLASTTestError.missingResponse
        }
        return responses.removeFirst()
    }
}

private actor RecordingPollingSleeper: BLASTPollingSleeper {
    private(set) var durations: [Duration] = []

    func sleep(for duration: Duration) async throws {
        durations.append(duration)
    }
}

private enum BLASTTestError: Error {
    case missingResponse
}
