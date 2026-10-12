//
//  BLASTPolling.swift
//  BioSwiftNetworking
//

import Foundation

/// Controls how frequently an NCBI BLAST request is checked for completion.
public struct NCBIBLASTPollingPolicy: Equatable, Sendable {
    /// The delay between requests for the same NCBI request identifier.
    public let interval: Duration

    /// The maximum number of result-retrieval attempts after submission.
    public let maximumAttempts: Int

    /// NCBI's minimum polling interval with a thirty-attempt limit.
    public static let ncbiDefault = NCBIBLASTPollingPolicy(
        interval: .seconds(60),
        maximumAttempts: 30,
        validated: ()
    )

    public init(
        interval: Duration = .seconds(60),
        maximumAttempts: Int = 30
    ) throws {
        guard interval >= .seconds(60) else {
            throw NCBIBLASTError.pollingIntervalTooShort(interval)
        }
        guard maximumAttempts > 0 else {
            throw NCBIBLASTError.invalidMaximumPollingAttempts(maximumAttempts)
        }

        self.interval = interval
        self.maximumAttempts = maximumAttempts
    }

    private init(interval: Duration, maximumAttempts: Int, validated: Void) {
        self.interval = interval
        self.maximumAttempts = maximumAttempts
    }
}

/// Injectable suspension used to make the NCBI polling loop deterministic in tests.
protocol BLASTPollingSleeper: Sendable {
    func sleep(for duration: Duration) async throws
}

/// Production polling suspension based on a monotonic clock.
struct ContinuousBLASTPollingSleeper: BLASTPollingSleeper {
    func sleep(for duration: Duration) async throws {
        try await ContinuousClock().sleep(for: duration)
    }
}
