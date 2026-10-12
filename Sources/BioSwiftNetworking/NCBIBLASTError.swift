//
//  NCBIBLASTError.swift
//  BioSwiftNetworking
//

import Foundation

/// Errors produced by the NCBI BLAST service adapter.
public enum NCBIBLASTError: Error, Equatable, Sendable {
    case emptyEmail
    case emptyToolName
    case concurrentSearch

    case pollingIntervalTooShort(Duration)
    case invalidMaximumPollingAttempts(Int)
    case pollingTimedOut

    case missingRequestIdentifier
    case invalidEstimatedCompletionTime(String)
    case malformedSubmissionResponse

    case searchFailed(String?)
    case requestExpired
    case malformedResult(String)
}
