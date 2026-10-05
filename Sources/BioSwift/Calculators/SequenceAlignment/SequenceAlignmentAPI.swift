//
//  SequenceAlignmentAPI.swift
//  BioSwift
//

import Foundation

public enum AlignmentError: Error, Equatable, Sendable {
    case invalidFirstChainIndex(Int)
    case invalidSecondChainIndex(Int)
}

extension Chain {
    /// Aligns this chain with another chain of the same concrete type.
    public func align(
        with other: Self,
        algorithm: AlignmentAlgorithm,
        scoring: AlignmentScoring
    ) -> AlignmentResult {
        SequenceAligner.align(
            residues.map(\.identifier),
            with: other.residues.map(\.identifier),
            algorithm: algorithm,
            scoring: scoring
        )
    }
}

extension NucleicAcidChain {
    /// Aligns two DNA or two RNA chains using nucleotide scoring.
    public func align(
        with other: Self,
        algorithm: AlignmentAlgorithm = .needlemanWunsch
    ) -> AlignmentResult {
        align(with: other, algorithm: algorithm, scoring: .nucleotide())
    }
}

extension AminoAcidChain {
    /// Aligns two amino-acid chains using BLOSUM62 scoring.
    public func align(
        with other: Self,
        algorithm: AlignmentAlgorithm = .needlemanWunsch
    ) -> AlignmentResult {
        align(with: other, algorithm: algorithm, scoring: .blosum62())
    }
}

extension BioMolecule {
    /// Aligns selected chains from two molecules of the same concrete type.
    public func align(
        with other: Self,
        chainIndex: Int = 0,
        otherChainIndex: Int = 0,
        algorithm: AlignmentAlgorithm,
        scoring: AlignmentScoring
    ) throws -> AlignmentResult {
        guard chains.indices.contains(chainIndex) else {
            throw BioSwiftDiagnostics.logged(AlignmentError.invalidFirstChainIndex(chainIndex))
        }
        guard other.chains.indices.contains(otherChainIndex) else {
            throw BioSwiftDiagnostics.logged(AlignmentError.invalidSecondChainIndex(otherChainIndex))
        }

        return chains[chainIndex].align(
            with: other.chains[otherChainIndex],
            algorithm: algorithm,
            scoring: scoring
        )
    }
}

extension BioMolecule where ChainType: NucleicAcidChain {
    /// Aligns selected chains from two DNA or two RNA molecules using nucleotide scoring.
    public func align(
        with other: Self,
        chainIndex: Int = 0,
        otherChainIndex: Int = 0,
        algorithm: AlignmentAlgorithm = .needlemanWunsch
    ) throws -> AlignmentResult {
        try align(
            with: other,
            chainIndex: chainIndex,
            otherChainIndex: otherChainIndex,
            algorithm: algorithm,
            scoring: .nucleotide()
        )
    }
}

extension BioMolecule where ChainType: AminoAcidChain {
    /// Aligns selected chains from two proteins using BLOSUM62 scoring.
    public func align(
        with other: Self,
        chainIndex: Int = 0,
        otherChainIndex: Int = 0,
        algorithm: AlignmentAlgorithm = .needlemanWunsch
    ) throws -> AlignmentResult {
        try align(
            with: other,
            chainIndex: chainIndex,
            otherChainIndex: otherChainIndex,
            algorithm: algorithm,
            scoring: .blosum62()
        )
    }
}
