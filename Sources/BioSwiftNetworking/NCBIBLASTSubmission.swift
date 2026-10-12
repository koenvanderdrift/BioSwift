//
//  NCBIBLASTSubmission.swift
//  BioSwiftNetworking
//

import BioSwift
import Foundation

/// A persistent handle for a search submitted to NCBI BLAST.
///
/// Store this value if polling may be cancelled. The same search can later be
/// resumed with ``NCBIBLASTClient/result(for:)`` without submitting it again.
public struct NCBIBLASTSubmission: Codable, Equatable, Sendable {
    public let requestIdentifier: String
    public let estimatedCompletionTime: Duration
    public let submittedAt: Date
    public let query: BLASTQuery
    public let configuration: BLASTConfiguration

    public init(
        requestIdentifier: String,
        estimatedCompletionTime: Duration,
        submittedAt: Date,
        query: BLASTQuery,
        configuration: BLASTConfiguration
    ) {
        self.requestIdentifier = requestIdentifier
        self.estimatedCompletionTime = estimatedCompletionTime
        self.submittedAt = submittedAt
        self.query = query
        self.configuration = configuration
    }
}

/// The server-side state of an NCBI BLAST request.
public enum NCBIBLASTStatus: Equatable, Sendable {
    case waiting
    case ready(hasHits: Bool)
    case failed(message: String?)
    case expired
}

/// Progress emitted while an NCBI BLAST request is submitted and polled.
public enum NCBIBLASTEvent: Equatable, Sendable {
    case submitted(requestIdentifier: String, estimatedCompletionTime: Duration)
    case polling(requestIdentifier: String, attempt: Int, elapsed: Duration)
    case status(requestIdentifier: String, status: NCBIBLASTStatus, elapsed: Duration)
    case retrieving(requestIdentifier: String, elapsed: Duration)
}

extension NCBIBLASTEvent: CustomStringConvertible {
    public var description: String {
        switch self {
        case .submitted(let identifier, let estimate):
            return "NCBI BLAST submitted RID \(identifier) (estimated completion: \(estimate))"
        case .polling(let identifier, let attempt, let elapsed):
            return "NCBI BLAST polling RID \(identifier), attempt \(attempt), elapsed \(elapsed)"
        case .status(let identifier, let status, let elapsed):
            return "NCBI BLAST RID \(identifier) status: \(status.description), elapsed \(elapsed)"
        case .retrieving(let identifier, let elapsed):
            return "NCBI BLAST retrieving RID \(identifier), elapsed \(elapsed)"
        }
    }
}

private extension NCBIBLASTStatus {
    var description: String {
        switch self {
        case .waiting:
            return "WAITING"
        case .ready(let hasHits):
            return hasHits ? "READY (hits found)" : "READY (no hits)"
        case .failed(let message):
            return message.map { "FAILED (\($0))" } ?? "FAILED"
        case .expired:
            return "UNKNOWN/EXPIRED"
        }
    }
}
