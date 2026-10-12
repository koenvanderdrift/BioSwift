//
//  UniProtClient.swift
//  BioSwiftNetworking
//

import BioSwift
import Foundation

/// Errors produced while constructing or interpreting UniProt requests.
public enum UniProtError: Error, Equatable, Sendable {
    case emptyQuery
    case emptyAccession
    case invalidPageSize(Int)
    case invalidURL
    case invalidPageToken
    case emptyResponse
}

/// An opaque continuation returned with a paginated UniProt search.
public struct UniProtPageToken: Equatable, Sendable {
    fileprivate let url: URL
}

/// One page of values returned by UniProt.
public struct UniProtPage<Value: Sendable>: Sendable {
    public let values: [Value]
    public let nextPageToken: UniProtPageToken?
    public let totalResults: Int?

    public init(
        values: [Value],
        nextPageToken: UniProtPageToken?,
        totalResults: Int?
    ) {
        self.values = values
        self.nextPageToken = nextPageToken
        self.totalResults = totalResults
    }
}

extension UniProtPage: Equatable where Value: Equatable {}

/// Retrieves lightweight FASTA search results and raw UniProt entry JSON.
///
/// JSON schema decoding remains the caller's responsibility. The client is stateless;
/// pagination is represented by the opaque token returned with each FASTA page.
public struct UniProtClient: Sendable {
    private let transport: any HTTPTransport

    public init(transport: any HTTPTransport = URLSessionTransport()) {
        self.transport = transport
    }

    /// Searches UniProtKB and parses one page of lightweight FASTA records.
    public func searchFasta(
        query: String,
        pageSize: Int = 100
    ) async throws -> UniProtPage<FastaRecord> {
        guard query.contains(where: { !$0.isWhitespace }) else {
            throw UniProtError.emptyQuery
        }
        guard (1...500).contains(pageSize) else {
            throw UniProtError.invalidPageSize(pageSize)
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = Self.host
        components.path = "/uniprotkb/search"
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "format", value: "fasta"),
            URLQueryItem(name: "size", value: String(pageSize)),
        ]
        guard let url = components.url else {
            throw UniProtError.invalidURL
        }

        return try await fastaPage(from: url)
    }

    /// Retrieves the next page represented by a previous search result.
    public func searchFasta(
        nextPage pageToken: UniProtPageToken
    ) async throws -> UniProtPage<FastaRecord> {
        guard Self.isAllowedPageURL(pageToken.url) else {
            throw UniProtError.invalidPageToken
        }
        return try await fastaPage(from: pageToken.url)
    }

    /// Retrieves the complete JSON representation of one UniProtKB entry.
    /// The returned data is not decoded by BioSwiftNetworking.
    public func entryJSON(accession: String) async throws -> Data {
        let accession = accession.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !accession.isEmpty else {
            throw UniProtError.emptyAccession
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = Self.host
        components.path = "/uniprotkb/\(accession).json"
        guard let url = components.url else {
            throw UniProtError.invalidURL
        }

        let response = try await response(for: url, accepting: "application/json")
        guard !response.data.isEmpty else {
            throw UniProtError.emptyResponse
        }
        return response.data
    }

    /// Retrieves the current entry version, or `nil` when a successful response has no value.
    public func version(accession: String) async throws -> String? {
        let accession = accession.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !accession.isEmpty else {
            throw UniProtError.emptyAccession
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = Self.host
        components.path = "/uniprotkb/stream"
        components.queryItems = [
            URLQueryItem(name: "fields", value: "version"),
            URLQueryItem(name: "format", value: "tsv"),
            URLQueryItem(name: "query", value: "(accession:\(accession))"),
        ]
        guard let url = components.url else {
            throw UniProtError.invalidURL
        }

        let response = try await response(for: url, accepting: "text/tab-separated-values")
        guard let text = String(data: response.data, encoding: .utf8) else {
            throw UniProtError.emptyResponse
        }

        return text.split(whereSeparator: \.isNewline).dropFirst().first.map(String.init)
    }

    private func fastaPage(from url: URL) async throws -> UniProtPage<FastaRecord> {
        let response = try await response(for: url, accepting: "text/plain")
        let values: [FastaRecord]
        if response.data.isEmpty {
            values = []
        } else {
            values = try await FastaParser().parse(response.data)
        }

        return UniProtPage(
            values: values,
            nextPageToken: Self.nextPageToken(from: response.value(forHeaderField: "Link")),
            totalResults: response.value(forHeaderField: "X-Total-Results").flatMap(Int.init)
        )
    }

    private func response(for url: URL, accepting contentType: String) async throws -> HTTPResponse {
        var request = URLRequest(url: url)
        request.setValue(contentType, forHTTPHeaderField: "Accept")
        return try await transport.data(for: request).validated()
    }

    private static func nextPageToken(from linkHeader: String?) -> UniProtPageToken? {
        guard let linkHeader else { return nil }

        for value in linkHeader.split(separator: ",") {
            let parts = value.split(separator: ";", omittingEmptySubsequences: true)
            guard let reference = parts.first?.trimmingCharacters(in: .whitespaces),
                reference.hasPrefix("<"), reference.hasSuffix(">"),
                parts.dropFirst().contains(where: {
                    $0.trimmingCharacters(in: .whitespaces)
                        .lowercased() == "rel=\"next\""
                }),
                let url = URL(string: String(reference.dropFirst().dropLast())),
                isAllowedPageURL(url)
            else {
                continue
            }
            return UniProtPageToken(url: url)
        }
        return nil
    }

    private static func isAllowedPageURL(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "https"
            && url.host?.lowercased() == host
            && url.path == "/uniprotkb/search"
    }

    private static let host = "rest.uniprot.org"
}
