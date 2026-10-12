import BioSwift
import Foundation
import Testing
@testable import BioSwiftNetworking

@Suite("UniProt client")
struct UniProtClientTests {
    @Test("FASTA search returns records and pagination metadata")
    func fastaSearch() async throws {
        let data = Data("""
            >sp|P01009|A1AT_HUMAN Alpha-1-antitrypsin OS=Homo sapiens
            MPEPTIDE
            >tr|Q12345|EXAMPLE_MOUSE Example protein OS=Mus musculus
            ACDE
            """.utf8)
        let nextURL = "https://rest.uniprot.org/uniprotkb/search?format=fasta&cursor=next&size=2"
        let transport = RecordingTransport(responses: [HTTPResponse(
            data: data,
            statusCode: 200,
            headers: [
                "Link": "<\(nextURL)>; rel=\"next\"",
                "X-Total-Results": "12",
            ]
        )])
        let client = UniProtClient(transport: transport)

        let page = try await client.searchFasta(query: "albumin human", pageSize: 2)

        #expect(page.values.map(\.accession) == ["P01009", "Q12345"])
        #expect(page.totalResults == 12)
        #expect(page.nextPageToken != nil)

        let request = try #require(await transport.requests.first)
        let requestURL = try #require(request.url)
        let components = try #require(URLComponents(
            url: requestURL,
            resolvingAgainstBaseURL: false
        ))
        #expect(components.path == "/uniprotkb/search")
        #expect(components.queryItems?.first(where: { $0.name == "query" })?.value == "albumin human")
        #expect(components.queryItems?.first(where: { $0.name == "format" })?.value == "fasta")
        #expect(components.queryItems?.first(where: { $0.name == "size" })?.value == "2")
        #expect(request.value(forHTTPHeaderField: "Accept") == "text/plain")
    }

    @Test("Next-page searches use the server continuation URL")
    func nextPage() async throws {
        let nextURL = "https://rest.uniprot.org/uniprotkb/search?format=fasta&cursor=next&size=1"
        let transport = RecordingTransport(responses: [
            HTTPResponse(
                data: Data(">sp|P1|FIRST First\nAC\n".utf8),
                statusCode: 200,
                headers: ["Link": "<\(nextURL)>; rel=\"next\""]
            ),
            HTTPResponse(data: Data(">sp|P2|SECOND Second\nGT\n".utf8), statusCode: 200),
        ])
        let client = UniProtClient(transport: transport)

        let first = try await client.searchFasta(query: "protein", pageSize: 1)
        let token = try #require(first.nextPageToken)
        let second = try await client.searchFasta(nextPage: token)

        #expect(second.values.map(\.accession) == ["P2"])
        #expect(await transport.requests.last?.url?.absoluteString == nextURL)
    }

    @Test("Entry retrieval returns raw JSON without decoding it")
    func entryJSON() async throws {
        let data = Data(#"{"primaryAccession":"P01009"}"#.utf8)
        let transport = RecordingTransport(responses: [
            HTTPResponse(data: data, statusCode: 200)
        ])

        let result = try await UniProtClient(transport: transport).entryJSON(accession: "P01009")

        #expect(result == data)
        let request = try #require(await transport.requests.first)
        #expect(request.url?.absoluteString == "https://rest.uniprot.org/uniprotkb/P01009.json")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test("Version retrieval extracts the first TSV value")
    func version() async throws {
        let transport = RecordingTransport(responses: [
            HTTPResponse(data: Data("Entry version\n214\n".utf8), statusCode: 200)
        ])

        let version = try await UniProtClient(transport: transport).version(accession: "P01009")

        #expect(version == "214")
    }

    @Test("Empty searches and invalid page sizes are rejected")
    func invalidSearch() async {
        let client = UniProtClient(transport: RecordingTransport(responses: []))

        await #expect(throws: UniProtError.emptyQuery) {
            try await client.searchFasta(query: " ")
        }
        await #expect(throws: UniProtError.invalidPageSize(0)) {
            try await client.searchFasta(query: "protein", pageSize: 0)
        }
        await #expect(throws: UniProtError.invalidPageSize(501)) {
            try await client.searchFasta(query: "protein", pageSize: 501)
        }
    }

    @Test("Entry retrieval rejects empty accessions and empty bodies")
    func invalidEntry() async {
        let emptyTransport = RecordingTransport(responses: [
            HTTPResponse(data: Data(), statusCode: 200)
        ])
        let client = UniProtClient(transport: emptyTransport)

        await #expect(throws: UniProtError.emptyAccession) {
            try await client.entryJSON(accession: "\n")
        }
        await #expect(throws: UniProtError.emptyResponse) {
            try await client.entryJSON(accession: "P01009")
        }
    }

    @Test("Provider HTTP errors preserve their status and body")
    func httpFailure() async {
        let body = Data("not found".utf8)
        let transport = RecordingTransport(responses: [
            HTTPResponse(data: body, statusCode: 404)
        ])

        await #expect(
            throws: NetworkingError.unsuccessfulStatus(code: 404, responseBody: body)
        ) {
            try await UniProtClient(transport: transport).entryJSON(accession: "UNKNOWN")
        }
    }
}

private actor RecordingTransport: HTTPTransport {
    private var responses: [HTTPResponse]
    private(set) var requests: [URLRequest] = []

    init(responses: [HTTPResponse]) {
        self.responses = responses
    }

    func data(for request: URLRequest) async throws -> HTTPResponse {
        requests.append(request)
        guard !responses.isEmpty else {
            throw RecordingTransportError.missingResponse
        }
        return responses.removeFirst()
    }
}

private enum RecordingTransportError: Error {
    case missingResponse
}
