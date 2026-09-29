import Foundation
import Testing
@testable import BioSwift

@Suite("Sequence alignment models")
struct SequenceAlignmentTests {
    @Test("Alignment algorithms support iteration and Codable round trips")
    func algorithms() throws {
        #expect(AlignmentAlgorithm.allCases == [.needlemanWunsch, .smithWaterman])

        let encoded = try JSONEncoder().encode(AlignmentAlgorithm.needlemanWunsch)
        let decoded = try JSONDecoder().decode(AlignmentAlgorithm.self, from: encoded)

        #expect(decoded == .needlemanWunsch)
    }

    @Test("Alignment scoring retains configured values")
    func scoring() {
        let scoring = AlignmentScoring(match: 2, mismatch: -1, gap: -2)

        #expect(scoring.match == 2)
        #expect(scoring.mismatch == -1)
        #expect(scoring.gap == -2)
    }

    @Test("Alignment result derives sequences and statistics from its columns")
    func resultStatistics() {
        let columns = [
            AlignmentColumn(
                firstResidue: "A", firstIndex: 0,
                secondResidue: "A", secondIndex: 2,
                operation: .identity
            ),
            AlignmentColumn(
                firstResidue: "G", firstIndex: 1,
                secondResidue: "A", secondIndex: 3,
                operation: .similarity
            ),
            AlignmentColumn(
                firstResidue: "T", firstIndex: 2,
                secondResidue: nil, secondIndex: nil,
                operation: .deletion
            ),
            AlignmentColumn(
                firstResidue: "C", firstIndex: 3,
                secondResidue: "G", secondIndex: 4,
                operation: .substitution
            ),
        ]
        let result = AlignmentResult(
            algorithm: .smithWaterman,
            score: 4,
            firstRange: 0..<4,
            secondRange: 2..<5,
            columns: columns
        )

        #expect(result.firstAlignedSequence == "AGTC")
        #expect(result.secondAlignedSequence == "AA-G")
        #expect(result.identityCount == 1)
        #expect(result.similarityCount == 2)
        #expect(result.gapCount == 1)
        #expect(result.identity == 0.25)
        #expect(result.similarity == 0.5)
    }

    @Test("An empty alignment has zero identity and similarity")
    func emptyResult() {
        let result = AlignmentResult(
            algorithm: .smithWaterman,
            score: 0,
            firstRange: 0..<0,
            secondRange: 0..<0,
            columns: []
        )

        #expect(result.firstAlignedSequence.isEmpty)
        #expect(result.secondAlignedSequence.isEmpty)
        #expect(result.identity == 0)
        #expect(result.similarity == 0)
    }

    @Test("Needleman-Wunsch aligns complete sequences")
    func needlemanWunsch() {
        let result = SequenceAligner.align(
            residues("ACG"),
            with: residues("AG"),
            algorithm: .needlemanWunsch,
            scoring: AlignmentScoring(match: 2, mismatch: -1, gap: -2)
        )

        #expect(result.score == 2)
        #expect(result.firstAlignedSequence == "ACG")
        #expect(result.secondAlignedSequence == "A-G")
        #expect(result.firstRange == 0..<3)
        #expect(result.secondRange == 0..<2)
        #expect(result.gapCount == 1)
    }

    @Test("Smith-Waterman finds the highest-scoring local regions")
    func smithWaterman() {
        let result = SequenceAligner.align(
            residues("TTAC"),
            with: residues("GGTTACAA"),
            algorithm: .smithWaterman,
            scoring: AlignmentScoring(match: 2, mismatch: -1, gap: -2)
        )

        #expect(result.score == 8)
        #expect(result.firstAlignedSequence == "TTAC")
        #expect(result.secondAlignedSequence == "TTAC")
        #expect(result.firstRange == 0..<4)
        #expect(result.secondRange == 2..<6)
        #expect(result.identity == 1)
    }

    @Test("Global alignment handles an empty sequence")
    func globalEmptySequence() {
        let result = SequenceAligner.align(
            [],
            with: residues("AC"),
            algorithm: .needlemanWunsch,
            scoring: AlignmentScoring(match: 2, mismatch: -1, gap: -2)
        )

        #expect(result.score == -4)
        #expect(result.firstAlignedSequence == "--")
        #expect(result.secondAlignedSequence == "AC")
        #expect(result.firstRange == 0..<0)
        #expect(result.secondRange == 0..<2)
    }

    @Test("Local alignment returns an empty result when no positive score exists")
    func localWithoutPositiveScore() {
        let result = SequenceAligner.align(
            residues("AA"),
            with: residues("TT"),
            algorithm: .smithWaterman,
            scoring: AlignmentScoring(match: 2, mismatch: -1, gap: -2)
        )

        #expect(result.score == 0)
        #expect(result.columns.isEmpty)
        #expect(result.firstRange == 0..<0)
        #expect(result.secondRange == 0..<0)
    }

    @Test("Traceback uses deterministic diagonal-first tie breaking")
    func deterministicTieBreaking() {
        let result = SequenceAligner.align(
            residues("A"),
            with: residues("G"),
            algorithm: .needlemanWunsch,
            scoring: AlignmentScoring(match: 1, mismatch: 0, gap: 0)
        )

        #expect(result.firstAlignedSequence == "A")
        #expect(result.secondAlignedSequence == "G")
        #expect(result.columns.map(\.operation) == [.substitution])
    }

    @Test("Built-in scoring strategies provide expected defaults")
    func builtInScoring() {
        #expect(AlignmentScoring.nucleotide() == AlignmentScoring(match: 2, mismatch: -1, gap: -2))
        #expect(AlignmentScoring.proteinIdentity() == AlignmentScoring(match: 1, mismatch: -1, gap: -1))
        #expect(AlignmentScoring.blosum62().gap == -4)
    }

    @Test("BLOSUM62 contains canonical substitution scores")
    func blosum62Scores() {
        let matrix = SubstitutionMatrix.blosum62

        #expect(matrix.score(first: "A", second: "A") == 4)
        #expect(matrix.score(first: "W", second: "W") == 11)
        #expect(matrix.score(first: "D", second: "E") == 2)
        #expect(matrix.score(first: "E", second: "D") == 2)
        #expect(matrix.score(first: "C", second: "W") == -2)
        #expect(matrix.score(first: "?", second: "A") == -4)
    }

    @Test("A positive BLOSUM62 substitution is reported as similarity")
    func proteinSimilarity() {
        let result = SequenceAligner.align(
            ["D"],
            with: ["E"],
            algorithm: .needlemanWunsch,
            scoring: .blosum62()
        )

        #expect(result.score == 2)
        #expect(result.columns.map(\.operation) == [.similarity])
        #expect(result.identityCount == 0)
        #expect(result.similarityCount == 1)
    }

    @Test("Custom substitution matrices override match and mismatch scores")
    func customSubstitutionMatrix() throws {
        let matrix = try #require(SubstitutionMatrix(
            alphabet: ["A", "B"],
            scores: [3, -2, -2, 5],
            unknownScore: -7
        ))
        let scoring = AlignmentScoring(
            match: 100,
            mismatch: 100,
            gap: -3,
            substitutionMatrix: matrix
        )

        #expect(scoring.score(first: "A", second: "A") == 3)
        #expect(scoring.score(first: "A", second: "B") == -2)
        #expect(scoring.score(first: "X", second: "A") == -7)
    }

    @Test("Substitution matrices reject malformed score tables")
    func malformedSubstitutionMatrix() {
        #expect(SubstitutionMatrix(alphabet: ["A", "B"], scores: [1, 2], unknownScore: -1) == nil)
    }

    private func residues(_ sequence: String) -> [String] {
        sequence.map(String.init)
    }
}
