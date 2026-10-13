//
//  BLAST.swift
//  BioSwift
//

import Foundation

/// A search program from the Basic Local Alignment Search Tool family.
public enum BLASTProgram: String, Codable, CaseIterable, Sendable {
    case blastn
    case blastp
    case blastx
    case tblastn
    case tblastx
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

/// Options shared by BLAST query destinations.
public struct BLASTConfiguration: Codable, Equatable, Sendable {
    public let program: BLASTProgram
    public let database: String
    public let expectationValue: Double
    public let maximumHits: Int
    public let filtersLowComplexityRegions: Bool
    public let substitutionMatrix: String?
    public let wordSize: Int?
    public let adjustsForShortQuery: Bool?
    public let nucleotideMatchReward: Int?
    public let nucleotideMismatchPenalty: Int?

    public init(
        program: BLASTProgram,
        database: String,
        expectationValue: Double = 10,
        maximumHits: Int = 100,
        filtersLowComplexityRegions: Bool = true,
        substitutionMatrix: String? = nil,
        wordSize: Int? = nil,
        adjustsForShortQuery: Bool? = nil,
        nucleotideMatchReward: Int? = nil,
        nucleotideMismatchPenalty: Int? = nil
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
        if let wordSize, wordSize <= 0 {
            throw BLASTError.invalidWordSize(wordSize)
        }
        if let substitutionMatrix {
            guard substitutionMatrix.contains(where: { !$0.isWhitespace }) else {
                throw BLASTError.emptySubstitutionMatrix
            }
            guard program != .blastn else {
                throw BLASTError.unsupportedOption("substitutionMatrix", program: program)
            }
        }
        if adjustsForShortQuery != nil, program != .blastn, program != .blastp {
            throw BLASTError.unsupportedOption("adjustsForShortQuery", program: program)
        }
        if nucleotideMatchReward != nil || nucleotideMismatchPenalty != nil {
            guard program == .blastn else {
                throw BLASTError.unsupportedOption("nucleotideScoring", program: program)
            }
            if let nucleotideMatchReward, nucleotideMatchReward <= 0 {
                throw BLASTError.invalidNucleotideMatchReward(nucleotideMatchReward)
            }
            if let nucleotideMismatchPenalty, nucleotideMismatchPenalty >= 0 {
                throw BLASTError.invalidNucleotideMismatchPenalty(nucleotideMismatchPenalty)
            }
        }

        self.program = program
        self.database = database
        self.expectationValue = expectationValue
        self.maximumHits = maximumHits
        self.filtersLowComplexityRegions = filtersLowComplexityRegions
        self.substitutionMatrix = substitutionMatrix
        self.wordSize = wordSize
        self.adjustsForShortQuery = adjustsForShortQuery
        self.nucleotideMatchReward = nucleotideMatchReward
        self.nucleotideMismatchPenalty = nucleotideMismatchPenalty
    }
}

public enum BLASTError: Error, Equatable, Sendable {
    case emptyQuery
    case emptyDatabase
    case invalidExpectationValue(Double)
    case invalidMaximumHits(Int)
    case emptySubstitutionMatrix
    case invalidWordSize(Int)
    case invalidNucleotideMatchReward(Int)
    case invalidNucleotideMismatchPenalty(Int)
    case unsupportedOption(String, program: BLASTProgram)
}
