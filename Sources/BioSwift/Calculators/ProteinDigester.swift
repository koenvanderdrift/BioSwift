//
//  Digest.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/12/18.
//  Copyright © 2018 Koen van der Drift. All rights reserved.
//

import Foundation

class ProteinDigester {
    public let protein: Protein

    public init(protein: Protein) {
        self.protein = protein
    }

    public func peptides(using regex: String, with missedCleavages: Int) -> [Peptide] {
        var peptides: [Peptide] = []
        
        for chain in protein.chains {
            peptides += chain.digest(using: regex, with: missedCleavages)
        }

        return peptides
    }
    
    private func digestChain() -> [Peptide] {
        []
    }
}

extension Chain {
    public func digest<T: RangedChain>(using regex: String, with missedCleavages: Int) -> [T] {
        let sites = cleavageSites(for: regex)

        var subSequences = [T]()

        var start = residues.startIndex
        var end = start

        for site in sites {
            end = residues.index(residues.startIndex, offsetBy: site)

            if var new: T = subChain(from: start, to: end - 1) as? T {
                new.rangeInParent = start ... end - 1
                subSequences.append(new)

                start = end
            }
        }

        if var final: T = subChain(from: start, to: residues.endIndex - 1) as? T {
            final.rangeInParent = start ... residues.endIndex - 1
            subSequences.append(final)
        }

        guard missedCleavages > 0 else {
            return subSequences
        }

        var joinedSubSequences = [T]()

        for mc in 0 ... missedCleavages {
            for (index, _) in subSequences.enumerated() {
                let newIndex = index + mc
                if subSequences.indices.contains(newIndex) {
                    let res = subSequences[index ... newIndex]
                        .reduce([]) { $0 + $1.residues }
                    var new = T(residues: res)

                    new.rangeInParent = subSequences[index].rangeInParent.lowerBound ... subSequences[newIndex].rangeInParent.upperBound

                    if index == 0 {
                        new.termini?.first.modification = termini?.first.modification
                    }

                    if newIndex == subSequences.count - 1 {
                        new.termini?.last.modification = termini?.last.modification
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
