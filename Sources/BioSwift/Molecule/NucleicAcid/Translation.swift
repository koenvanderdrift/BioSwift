//
//  Translation.swift
//  BioSwift
//

import Foundation

extension BioMolecule where ChainType == DNAChain {
    /// Transcribes each DNA coding strand into RNA by replacing thymine with uracil.
    public func transcribed() -> RNA {
        let rnaChains = chains.map { dnaChain in
            var rnaChain = RNAChain(
                sequence: dnaChain.sequenceString.replacingOccurrences(of: "T", with: "U"))
            rnaChain.name = dnaChain.name
            rnaChain.range = dnaChain.range
            rnaChain.parentLength = dnaChain.parentLength
            return rnaChain
        }

        return RNA(chains: rnaChains, adducts: adducts)
    }

    /// Transcribes the DNA and translates the resulting RNA using the standard genetic code.
    public func translated() -> Protein {
        transcribed().translated()
    }
}

extension BioMolecule where ChainType == RNAChain {
    /// Translates each RNA strand from its first nucleotide using the standard genetic code.
    /// Translation ends at the first stop codon; an incomplete trailing codon is ignored.
    public func translated() -> Protein {
        let peptides = chains.map { rnaChain in
            var peptide = Peptide(sequence: Self.aminoAcidSequence(from: rnaChain.sequenceString))
            peptide.name = rnaChain.name
            peptide.range = rnaChain.range
            peptide.parentLength = rnaChain.parentLength
            return peptide
        }

        return Protein(chains: peptides)
    }

    private static func aminoAcidSequence(from sequence: String) -> String {
        let nucleotides = Array(sequence.uppercased())
        var aminoAcids = ""
        aminoAcids.reserveCapacity(nucleotides.count / 3)

        for start in stride(from: 0, through: nucleotides.count - nucleotides.count % 3 - 3, by: 3) {
            let codon = String(nucleotides[start..<(start + 3)])
            guard let aminoAcid = standardGeneticCode[codon] else { continue }
            guard let aminoAcid else { break }
            aminoAcids.append(aminoAcid)
        }

        return aminoAcids
    }
}

private let standardGeneticCode: [String: Character?] = [
    "UUU": "F", "UUC": "F", "UUA": "L", "UUG": "L",
    "UCU": "S", "UCC": "S", "UCA": "S", "UCG": "S",
    "UAU": "Y", "UAC": "Y", "UAA": nil, "UAG": nil,
    "UGU": "C", "UGC": "C", "UGA": nil, "UGG": "W",
    "CUU": "L", "CUC": "L", "CUA": "L", "CUG": "L",
    "CCU": "P", "CCC": "P", "CCA": "P", "CCG": "P",
    "CAU": "H", "CAC": "H", "CAA": "Q", "CAG": "Q",
    "CGU": "R", "CGC": "R", "CGA": "R", "CGG": "R",
    "AUU": "I", "AUC": "I", "AUA": "I", "AUG": "M",
    "ACU": "T", "ACC": "T", "ACA": "T", "ACG": "T",
    "AAU": "N", "AAC": "N", "AAA": "K", "AAG": "K",
    "AGU": "S", "AGC": "S", "AGA": "R", "AGG": "R",
    "GUU": "V", "GUC": "V", "GUA": "V", "GUG": "V",
    "GCU": "A", "GCC": "A", "GCA": "A", "GCG": "A",
    "GAU": "D", "GAC": "D", "GAA": "E", "GAG": "E",
    "GGU": "G", "GGC": "G", "GGA": "G", "GGG": "G",
]
