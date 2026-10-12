//
//  NCBIBLASTClient.swift
//  BioSwiftNetworking
//

import BioSwift
import Foundation

/// Searches NCBI-hosted BLAST databases through the Common URL API.
public actor NCBIBLASTClient: BLASTSearching {
    private let email: String
    private let tool: String
    private let transport: any HTTPTransport
    private let pollingPolicy: NCBIBLASTPollingPolicy
    private let sleeper: any BLASTPollingSleeper
    private let eventHandler: @Sendable (NCBIBLASTEvent) -> Void

    private var isSearching = false

    public init(
        email: String,
        tool: String = "BioSwift",
        transport: any HTTPTransport = URLSessionTransport(),
        pollingPolicy: NCBIBLASTPollingPolicy = .ncbiDefault,
        eventHandler: @escaping @Sendable (NCBIBLASTEvent) -> Void = { _ in }
    ) throws {
        try self.init(
            email: email,
            tool: tool,
            transport: transport,
            pollingPolicy: pollingPolicy,
            sleeper: ContinuousBLASTPollingSleeper(),
            eventHandler: eventHandler
        )
    }

    init(
        email: String,
        tool: String = "BioSwift",
        transport: any HTTPTransport,
        pollingPolicy: NCBIBLASTPollingPolicy = .ncbiDefault,
        sleeper: any BLASTPollingSleeper,
        eventHandler: @escaping @Sendable (NCBIBLASTEvent) -> Void = { _ in }
    ) throws {
        guard email.contains(where: { !$0.isWhitespace }) else {
            throw NCBIBLASTError.emptyEmail
        }
        guard tool.contains(where: { !$0.isWhitespace }) else {
            throw NCBIBLASTError.emptyToolName
        }

        self.email = email
        self.tool = tool
        self.transport = transport
        self.pollingPolicy = pollingPolicy
        self.sleeper = sleeper
        self.eventHandler = eventHandler
    }

    public func search(
        query: BLASTQuery,
        configuration: BLASTConfiguration
    ) async throws -> BLASTResult {
        guard !isSearching else {
            throw NCBIBLASTError.concurrentSearch
        }
        isSearching = true
        defer { isSearching = false }

        let submission = try await submit(query: query, configuration: configuration)
        return try await pollForResult(submission)
    }

    /// Submits a search and immediately returns its persistent NCBI request handle.
    public func submit(
        query: BLASTQuery,
        configuration: BLASTConfiguration
    ) async throws -> NCBIBLASTSubmission {
        let response = try await submitRequest(query: query, configuration: configuration)
        let submission = NCBIBLASTSubmission(
            requestIdentifier: response.requestIdentifier,
            estimatedCompletionTime: .seconds(response.estimatedCompletionTime),
            submittedAt: Date(),
            query: query,
            configuration: configuration
        )
        eventHandler(.submitted(
            requestIdentifier: submission.requestIdentifier,
            estimatedCompletionTime: submission.estimatedCompletionTime
        ))
        return submission
    }

    /// Returns NCBI's current state without retrieving an alignment report.
    public func status(for submission: NCBIBLASTSubmission) async throws -> NCBIBLASTStatus {
        try await requestStatus(requestIdentifier: submission.requestIdentifier)
    }

    /// Waits for a submitted request and retrieves its completed JSON2 report.
    ///
    /// Cancelling the calling task stops local polling. Persist `submission` and
    /// pass it to this method again to resume without creating a new NCBI job.
    public func result(for submission: NCBIBLASTSubmission) async throws -> BLASTResult {
        guard !isSearching else {
            throw NCBIBLASTError.concurrentSearch
        }
        isSearching = true
        defer { isSearching = false }
        return try await pollForResult(submission)
    }

    private func pollForResult(_ submission: NCBIBLASTSubmission) async throws -> BLASTResult {
        let requiredInitialDelay = max(pollingPolicy.interval, submission.estimatedCompletionTime)
        let elapsedBeforePolling = max(0, Date().timeIntervalSince(submission.submittedAt))
        // A newly created handle has only accrued bookkeeping time. Preserve the
        // complete NCBI interval instead of polling a fraction of a second early.
        let remainingDelay = elapsedBeforePolling < 1
            ? requiredInitialDelay
            : requiredInitialDelay - .seconds(elapsedBeforePolling)
        if remainingDelay > .zero {
            try await sleeper.sleep(for: remainingDelay)
        }

        for attempt in 0..<pollingPolicy.maximumAttempts {
            let elapsed = Self.elapsed(since: submission.submittedAt)
            eventHandler(.polling(
                requestIdentifier: submission.requestIdentifier,
                attempt: attempt + 1,
                elapsed: elapsed
            ))
            let status = try await requestStatus(requestIdentifier: submission.requestIdentifier)
            eventHandler(.status(
                requestIdentifier: submission.requestIdentifier,
                status: status,
                elapsed: Self.elapsed(since: submission.submittedAt)
            ))
            switch status {
            case .waiting:
                guard attempt + 1 < pollingPolicy.maximumAttempts else {
                    throw NCBIBLASTError.pollingTimedOut
                }
                try await sleeper.sleep(for: pollingPolicy.interval)
            case .failed(let message):
                throw NCBIBLASTError.searchFailed(message)
            case .expired:
                throw NCBIBLASTError.requestExpired
            case .ready:
                eventHandler(.retrieving(
                    requestIdentifier: submission.requestIdentifier,
                    elapsed: Self.elapsed(since: submission.submittedAt)
                ))
                let data = try await retrieveResult(requestIdentifier: submission.requestIdentifier)
                return try NCBIBLASTResponseDecoder().decode(
                    data,
                    query: submission.query,
                    configuration: submission.configuration
                )
            }
        }

        throw NCBIBLASTError.pollingTimedOut
    }

    private func submitRequest(
        query: BLASTQuery,
        configuration: BLASTConfiguration
    ) async throws -> Submission {
        var items = [
            URLQueryItem(name: "CMD", value: "Put"),
            URLQueryItem(name: "QUERY", value: Self.fasta(query)),
            URLQueryItem(name: "DATABASE", value: configuration.database),
            URLQueryItem(name: "PROGRAM", value: configuration.program.rawValue),
            URLQueryItem(name: "EXPECT", value: String(configuration.expectationValue)),
            URLQueryItem(name: "HITLIST_SIZE", value: String(configuration.maximumHits)),
            URLQueryItem(
                name: "FILTER",
                value: configuration.filtersLowComplexityRegions ? "T" : "F"
            ),
            URLQueryItem(name: "EMAIL", value: email),
            URLQueryItem(name: "TOOL", value: tool),
        ]
        if let substitutionMatrix = configuration.substitutionMatrix {
            items.append(URLQueryItem(name: "MATRIX", value: substitutionMatrix))
        }

        var form = URLComponents()
        form.queryItems = items
        guard let encodedForm = form.percentEncodedQuery else {
            throw NCBIBLASTError.malformedSubmissionResponse
        }

        var request = URLRequest(url: try Self.endpoint())
        request.httpMethod = "POST"
        request.httpBody = Data(encodedForm.utf8)
        request.setValue(
            "application/x-www-form-urlencoded; charset=utf-8",
            forHTTPHeaderField: "Content-Type"
        )

        let response = try await transport.data(for: request).validated()
        return try Self.parseSubmission(response.data)
    }

    private func requestStatus(requestIdentifier: String) async throws -> NCBIBLASTStatus {
        var components = URLComponents(
            url: try Self.endpoint(),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "CMD", value: "Get"),
            URLQueryItem(name: "RID", value: requestIdentifier),
            URLQueryItem(name: "FORMAT_OBJECT", value: "SearchInfo"),
            URLQueryItem(name: "EMAIL", value: email),
            URLQueryItem(name: "TOOL", value: tool),
        ]
        guard let url = components?.url else {
            throw NCBIBLASTError.malformedResult("Unable to construct the retrieval URL.")
        }

        let response = try await transport.data(for: URLRequest(url: url)).validated()
        let text = String(decoding: response.data, as: UTF8.self)
        if text.range(of: "Status=WAITING", options: .caseInsensitive) != nil {
            return .waiting
        }
        if text.range(of: "Status=FAILED", options: .caseInsensitive) != nil {
            return .failed(message: Self.statusMessage(in: text))
        }
        if text.range(of: "Status=UNKNOWN", options: .caseInsensitive) != nil {
            return .expired
        }
        if text.range(of: "Status=READY", options: .caseInsensitive) != nil {
            let hasHits = text.range(of: "ThereAreHits=yes", options: .caseInsensitive) != nil
            return .ready(hasHits: hasHits)
        }

        throw NCBIBLASTError.malformedResult(text)
    }

    private func retrieveResult(requestIdentifier: String) async throws -> Data {
        var components = URLComponents(url: try Self.endpoint(), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "CMD", value: "Get"),
            URLQueryItem(name: "RID", value: requestIdentifier),
            URLQueryItem(name: "FORMAT_TYPE", value: "JSON2_S"),
            URLQueryItem(name: "EMAIL", value: email),
            URLQueryItem(name: "TOOL", value: tool),
        ]
        guard let url = components?.url else {
            throw NCBIBLASTError.malformedResult("Unable to construct the retrieval URL.")
        }
        let data = try await transport.data(for: URLRequest(url: url)).validated().data
        guard Self.looksLikeJSON(data) else {
            throw NCBIBLASTError.malformedResult(String(decoding: data, as: UTF8.self))
        }
        return data
    }

    private static func elapsed(since date: Date) -> Duration {
        .seconds(max(0, Date().timeIntervalSince(date)))
    }

    private static func fasta(_ query: BLASTQuery) -> String {
        guard let identifier = query.identifier else {
            return query.sequence
        }
        let safeIdentifier = identifier
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
        return ">\(safeIdentifier)\n\(query.sequence)"
    }

    private static func parseSubmission(_ data: Data) throws -> Submission {
        let text = String(decoding: data, as: UTF8.self)
        var values: [String: String] = [:]
        for line in text.split(whereSeparator: \.isNewline) {
            let parts = line.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            values[parts[0].trimmingCharacters(in: .whitespaces)] =
                parts[1].trimmingCharacters(in: .whitespaces)
        }

        guard let requestIdentifier = values["RID"], !requestIdentifier.isEmpty else {
            throw NCBIBLASTError.missingRequestIdentifier
        }
        guard let estimatedText = values["RTOE"],
            let estimatedCompletionTime = Int64(estimatedText),
            estimatedCompletionTime >= 0
        else {
            throw NCBIBLASTError.invalidEstimatedCompletionTime(values["RTOE"] ?? "")
        }

        return Submission(
            requestIdentifier: requestIdentifier,
            estimatedCompletionTime: estimatedCompletionTime
        )
    }

    private static func looksLikeJSON(_ data: Data) -> Bool {
        data.first(where: { !$0.isASCIIWhitespace }) == Character("{").asciiValue
    }

    private static func statusMessage(in text: String) -> String? {
        text.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { $0.lowercased().hasPrefix("message=") }
            .map { String($0.dropFirst("message=".count)).trimmingCharacters(in: .whitespaces) }
    }

    private static func endpoint() throws -> URL {
        guard let url = URL(string: "https://blast.ncbi.nlm.nih.gov/Blast.cgi") else {
            throw NCBIBLASTError.malformedSubmissionResponse
        }
        return url
    }
}

private struct Submission {
    let requestIdentifier: String
    let estimatedCompletionTime: Int64
}

private extension UInt8 {
    var isASCIIWhitespace: Bool {
        self == 0x20 || self == 0x09 || self == 0x0A || self == 0x0D
    }
}
