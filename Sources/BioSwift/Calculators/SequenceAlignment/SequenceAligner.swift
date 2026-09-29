//
//  SequenceAligner.swift
//  BioSwift
//

import Foundation

/// Performs pairwise alignment of biological residue identifiers.
public enum SequenceAligner {
    /// Aligns two sequences using linear gap scoring.
    ///
    /// Positive scores are rewards and negative scores are penalties. The gap score is
    /// applied once per residue in a gap. Traceback resolves equal scores in this order:
    /// diagonal, deletion, insertion. Smith-Waterman selects the first maximum cell in
    /// row-major order when several cells have the same best score. These rules make the
    /// returned alignment deterministic when several optimal paths exist.
    ///
    /// For input lengths `m` and `n`, this implementation uses `O(mn)` time and `O(mn)`
    /// memory because it retains the complete score and traceback matrices.
    public static func align(
        _ first: [String],
        with second: [String],
        algorithm: AlignmentAlgorithm,
        scoring: AlignmentScoring
    ) -> AlignmentResult {
        let columnCount = second.count + 1
        let cellCount = (first.count + 1) * columnCount
        var scores = Array(repeating: 0, count: cellCount)
        var traceback = Array(repeating: Traceback.stop, count: cellCount)

        func offset(_ firstIndex: Int, _ secondIndex: Int) -> Int {
            firstIndex * columnCount + secondIndex
        }

        if algorithm == .needlemanWunsch {
            if !first.isEmpty {
                for firstIndex in 1...first.count {
                    scores[offset(firstIndex, 0)] = firstIndex * scoring.gap
                    traceback[offset(firstIndex, 0)] = .deletion
                }
            }
            if !second.isEmpty {
                for secondIndex in 1...second.count {
                    scores[offset(0, secondIndex)] = secondIndex * scoring.gap
                    traceback[offset(0, secondIndex)] = .insertion
                }
            }
        }

        var bestFirstIndex = 0
        var bestSecondIndex = 0
        var bestScore = 0

        if !first.isEmpty, !second.isEmpty {
            for firstIndex in 1...first.count {
                for secondIndex in 1...second.count {
                    let substitution = scoring.score(
                        first: first[firstIndex - 1],
                        second: second[secondIndex - 1]
                    )
                    let diagonalScore = scores[offset(firstIndex - 1, secondIndex - 1)] + substitution
                    let deletionScore = scores[offset(firstIndex - 1, secondIndex)] + scoring.gap
                    let insertionScore = scores[offset(firstIndex, secondIndex - 1)] + scoring.gap

                    var cellScore = diagonalScore
                    var direction = Traceback.diagonal
                    if deletionScore > cellScore {
                        cellScore = deletionScore
                        direction = .deletion
                    }
                    if insertionScore > cellScore {
                        cellScore = insertionScore
                        direction = .insertion
                    }
                    if algorithm == .smithWaterman, cellScore <= 0 {
                        cellScore = 0
                        direction = .stop
                    }

                    scores[offset(firstIndex, secondIndex)] = cellScore
                    traceback[offset(firstIndex, secondIndex)] = direction

                    if algorithm == .smithWaterman, cellScore > bestScore {
                        bestScore = cellScore
                        bestFirstIndex = firstIndex
                        bestSecondIndex = secondIndex
                    }
                }
            }
        }

        let endFirstIndex: Int
        let endSecondIndex: Int
        let resultScore: Int
        switch algorithm {
        case .needlemanWunsch:
            endFirstIndex = first.count
            endSecondIndex = second.count
            resultScore = scores[offset(first.count, second.count)]
        case .smithWaterman:
            endFirstIndex = bestFirstIndex
            endSecondIndex = bestSecondIndex
            resultScore = bestScore
        }

        var firstIndex = endFirstIndex
        var secondIndex = endSecondIndex
        var columns: [AlignmentColumn] = []
        columns.reserveCapacity(first.count + second.count)

        while firstIndex > 0 || secondIndex > 0 {
            let direction = traceback[offset(firstIndex, secondIndex)]
            if algorithm == .smithWaterman, direction == .stop {
                break
            }

            switch direction {
            case .diagonal:
                firstIndex -= 1
                secondIndex -= 1
                let isIdentity = first[firstIndex] == second[secondIndex]
                let substitutionScore = scoring.score(
                    first: first[firstIndex],
                    second: second[secondIndex]
                )
                columns.append(AlignmentColumn(
                    firstResidue: first[firstIndex],
                    firstIndex: firstIndex,
                    secondResidue: second[secondIndex],
                    secondIndex: secondIndex,
                    operation: isIdentity ? .identity : substitutionScore > 0 ? .similarity : .substitution
                ))
            case .deletion:
                firstIndex -= 1
                columns.append(AlignmentColumn(
                    firstResidue: first[firstIndex],
                    firstIndex: firstIndex,
                    secondResidue: nil,
                    secondIndex: nil,
                    operation: .deletion
                ))
            case .insertion:
                secondIndex -= 1
                columns.append(AlignmentColumn(
                    firstResidue: nil,
                    firstIndex: nil,
                    secondResidue: second[secondIndex],
                    secondIndex: secondIndex,
                    operation: .insertion
                ))
            case .stop:
                break
            }

            if direction == .stop {
                break
            }
        }

        return AlignmentResult(
            algorithm: algorithm,
            score: resultScore,
            firstRange: firstIndex..<endFirstIndex,
            secondRange: secondIndex..<endSecondIndex,
            columns: Array(columns.reversed())
        )
    }
}

private enum Traceback {
    case stop
    case diagonal
    case deletion
    case insertion
}
