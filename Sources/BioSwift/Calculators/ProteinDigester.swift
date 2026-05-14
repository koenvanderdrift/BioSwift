//
//  ProteinDigester.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/12/18.
//  Copyright © 2018 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

public class ProteinDigester {
    public let protein: Protein

    public init(protein: Protein) {
        self.protein = protein
    }

    public func peptides(using enzyme: Enzyme, with missedCleavages: Int) -> [Peptide] {
        var peptides: [Peptide] = []

        for chain in protein.chains {
            peptides += chain.digest(using: enzyme, with: missedCleavages)
        }

        return peptides
    }

    private func digestChain() -> [Peptide] {
        []
    }
}

extension Chain {
    // TODO: this is Protein only
    // TODO: recreate residues

    public func digest(using enzyme: Enzyme, with missedCleavages: Int) -> [Peptide] {
        let sites = cleavageSites(for: enzyme.regex())

        var subSequences = [Peptide]()

        var start = residues.startIndex
        var end = start

        for site in sites {
            end = residues.index(residues.startIndex, offsetBy: site)

            if var new: Peptide = subChain(from: start, to: end - 1) as? Peptide {
                new.range = start ... end - 1
                new.parentLength = self.sequenceLength

                subSequences.append(new)

                start = end
            }
        }

        if var final: Peptide = subChain(from: start, to: residues.endIndex - 1) as? Peptide {
            final.range = start ... residues.endIndex - 1
            final.parentLength = self.sequenceLength

            subSequences.append(final)
        }

        guard missedCleavages > 0 else {
            return subSequences
        }

        var joinedSubSequences = [Peptide]()

        for mc in 0 ... missedCleavages {
            for (index, _) in subSequences.enumerated() {
                let newIndex = index + mc
                if subSequences.indices.contains(newIndex) {
                    let res = subSequences[index ... newIndex]
                        .reduce([]) { $0 + $1.residues }
                    var new = Peptide(residues: res)

                    new.range = subSequences[index].range.lowerBound ... subSequences[newIndex].range.upperBound
                    new.parentLength = self.sequenceLength

                    if index == 0 {
                        new.nTerminal = nTerminal
                    }

                    if newIndex == subSequences.count - 1 {
                        new.cTerminal = cTerminal
                    }

                    joinedSubSequences.append(new)
                }
            }
        }

        return joinedSubSequences
    }

    func cleavageSites(for regex: String) -> [Int] {
        sequenceString.matches(for: regex).map(\.range.location)
    }
}
