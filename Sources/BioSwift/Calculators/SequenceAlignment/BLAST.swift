//
//  BLAST.swift
//  BioSwift
//

import Foundation

/// A provider-neutral interface for performing BLAST searches.
///
/// Implementations may use a remote service, a local BLAST+ installation, or
/// another search engine that returns BioSwift's BLAST result models.
public protocol BLASTSearching: Sendable {
    func search(
        query: BLASTQuery,
        configuration: BLASTConfiguration
    ) async throws -> BLASTResult
}

/// A search program from the Basic Local Alignment Search Tool family.
public enum BLASTProgram: String, Codable, CaseIterable, Sendable {
    /// Compares a nucleotide query with a nucleotide database.
    case blastn

    /// Compares a protein query with a protein database.
    case blastp

    /// Translates a nucleotide query and compares it with a protein database.
    case blastx

    /// Compares a protein query with translated nucleotide database sequences.
    case tblastn

    /// Translates both a nucleotide query and nucleotide database sequences.
    case tblastx
}

/// The orientation of a nucleotide sequence participating in a BLAST alignment.
public enum BLASTStrand: String, Codable, CaseIterable, Sendable {
    case plus
    case minus
}

/// A provider-independent BLAST query.
public struct BLASTQuery: Codable, Equatable, Sendable {
    public let identifier: String?
    public let sequence: String

    public init(identifier: String? = nil, sequence: String) throws {
        guard sequence.contains(where: { !$0.isWhitespace }) else {
            throw BLASTError.emptyQuery
        }

        self.identifier = identifier
        self.sequence = sequence
    }
}

/// Provider-independent options shared by BLAST search implementations.
public struct BLASTConfiguration: Codable, Equatable, Sendable {
    public let program: BLASTProgram
    public let database: String
    public let expectationValue: Double
    public let maximumHits: Int
    public let filtersLowComplexityRegions: Bool
    public let substitutionMatrix: String?

    public init(
        program: BLASTProgram,
        database: String,
        expectationValue: Double = 10,
        maximumHits: Int = 100,
        filtersLowComplexityRegions: Bool = true,
        substitutionMatrix: String? = nil
    ) throws {
        guard database.contains(where: { !$0.isWhitespace }) else {
            throw BLASTError.emptyDatabase
        }
        guard expectationValue.isFinite, expectationValue > 0 else {
            throw BLASTError.invalidExpectationValue(expectationValue)
        }
        guard maximumHits > 0 else {
            throw BLASTError.invalidMaximumHits(maximumHits)
        }

        self.program = program
        self.database = database
        self.expectationValue = expectationValue
        self.maximumHits = maximumHits
        self.filtersLowComplexityRegions = filtersLowComplexityRegions
        self.substitutionMatrix = substitutionMatrix
    }
}

/// A complete BLAST search result containing ranked database hits.
public struct BLASTResult: Codable, Equatable, Sendable {
    public let program: BLASTProgram
    public let database: String
    public let query: BLASTQuery
    public let hits: [BLASTHit]

    public init(
        program: BLASTProgram,
        database: String,
        query: BLASTQuery,
        hits: [BLASTHit]
    ) {
        self.program = program
        self.database = database
        self.query = query
        self.hits = hits
    }
}

/// A database sequence matched by a BLAST query.
public struct BLASTHit: Codable, Equatable, Sendable {
    public let identifier: String
    public let accession: String?
    public let definition: String?
    public let sequenceLength: Int
    public let highScoringPairs: [BLASTHighScoringPair]

    public init(
        identifier: String,
        accession: String? = nil,
        definition: String? = nil,
        sequenceLength: Int,
        highScoringPairs: [BLASTHighScoringPair]
    ) throws {
        guard sequenceLength >= 0 else {
            throw BLASTError.invalidSequenceLength(sequenceLength)
        }

        self.identifier = identifier
        self.accession = accession
        self.definition = definition
        self.sequenceLength = sequenceLength
        self.highScoringPairs = highScoringPairs
    }
}

/// One high-scoring segment pair (HSP) within a BLAST hit.
///
/// Ranges use BioSwift's zero-based, half-open convention. Providers that use
/// one-based inclusive coordinates must normalize them before creating this value.
/// A reverse-oriented match still stores its range from lower to upper bound; its
/// direction is represented by the corresponding strand property.
public struct BLASTHighScoringPair: Codable, Equatable, Sendable {
    public let rawScore: Int
    public let bitScore: Double
    public let expectationValue: Double
    public let queryRange: Range<Int>
    public let subjectRange: Range<Int>
    public let querySequence: String
    public let subjectSequence: String
    public let identityCount: Int
    public let positiveCount: Int
    public let gapCount: Int
    public let queryStrand: BLASTStrand?
    public let subjectStrand: BLASTStrand?
    public let queryFrame: Int?
    public let subjectFrame: Int?

    public init(
        rawScore: Int,
        bitScore: Double,
        expectationValue: Double,
        queryRange: Range<Int>,
        subjectRange: Range<Int>,
        querySequence: String,
        subjectSequence: String,
        identityCount: Int,
        positiveCount: Int,
        gapCount: Int,
        queryStrand: BLASTStrand? = nil,
        subjectStrand: BLASTStrand? = nil,
        queryFrame: Int? = nil,
        subjectFrame: Int? = nil
    ) throws {
        guard queryRange.lowerBound >= 0 else {
            throw BLASTError.invalidRange(queryRange)
        }
        guard subjectRange.lowerBound >= 0 else {
            throw BLASTError.invalidRange(subjectRange)
        }

        let queryAlignmentLength = querySequence.count
        let subjectAlignmentLength = subjectSequence.count
        guard queryAlignmentLength == subjectAlignmentLength else {
            throw BLASTError.inconsistentAlignmentLengths(
                query: queryAlignmentLength,
                subject: subjectAlignmentLength
            )
        }
        guard expectationValue.isFinite, expectationValue >= 0 else {
            throw BLASTError.invalidExpectationValue(expectationValue)
        }

        let alignmentLength = queryAlignmentLength
        try Self.validate(identityCount, named: "identity", alignmentLength: alignmentLength)
        try Self.validate(positiveCount, named: "positive", alignmentLength: alignmentLength)
        try Self.validate(gapCount, named: "gap", alignmentLength: alignmentLength)
        guard positiveCount >= identityCount else {
            throw BLASTError.invalidCount(
                name: "positive",
                value: positiveCount,
                alignmentLength: alignmentLength
            )
        }

        self.rawScore = rawScore
        self.bitScore = bitScore
        self.expectationValue = expectationValue
        self.queryRange = queryRange
        self.subjectRange = subjectRange
        self.querySequence = querySequence
        self.subjectSequence = subjectSequence
        self.identityCount = identityCount
        self.positiveCount = positiveCount
        self.gapCount = gapCount
        self.queryStrand = queryStrand
        self.subjectStrand = subjectStrand
        self.queryFrame = queryFrame
        self.subjectFrame = subjectFrame
    }

    public var alignmentLength: Int {
        querySequence.count
    }

    public var identity: Double {
        guard alignmentLength > 0 else { return 0 }
        return Double(identityCount) / Double(alignmentLength)
    }

    public var positives: Double {
        guard alignmentLength > 0 else { return 0 }
        return Double(positiveCount) / Double(alignmentLength)
    }

    private static func validate(_ count: Int, named name: String, alignmentLength: Int) throws {
        guard (0...alignmentLength).contains(count) else {
            throw BLASTError.invalidCount(
                name: name,
                value: count,
                alignmentLength: alignmentLength
            )
        }
    }
}

/// Errors shared by BLAST model and provider implementations.
public enum BLASTError: Error, Equatable, Sendable {
    case emptyQuery
    case emptyDatabase
    case invalidExpectationValue(Double)
    case invalidMaximumHits(Int)
    case invalidSequenceLength(Int)
    case invalidRange(Range<Int>)
    case inconsistentAlignmentLengths(query: Int, subject: Int)
    case invalidCount(name: String, value: Int, alignmentLength: Int)
    case malformedResult(String)
    case searchFailed(String)
}
