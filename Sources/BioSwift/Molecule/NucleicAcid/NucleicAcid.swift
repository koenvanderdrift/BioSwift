//
//  NucleicAcid.swift
//  BioSwift
//

import Foundation

public protocol NucleicAcidChain: SequenceInitializableChain, Structure where ResidueType == Nucleotide {}

extension NucleicAcidChain {
    static func createResidues(
        from sequence: String,
        type: NucleicAcidType
    ) throws -> [Nucleotide] {
        try parseResidues(from: sequence, sequenceType: type.rawValue) { character in
            Nucleotide.standard(code: character, type: type)
        }
    }

    public var complement: Self {
        transformed(residues: residues.map(\.complement))
    }

    public var reverse: Self {
        transformed(residues: Array(residues.reversed()))
    }

    public var reverseComplement: Self {
        transformed(residues: residues.reversed().map(\.complement))
    }

    private func transformed(residues: [Nucleotide]) -> Self {
        var chain = Self(residues: residues, name: name)
        chain.range = range
        chain.parentLength = parentLength
        return chain
    }

    public var formula: Formula {
        guard !residues.isEmpty else { return zeroFormula }

        return residues.reduce(water.formula) { result, residue in
            result + residue.formula + (residue.modification?.formula ?? zeroFormula)
        }
    }

}

extension BioMolecule where ChainType: NucleicAcidChain {
    public var complement: Self {
        Self(chains: chains.map(\.complement))
    }

    public var reverse: Self {
        Self(chains: chains.map(\.reverse))
    }

    public var reverseComplement: Self {
        Self(chains: chains.map(\.reverseComplement))
    }

    public func nucleotide(at location: Int, chainIndex: Int = 0) -> Nucleotide? {
        residue(at: location, chainIndex: chainIndex)
    }

    public func nucleotide(at location: Int, chainName: String) -> Nucleotide? {
        residue(at: location, chainName: chainName)
    }

    public var nucleotides: [Nucleotide] {
        residues
    }

    public func nucleotides(chainIndex: Int) -> [Nucleotide] {
        residues(chainIndex: chainIndex)
    }

    public func nucleotides(chainName: String) -> [Nucleotide]? {
        residues(chainName: chainName)
    }
}
