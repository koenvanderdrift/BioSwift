//
//  RefSeqClient.swift
//  BioSwiftNetworking
//

import BioSwift
import Foundation

/// The NCBI Entrez sequence database queried by ``RefSeqClient``.
public enum RefSeqDatabase: String, CaseIterable, Sendable {
    case nucleotide = "nuccore"
    case protein
}

/// Errors produced while constructing or interpreting RefSeq requests.
public enum RefSeqError: Error, Equatable, Sendable {
    case emptyQuery
    case emptyAccession
    case invalidPageSize(Int)
    case invalidURL
    case invalidPageToken
    case invalidSearchResponse
    case emptyResponse
    case unexpectedRecordCount(Int)
}

/// An opaque continuation returned with a paginated RefSeq search.
public struct RefSeqPageToken: Equatable, Sendable {
    fileprivate let query: String
    fileprivate let database: RefSeqDatabase
    fileprivate let pageSize: Int
    fileprivate let offset: Int
}

/// One page of values returned by a RefSeq search.
public struct RefSeqPage<Value: Sendable>: Sendable {
    public let values: [Value]
    public let nextPageToken: RefSeqPageToken?
    public let totalResults: Int

    public init(
        values: [Value],
        nextPageToken: RefSeqPageToken?,
        totalResults: Int
    ) {
        self.values = values
        self.nextPageToken = nextPageToken
        self.totalResults = totalResults
    }
}

extension RefSeqPage: Equatable where Value: Equatable {}

/// Retrieves RefSeq nucleotide and protein sequences through NCBI E-utilities.
///
/// The client is stateless and uses an injected transport. Searches are restricted to
/// RefSeq records and require an ESearch request followed by EFetch when matches exist.
public struct RefSeqClient: Sendable {
    /// Optional identification and authentication values sent to NCBI E-utilities.
    public struct Configuration: Equatable, Sendable {
        public let tool: String?
        public let email: String?
        public let apiKey: String?

        public init(tool: String? = nil, email: String? = nil, apiKey: String? = nil) {
            self.tool = tool
            self.email = email
            self.apiKey = apiKey
        }
    }

    private let transport: any HTTPTransport
    private let configuration: Configuration

    public init(
        transport: any HTTPTransport = URLSessionTransport(),
        configuration: Configuration = Configuration()
    ) {
        self.transport = transport
        self.configuration = configuration
    }

    /// Searches RefSeq and parses one page of FASTA records.
    public func searchFasta(
        query: String,
        database: RefSeqDatabase,
        pageSize: Int = 100
    ) async throws -> RefSeqPage<FastaRecord> {
        guard query.contains(where: { !$0.isWhitespace }) else {
            throw RefSeqError.emptyQuery
        }
        guard (1...500).contains(pageSize) else {
            throw RefSeqError.invalidPageSize(pageSize)
        }

        return try await fastaPage(
            query: query,
            database: database,
            pageSize: pageSize,
            offset: 0
        )
    }

    /// Retrieves the next page represented by a previous search result.
    public func searchFasta(
        nextPage pageToken: RefSeqPageToken
    ) async throws -> RefSeqPage<FastaRecord> {
        guard pageToken.query.contains(where: { !$0.isWhitespace }),
              (1...500).contains(pageToken.pageSize),
              pageToken.offset > 0
        else {
            throw RefSeqError.invalidPageToken
        }

        return try await fastaPage(
            query: pageToken.query,
            database: pageToken.database,
            pageSize: pageToken.pageSize,
            offset: pageToken.offset
        )
    }

    /// Retrieves and parses one RefSeq FASTA record by accession.
    public func fasta(
        accession: String,
        database: RefSeqDatabase
    ) async throws -> FastaRecord {
        let accession = accession.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !accession.isEmpty else {
            throw RefSeqError.emptyAccession
        }

        let data = try await fetchFasta(identifiers: [accession], database: database)
        guard !data.isEmpty else {
            throw RefSeqError.emptyResponse
        }
        let records = try await FastaParser().parse(data)
        guard records.count == 1, let record = records.first else {
            throw RefSeqError.unexpectedRecordCount(records.count)
        }
        return record
    }

    /// Retrieves the complete annotated NCBI sequence record as raw XML.
    ///
    /// Nucleotide records use GBSeq XML and protein records use GenPept GBSeq XML.
    /// The returned data is not decoded by BioSwiftNetworking.
    public func recordXML(
        accession: String,
        database: RefSeqDatabase
    ) async throws -> Data {
        let accession = accession.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !accession.isEmpty else {
            throw RefSeqError.emptyAccession
        }

        let retrievalType = switch database {
        case .nucleotide: "gb"
        case .protein: "gp"
        }
        let url = try url(path: "/entrez/eutils/efetch.fcgi", queryItems: [
            URLQueryItem(name: "db", value: database.rawValue),
            URLQueryItem(name: "id", value: accession),
            URLQueryItem(name: "rettype", value: retrievalType),
            URLQueryItem(name: "retmode", value: "xml"),
        ])
        let data = try await response(for: url, accepting: "application/xml").data
        guard !data.isEmpty else {
            throw RefSeqError.emptyResponse
        }
        return data
    }

    /// Retrieves the complete annotated XML record for a selected FASTA result.
    public func recordXML(
        for record: FastaRecord,
        database: RefSeqDatabase
    ) async throws -> Data {
        try await recordXML(accession: record.accession, database: database)
    }

    /// Retrieves the raw ESummary JSON for one RefSeq accession.
    public func summaryJSON(
        accession: String,
        database: RefSeqDatabase
    ) async throws -> Data {
        let accession = accession.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !accession.isEmpty else {
            throw RefSeqError.emptyAccession
        }

        let url = try url(path: "/entrez/eutils/esummary.fcgi", queryItems: [
            URLQueryItem(name: "db", value: database.rawValue),
            URLQueryItem(name: "id", value: accession),
            URLQueryItem(name: "retmode", value: "json"),
        ])
        let data = try await response(for: url, accepting: "application/json").data
        guard !data.isEmpty else {
            throw RefSeqError.emptyResponse
        }
        return data
    }

    private func fastaPage(
        query: String,
        database: RefSeqDatabase,
        pageSize: Int,
        offset: Int
    ) async throws -> RefSeqPage<FastaRecord> {
        let result = try await search(
            query: query,
            database: database,
            pageSize: pageSize,
            offset: offset
        )
        let values: [FastaRecord]
        if result.identifiers.isEmpty {
            values = []
        } else {
            let data = try await fetchFasta(identifiers: result.identifiers, database: database)
            values = data.isEmpty ? [] : try await FastaParser().parse(data)
        }

        let nextOffset = offset + result.identifiers.count
        let token = nextOffset < result.totalResults && !result.identifiers.isEmpty
            ? RefSeqPageToken(
                query: query,
                database: database,
                pageSize: pageSize,
                offset: nextOffset
            )
            : nil
        return RefSeqPage(values: values, nextPageToken: token, totalResults: result.totalResults)
    }

    private func search(
        query: String,
        database: RefSeqDatabase,
        pageSize: Int,
        offset: Int
    ) async throws -> SearchResult {
        let url = try url(path: "/entrez/eutils/esearch.fcgi", queryItems: [
            URLQueryItem(name: "db", value: database.rawValue),
            URLQueryItem(name: "term", value: "(\(query)) AND srcdb_refseq[prop]"),
            URLQueryItem(name: "retmode", value: "json"),
            URLQueryItem(name: "idtype", value: "acc"),
            URLQueryItem(name: "retmax", value: String(pageSize)),
            URLQueryItem(name: "retstart", value: String(offset)),
        ])
        let data = try await response(for: url, accepting: "application/json").data
        guard !data.isEmpty else {
            throw RefSeqError.invalidSearchResponse
        }

        do {
            let response = try JSONDecoder().decode(ESearchResponse.self, from: data)
            guard let totalResults = Int(response.esearchresult.count) else {
                throw RefSeqError.invalidSearchResponse
            }
            return SearchResult(
                identifiers: response.esearchresult.idlist,
                totalResults: totalResults
            )
        } catch let error as RefSeqError {
            throw error
        } catch {
            throw RefSeqError.invalidSearchResponse
        }
    }

    private func fetchFasta(
        identifiers: [String],
        database: RefSeqDatabase
    ) async throws -> Data {
        let url = try url(path: "/entrez/eutils/efetch.fcgi", queryItems: [
            URLQueryItem(name: "db", value: database.rawValue),
            URLQueryItem(name: "id", value: identifiers.joined(separator: ",")),
            URLQueryItem(name: "rettype", value: "fasta"),
            URLQueryItem(name: "retmode", value: "text"),
        ])
        return try await response(for: url, accepting: "text/plain").data
    }

    private func url(path: String, queryItems: [URLQueryItem]) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = Self.host
        components.path = path
        components.queryItems = queryItems + configurationQueryItems
        guard let url = components.url else {
            throw RefSeqError.invalidURL
        }
        return url
    }

    private var configurationQueryItems: [URLQueryItem] {
        [
            configuration.tool.map { URLQueryItem(name: "tool", value: $0) },
            configuration.email.map { URLQueryItem(name: "email", value: $0) },
            configuration.apiKey.map { URLQueryItem(name: "api_key", value: $0) },
        ].compactMap { $0 }
    }

    private func response(for url: URL, accepting contentType: String) async throws -> HTTPResponse {
        var request = URLRequest(url: url)
        request.setValue(contentType, forHTTPHeaderField: "Accept")
        return try await transport.data(for: request).validated()
    }

    private static let host = "eutils.ncbi.nlm.nih.gov"
}

private struct SearchResult {
    let identifiers: [String]
    let totalResults: Int
}

private struct ESearchResponse: Decodable {
    let esearchresult: ESearchResult
}

private struct ESearchResult: Decodable {
    let count: String
    let idlist: [String]
}
