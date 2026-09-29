//
//  SequenceAlignment.swift
//  BioSwift
//

import Foundation

/// The strategy used to align two biological sequences.
public enum AlignmentAlgorithm: String, Codable, CaseIterable, Sendable {
    /// Global alignment across both complete sequences.
    case needlemanWunsch

    /// Local alignment of the highest-scoring regions of both sequences.
    case smithWaterman
}

/// Scores used when constructing a pairwise sequence alignment.
///
/// Positive values reward an alignment, negative values penalize it, and zero is neutral.
/// `gap` is a linear per-residue score, so a gap of length `n` contributes `n * gap`.
/// When `substitutionMatrix` is present, its values replace `match` and `mismatch`.
public struct AlignmentScoring: Codable, Equatable, Sendable {
    public var match: Int
    public var mismatch: Int
    public var gap: Int
    public var substitutionMatrix: SubstitutionMatrix?

    public init(
        match: Int,
        mismatch: Int,
        gap: Int,
        substitutionMatrix: SubstitutionMatrix? = nil
    ) {
        self.match = match
        self.mismatch = mismatch
        self.gap = gap
        self.substitutionMatrix = substitutionMatrix
    }

    public func score(first: String, second: String) -> Int {
        if let substitutionMatrix {
            return substitutionMatrix.score(first: first, second: second)
        }
        return first == second ? match : mismatch
    }

    public static func nucleotide(
        match: Int = 2,
        mismatch: Int = -1,
        gap: Int = -2
    ) -> AlignmentScoring {
        AlignmentScoring(match: match, mismatch: mismatch, gap: gap)
    }

    public static func proteinIdentity(
        match: Int = 1,
        mismatch: Int = -1,
        gap: Int = -1
    ) -> AlignmentScoring {
        AlignmentScoring(match: match, mismatch: mismatch, gap: gap)
    }

    public static func blosum62(gap: Int = -4) -> AlignmentScoring {
        AlignmentScoring(
            match: 1,
            mismatch: -1,
            gap: gap,
            substitutionMatrix: .blosum62
        )
    }
}

/// A square residue substitution matrix stored in row-major order.
public struct SubstitutionMatrix: Codable, Equatable, Sendable {
    public let alphabet: [String]
    public let scores: [Int]
    public let unknownScore: Int

    public init?(alphabet: [String], scores: [Int], unknownScore: Int) {
        guard !alphabet.isEmpty, scores.count == alphabet.count * alphabet.count else {
            return nil
        }
        self.alphabet = alphabet
        self.scores = scores
        self.unknownScore = unknownScore
    }

    init(validatedAlphabet alphabet: [String], scores: [Int], unknownScore: Int) {
        self.alphabet = alphabet
        self.scores = scores
        self.unknownScore = unknownScore
    }

    public func score(first: String, second: String) -> Int {
        guard
            let firstIndex = alphabet.firstIndex(of: first.uppercased()),
            let secondIndex = alphabet.firstIndex(of: second.uppercased())
        else {
            return unknownScore
        }
        return scores[firstIndex * alphabet.count + secondIndex]
    }
}

/// The relationship represented by one column of a pairwise alignment.
public enum AlignmentOperation: String, Codable, Sendable {
    case identity
    case similarity
    case substitution

    /// A residue in the second sequence aligned to a gap in the first sequence.
    case insertion

    /// A residue in the first sequence aligned to a gap in the second sequence.
    case deletion
}

/// One column of a pairwise sequence alignment.
///
/// Indices are zero-based positions in the original, unaligned sequences. An index and
/// residue are `nil` when that sequence contains a gap in this alignment column.
public struct AlignmentColumn: Codable, Equatable, Sendable {
    public let firstResidue: String?
    public let firstIndex: Int?
    public let secondResidue: String?
    public let secondIndex: Int?
    public let operation: AlignmentOperation

    public init(
        firstResidue: String?,
        firstIndex: Int?,
        secondResidue: String?,
        secondIndex: Int?,
        operation: AlignmentOperation
    ) {
        self.firstResidue = firstResidue
        self.firstIndex = firstIndex
        self.secondResidue = secondResidue
        self.secondIndex = secondIndex
        self.operation = operation
    }
}

/// The result of a global or local pairwise sequence alignment.
///
/// `firstRange` and `secondRange` are zero-based, half-open ranges in the original,
/// unaligned sequences. A global alignment normally spans both complete sequences,
/// while a local alignment reports only the regions selected by Smith-Waterman.
public struct AlignmentResult: Codable, Equatable, Sendable {
    public let algorithm: AlignmentAlgorithm
    public let score: Int
    /// The zero-based, half-open source range aligned from the first sequence.
    public let firstRange: Range<Int>

    /// The zero-based, half-open source range aligned from the second sequence.
    public let secondRange: Range<Int>
    public let columns: [AlignmentColumn]

    public init(
        algorithm: AlignmentAlgorithm,
        score: Int,
        firstRange: Range<Int>,
        secondRange: Range<Int>,
        columns: [AlignmentColumn]
    ) {
        self.algorithm = algorithm
        self.score = score
        self.firstRange = firstRange
        self.secondRange = secondRange
        self.columns = columns
    }

    public var firstAlignedSequence: String {
        columns.map { $0.firstResidue ?? "-" }.joined()
    }

    public var secondAlignedSequence: String {
        columns.map { $0.secondResidue ?? "-" }.joined()
    }

    public var identityCount: Int {
        columns.count { $0.operation == .identity }
    }

    public var similarityCount: Int {
        columns.count { $0.operation == .identity || $0.operation == .similarity }
    }

    public var gapCount: Int {
        columns.count { $0.operation == .insertion || $0.operation == .deletion }
    }

    /// The fraction of alignment columns containing identical residues.
    public var identity: Double {
        guard !columns.isEmpty else { return 0 }
        return Double(identityCount) / Double(columns.count)
    }

    /// The fraction of alignment columns containing identical or similar residues.
    public var similarity: Double {
        guard !columns.isEmpty else { return 0 }
        return Double(similarityCount) / Double(columns.count)
    }
}
