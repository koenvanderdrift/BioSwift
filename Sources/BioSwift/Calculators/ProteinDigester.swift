//
//  ProteinDigester.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/12/18.
//  Copyright © 2018 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

/// ProteinDigester produces a ``Peptides`` array.
///  It takes an ``Enzyme`` and optionally a missedCleavages paramenter
///
public class ProteinDigester {
    public let protein: Protein

    public init(protein: Protein) { self.protein = protein }

    public func peptides(using enzyme: Enzyme, with missedCleavages: Int = 0) -> [Peptide] {
        var peptides: [Peptide] = []

        for chain in protein.chains {
            peptides += chain.digest(using: enzyme, with: missedCleavages)
        }

        return peptides
    }

    private func digestChain() -> [Peptide] { [] }
}

extension Chain {
    // TODO: this is Protein only

    public func digest(using enzyme: Enzyme, with missedCleavages: Int) -> [Peptide] {
        var baseRanges: [Range<Int>] = []

        do {
            baseRanges = try enzyme.cutRanges(in: sequenceString)
        } catch {
            debugPrint(error.localizedDescription)
        }

        var ranges = baseRanges

        let chunksToCombine = missedCleavages + 1

        if missedCleavages > 0, chunksToCombine <= baseRanges.count {
            for startIndex in 0...(baseRanges.count - chunksToCombine) {
                let endIndex = startIndex + chunksToCombine - 1

                ranges.append(baseRanges[startIndex].lowerBound..<baseRanges[endIndex].upperBound)
            }
        }

        ranges.sort {
            if $0.lowerBound == $1.lowerBound {
                return $0.upperBound < $1.upperBound
            }

            return $0.lowerBound < $1.lowerBound
        }

        var peptides = [Peptide]()

        for range in ranges {
            if var new: Peptide = subChain(range: range) as? Peptide {
                new.range = range
                new.parentLength = sequenceLength

                peptides.append(new)
            }
        }

        return peptides
    }

    func cleavageSites(for regex: String) -> [Int] {
        do { return try sequenceString.matches(for: regex).map(\.range.location) } catch {
            debugPrint(error.localizedDescription)
        }

        return []
    }
}
