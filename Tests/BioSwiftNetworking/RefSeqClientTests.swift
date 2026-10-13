import BioSwift
import Foundation
import Testing
@testable import BioSwiftNetworking

@Suite("RefSeq client")
struct RefSeqClientTests {
    @Test("FASTA search uses ESearch and EFetch")
    func fastaSearch() async throws {
        let searchJSON = Data(#"{"esearchresult":{"count":"3","idlist":["NM_000546.6","NM_001126112.3"]}}"#.utf8)
        let fasta = Data("""
            >NM_000546.6 Homo sapiens tumor protein p53 (TP53), transcript variant 1, mRNA
            ACGT
            >NM_001126112.3 Homo sapiens tumor protein p53 (TP53), transcript variant 2, mRNA
            TGCA
            """.utf8)
        let transport = RefSeqRecordingTransport(responses: [
            HTTPResponse(data: searchJSON, statusCode: 200),
            HTTPResponse(data: fasta, statusCode: 200),
        ])
        let client = RefSeqClient(
            transport: transport,
            configuration: .init(tool: "BioSwift", email: "developer@example.com", apiKey: "secret")
        )

        let page = try await client.searchFasta(query: "TP53[gene]", database: .nucleotide, pageSize: 2)

        #expect(page.values.map(\.accession) == ["NM_000546.6", "NM_001126112.3"])
        #expect(page.totalResults == 3)
        #expect(page.nextPageToken != nil)
        let requests = await transport.requests
        #expect(requests.count == 2)
        let searchFields = queryFields(try #require(requests[0].url))
        #expect(requests[0].url?.host == "eutils.ncbi.nlm.nih.gov")
        #expect(requests[0].url?.path == "/entrez/eutils/esearch.fcgi")
        #expect(searchFields["db"] == "nuccore")
        #expect(searchFields["term"] == "(TP53[gene]) AND srcdb_refseq[prop]")
        #expect(searchFields["idtype"] == "acc")
        #expect(searchFields["retmax"] == "2")
        #expect(searchFields["retstart"] == "0")
        #expect(searchFields["tool"] == "BioSwift")
        #expect(searchFields["email"] == "developer@example.com")
        #expect(searchFields["api_key"] == "secret")
        let fetchFields = queryFields(try #require(requests[1].url))
        #expect(requests[1].url?.path == "/entrez/eutils/efetch.fcgi")
        #expect(fetchFields["id"] == "NM_000546.6,NM_001126112.3")
        #expect(fetchFields["rettype"] == "fasta")
        #expect(requests[1].value(forHTTPHeaderField: "Accept") == "text/plain")
    }

    @Test("Next-page search advances the ESearch offset")
    func nextPage() async throws {
        let firstSearch = Data(#"{"esearchresult":{"count":"2","idlist":["NP_000537.3"]}}"#.utf8)
        let secondSearch = Data(#"{"esearchresult":{"count":"2","idlist":["NP_001119584.1"]}}"#.utf8)
        let transport = RefSeqRecordingTransport(responses: [
            HTTPResponse(data: firstSearch, statusCode: 200),
            HTTPResponse(data: Data(">NP_000537.3 protein one\nMPEPTIDE\n".utf8), statusCode: 200),
            HTTPResponse(data: secondSearch, statusCode: 200),
            HTTPResponse(data: Data(">NP_001119584.1 protein two\nACDE\n".utf8), statusCode: 200),
        ])
        let client = RefSeqClient(transport: transport)

        let first = try await client.searchFasta(query: "TP53", database: .protein, pageSize: 1)
        let second = try await client.searchFasta(nextPage: #require(first.nextPageToken))

        #expect(second.values.map(\.accession) == ["NP_001119584.1"])
        #expect(second.nextPageToken == nil)
        let requests = await transport.requests
        #expect(queryFields(try #require(requests[2].url))["retstart"] == "1")
        #expect(queryFields(try #require(requests[2].url))["db"] == "protein")
    }

    @Test("Search terms are safely encoded as one query-item value")
    func queryEncoding() async throws {
        let transport = RefSeqRecordingTransport(responses: [
            HTTPResponse(
                data: Data(#"{"esearchresult":{"count":"0","idlist":[]}}"#.utf8),
                statusCode: 200
            )
        ])
        let query = #"BRCA1[gene] AND "Homo sapiens"[organism] & reviewed"#

        _ = try await RefSeqClient(transport: transport).searchFasta(
            query: query,
            database: .nucleotide
        )

        let request = try #require(await transport.requests.first)
        #expect(
            queryFields(try #require(request.url))["term"]
                == #"(BRCA1[gene] AND "Homo sapiens"[organism] & reviewed) AND srcdb_refseq[prop]"#
        )
    }

    @Test("Pagination ends when the server reports no remaining results")
    func paginationTermination() async throws {
        let transport = RefSeqRecordingTransport(responses: [
            HTTPResponse(
                data: Data(#"{"esearchresult":{"count":"1","idlist":["NP_000537.3"]}}"#.utf8),
                statusCode: 200
            ),
            HTTPResponse(
                data: Data(">NP_000537.3 cellular tumor antigen p53\nMPEPTIDE\n".utf8),
                statusCode: 200
            ),
        ])

        let page = try await RefSeqClient(transport: transport).searchFasta(
            query: "TP53",
            database: .protein,
            pageSize: 100
        )

        #expect(page.values.count == 1)
        #expect(page.totalResults == 1)
        #expect(page.nextPageToken == nil)
    }

    @Test("An empty search does not issue EFetch")
    func emptySearch() async throws {
        let transport = RefSeqRecordingTransport(responses: [
            HTTPResponse(
                data: Data(#"{"esearchresult":{"count":"0","idlist":[]}}"#.utf8),
                statusCode: 200
            )
        ])

        let page = try await RefSeqClient(transport: transport).searchFasta(
            query: "no matches",
            database: .nucleotide
        )

        #expect(page.values.isEmpty)
        #expect(page.totalResults == 0)
        #expect(page.nextPageToken == nil)
        #expect(await transport.requests.count == 1)
    }

    @Test("Exact FASTA retrieval parses one record")
    func exactFasta() async throws {
        let transport = RefSeqRecordingTransport(responses: [
            HTTPResponse(data: Data(">NC_000001.11 Homo sapiens chromosome 1\nACGT\n".utf8), statusCode: 200)
        ])

        let record = try await RefSeqClient(transport: transport).fasta(
            accession: " NC_000001.11 ",
            database: .nucleotide
        )

        #expect(record.accession == "NC_000001.11")
        let request = try #require(await transport.requests.first)
        #expect(queryFields(try #require(request.url))["id"] == "NC_000001.11")
    }

    @Test("Summary retrieval returns raw JSON")
    func summaryJSON() async throws {
        let data = Data(#"{"result":{"uids":["123"]}}"#.utf8)
        let transport = RefSeqRecordingTransport(responses: [HTTPResponse(data: data, statusCode: 200)])

        let result = try await RefSeqClient(transport: transport).summaryJSON(
            accession: "NP_000537.3",
            database: .protein
        )
        #expect(result == data)
        let request = try #require(await transport.requests.first)
        #expect(request.url?.path == "/entrez/eutils/esummary.fcgi")
        #expect(queryFields(try #require(request.url))["retmode"] == "json")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test("Nucleotide complete-record retrieval returns raw GBSeq XML")
    func nucleotideRecordXML() async throws {
        let xml = Data("<GBSet><GBSeq><GBSeq_locus>NM_000546</GBSeq_locus></GBSeq></GBSet>".utf8)
        let transport = RefSeqRecordingTransport(responses: [HTTPResponse(data: xml, statusCode: 200)])

        let result = try await RefSeqClient(transport: transport).recordXML(
            accession: " NM_000546.6 ",
            database: .nucleotide
        )

        #expect(result == xml)
        let request = try #require(await transport.requests.first)
        let fields = queryFields(try #require(request.url))
        #expect(request.url?.path == "/entrez/eutils/efetch.fcgi")
        #expect(fields["db"] == "nuccore")
        #expect(fields["id"] == "NM_000546.6")
        #expect(fields["rettype"] == "gb")
        #expect(fields["retmode"] == "xml")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/xml")
    }

    @Test("Protein complete-record retrieval accepts a selected FASTA record")
    func proteinRecordXMLFromFasta() async throws {
        let xml = Data("<GBSet><GBSeq><GBSeq_locus>NP_000537</GBSeq_locus></GBSeq></GBSet>".utf8)
        let transport = RefSeqRecordingTransport(responses: [HTTPResponse(data: xml, statusCode: 200)])
        let fastaRecord = try #require(
            try await FastaParser().parse(Data(">NP_000537.3 cellular tumor antigen p53\nMPEPTIDE\n".utf8)).first
        )

        let result = try await RefSeqClient(transport: transport).recordXML(
            for: fastaRecord,
            database: .protein
        )

        #expect(result == xml)
        let request = try #require(await transport.requests.first)
        let fields = queryFields(try #require(request.url))
        #expect(fields["db"] == "protein")
        #expect(fields["id"] == "NP_000537.3")
        #expect(fields["rettype"] == "gp")
        #expect(fields["retmode"] == "xml")
    }

    @Test("Invalid inputs are rejected before transport")
    func invalidInput() async {
        let client = RefSeqClient(transport: RefSeqRecordingTransport(responses: []))

        await #expect(throws: RefSeqError.emptyQuery) {
            try await client.searchFasta(query: " \n", database: .protein)
        }
        await #expect(throws: RefSeqError.invalidPageSize(0)) {
            try await client.searchFasta(query: "protein", database: .protein, pageSize: 0)
        }
        await #expect(throws: RefSeqError.invalidPageSize(501)) {
            try await client.searchFasta(query: "protein", database: .protein, pageSize: 501)
        }
        await #expect(throws: RefSeqError.emptyAccession) {
            try await client.fasta(accession: "", database: .nucleotide)
        }
    }

    @Test("Malformed searches, empty entries, and HTTP errors are preserved")
    func responseFailures() async {
        let malformed = RefSeqClient(transport: RefSeqRecordingTransport(responses: [
            HTTPResponse(data: Data(#"{"unexpected":true}"#.utf8), statusCode: 200)
        ]))
        await #expect(throws: RefSeqError.invalidSearchResponse) {
            try await malformed.searchFasta(query: "TP53", database: .protein)
        }

        let empty = RefSeqClient(transport: RefSeqRecordingTransport(responses: [
            HTTPResponse(data: Data(), statusCode: 200)
        ]))
        await #expect(throws: RefSeqError.emptyResponse) {
            try await empty.fasta(accession: "NP_000537.3", database: .protein)
        }

        let body = Data("too many requests".utf8)
        let failing = RefSeqClient(transport: RefSeqRecordingTransport(responses: [
            HTTPResponse(data: body, statusCode: 429)
        ]))
        await #expect(throws: NetworkingError.unsuccessfulStatus(code: 429, responseBody: body)) {
            try await failing.summaryJSON(accession: "NP_000537.3", database: .protein)
        }
    }

    @Test("Empty search and summary bodies produce typed errors")
    func emptyResponseBodies() async {
        let emptySearch = RefSeqClient(transport: RefSeqRecordingTransport(responses: [
            HTTPResponse(data: Data(), statusCode: 200)
        ]))
        await #expect(throws: RefSeqError.invalidSearchResponse) {
            try await emptySearch.searchFasta(query: "TP53", database: .protein)
        }

        let emptySummary = RefSeqClient(transport: RefSeqRecordingTransport(responses: [
            HTTPResponse(data: Data(), statusCode: 200)
        ]))
        await #expect(throws: RefSeqError.emptyResponse) {
            try await emptySummary.summaryJSON(accession: "NP_000537.3", database: .protein)
        }

        let emptyRecord = RefSeqClient(transport: RefSeqRecordingTransport(responses: [
            HTTPResponse(data: Data(), statusCode: 200)
        ]))
        await #expect(throws: RefSeqError.emptyResponse) {
            try await emptyRecord.recordXML(accession: "NP_000537.3", database: .protein)
        }
    }

    @Test("Exact FASTA retrieval requires exactly one record")
    func exactFastaCardinality() async {
        let fasta = Data("""
            >NP_000537.3 protein one
            MPEPTIDE
            >NP_001119584.1 protein two
            ACDE
            """.utf8)
        let client = RefSeqClient(transport: RefSeqRecordingTransport(responses: [
            HTTPResponse(data: fasta, statusCode: 200)
        ]))

        await #expect(throws: RefSeqError.unexpectedRecordCount(2)) {
            try await client.fasta(accession: "NP_000537.3", database: .protein)
        }
    }

    private func queryFields(_ url: URL) -> [String: String] {
        Dictionary(
            uniqueKeysWithValues: (URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? [])
                .compactMap { item in item.value.map { (item.name, $0) } }
        )
    }
}

private actor RefSeqRecordingTransport: HTTPTransport {
    private var responses: [HTTPResponse]
    private(set) var requests: [URLRequest] = []

    init(responses: [HTTPResponse]) {
        self.responses = responses
    }

    func data(for request: URLRequest) async throws -> HTTPResponse {
        requests.append(request)
        guard !responses.isEmpty else {
            throw RefSeqRecordingTransportError.missingResponse
        }
        return responses.removeFirst()
    }
}

private enum RefSeqRecordingTransportError: Error {
    case missingResponse
}
