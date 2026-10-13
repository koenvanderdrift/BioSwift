//
//  NCBIBLASTWebRequest.swift
//  BioSwiftNetworking
//

import BioSwift
import Foundation

/// A prefilled NCBI BLAST webpage request for handoff to a web browser.
///
/// This value does not submit a search. Applications remain responsible for
/// displaying a privacy notice and opening `url` after an explicit user action.
public struct NCBIBLASTWebRequest: Equatable, Sendable {
    /// A conservative limit for a URL handed to an external browser.
    public static let maximumURLLength = 8_000

    public let query: BLASTQuery
    public let configuration: BLASTConfiguration
    public let url: URL

    public init(query: BLASTQuery, configuration: BLASTConfiguration) throws {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "blast.ncbi.nlm.nih.gov"
        components.path = "/Blast.cgi"
        components.queryItems = Self.queryItems(query: query, configuration: configuration)

        guard let url = components.url else {
            throw NCBIBLASTWebRequestError.cannotConstructURL
        }
        guard url.absoluteString.utf8.count <= Self.maximumURLLength else {
            throw NCBIBLASTWebRequestError.urlTooLong(
                actual: url.absoluteString.utf8.count,
                maximum: Self.maximumURLLength
            )
        }

        self.query = query
        self.configuration = configuration
        self.url = url
    }

    private static func queryItems(
        query: BLASTQuery,
        configuration: BLASTConfiguration
    ) -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "PAGE_TYPE", value: "BlastSearch"),
            URLQueryItem(name: "PAGE", value: page(for: configuration.program)),
            URLQueryItem(name: "PROGRAM", value: configuration.program.rawValue),
            URLQueryItem(name: "BLAST_PROGRAMS", value: configuration.program.rawValue),
            URLQueryItem(name: "QUERY", value: fasta(query)),
            URLQueryItem(name: "DATABASE", value: configuration.database),
            URLQueryItem(name: "EXPECT", value: String(configuration.expectationValue)),
            URLQueryItem(name: "HITLIST_SIZE", value: String(configuration.maximumHits)),
            URLQueryItem(
                name: "FILTER",
                value: configuration.filtersLowComplexityRegions ? "T" : "F"
            ),
        ]

        if let matrix = configuration.substitutionMatrix {
            items.append(URLQueryItem(name: "MATRIX", value: matrix))
        }
        if let wordSize = configuration.wordSize {
            items.append(URLQueryItem(name: "WORD_SIZE", value: String(wordSize)))
        }
        if let adjusts = configuration.adjustsForShortQuery {
            items.append(URLQueryItem(name: "SHORT_QUERY_ADJUST", value: String(adjusts)))
        }
        if let reward = configuration.nucleotideMatchReward {
            items.append(URLQueryItem(name: "NUCL_REWARD", value: String(reward)))
        }
        if let penalty = configuration.nucleotideMismatchPenalty {
            items.append(URLQueryItem(name: "NUCL_PENALTY", value: String(penalty)))
        }
        if let identifier = query.identifier {
            items.append(URLQueryItem(name: "JOB_TITLE", value: sanitized(identifier)))
        }

        return items
    }

    private static func page(for program: BLASTProgram) -> String {
        switch program {
        case .blastn:
            return "Nucleotides"
        case .blastp:
            return "Proteins"
        case .blastx, .tblastn, .tblastx:
            return "Translations"
        }
    }

    private static func fasta(_ query: BLASTQuery) -> String {
        guard let identifier = query.identifier else { return query.sequence }
        return ">\(sanitized(identifier))\n\(query.sequence)"
    }

    private static func sanitized(_ identifier: String) -> String {
        identifier
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
    }
}

public enum NCBIBLASTWebRequestError: Error, Equatable, Sendable {
    case cannotConstructURL
    case urlTooLong(actual: Int, maximum: Int)
}
