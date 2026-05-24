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
        let sites = cleavageSites(for: enzyme.regex()) // site is first residue of new peptide 0-based

        var peptides = [Peptide]()

        var start = 1
        var end = start
        
        for site in sites {
            end = site

            let newRange: ChainRange = start ... end
            
            if var new: Peptide = subChain(chainRange: newRange) as? Peptide {
                new.rangeInParent = start ... end
                new.parentLength = self.sequenceLength

                peptides.append(new)

                start = site + 1
            }
        }

        let finalRange: ChainRange = start ... numberOfResidues

        if var final: Peptide = subChain(chainRange: finalRange) as? Peptide {
            final.rangeInParent = finalRange
            final.parentLength = self.sequenceLength

            peptides.append(final)
        }

        guard missedCleavages > 0 else {
            return peptides
        }

        let joinedPeptides: [Peptide] = peptides
            .combinedConsecutiveChains(ofSize: missedCleavages)
        
        return joinedPeptides
    }

    func cleavageSites(for regex: String) -> [Int] {
        sequenceString.matches(for: regex).map(\.range.location)
    }
}

