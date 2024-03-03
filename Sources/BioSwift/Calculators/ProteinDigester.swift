//
<<<<<<< HEAD
//  Digest.swift
=======
//  ProteinDigester.swift
>>>>>>> main
//  BioSwift
//
//  Created by Koen van der Drift on 7/12/18.
//  Copyright © 2018 Koen van der Drift. All rights reserved.
//

import Foundation

public class ProteinDigester {
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
<<<<<<< HEAD
    public func digest<T: RangedChain>(using regex: String, with missedCleavages: Int) -> [T] {
        let sites = cleavageSites(for: regex)

        var subSequences = [T]()
=======
    public func digest(using regex: String, with missedCleavages: Int) -> [Peptide] {
        let sites = cleavageSites(for: regex)

        var subSequences = [Peptide]()
>>>>>>> main

        var start = residues.startIndex
        var end = start

        for site in sites {
            end = residues.index(residues.startIndex, offsetBy: site)

<<<<<<< HEAD
            if var new: T = subChain(from: start, to: end - 1) as? T {
=======
            if var new: Peptide = subChain(from: start, to: end - 1) as? Peptide {
>>>>>>> main
                new.rangeInParent = start ... end - 1
                subSequences.append(new)

                start = end
            }
        }

<<<<<<< HEAD
        if var final: T = subChain(from: start, to: residues.endIndex - 1) as? T {
=======
        if var final: Peptide = subChain(from: start, to: residues.endIndex - 1) as? Peptide {
>>>>>>> main
            final.rangeInParent = start ... residues.endIndex - 1
            subSequences.append(final)
        }

        guard missedCleavages > 0 else {
            return subSequences
        }

<<<<<<< HEAD
        var joinedSubSequences = [T]()
=======
        var joinedSubSequences = [Peptide]()
>>>>>>> main

        for mc in 0 ... missedCleavages {
            for (index, _) in subSequences.enumerated() {
                let newIndex = index + mc
                if subSequences.indices.contains(newIndex) {
                    let res = subSequences[index ... newIndex]
                        .reduce([]) { $0 + $1.residues }
<<<<<<< HEAD
                    var new = T(residues: res)
=======
                    var new = Peptide(residues: res)
>>>>>>> main

                    new.rangeInParent = subSequences[index].rangeInParent.lowerBound ... subSequences[newIndex].rangeInParent.upperBound

                    if index == 0 {
<<<<<<< HEAD
                        new.termini?.first.modification = termini?.first.modification
                    }

                    if newIndex == subSequences.count - 1 {
                        new.termini?.last.modification = termini?.last.modification
=======
                        if let mod = termini?.first {
                            new.termini?.first = mod
                        }
                    }

                    if newIndex == subSequences.count - 1 {
                        if let mod = termini?.last {
                            new.termini?.last = mod
                        }
>>>>>>> main
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
