//
//  RNA.swift
//  BioSwift
//

import Foundation

public struct RNAChain: NucleicAcidChain, Ionizable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String = ""
    public var residues: [Nucleotide]
    public var adducts: [Adduct] = []
    public var range: Range<Int> = zeroRange
    public var parentLength: Int = 0

    public init(sequence: String) {
        self.init(sequence: sequence, id: UUID())
    }

    public init(sequence: String, id: UUID) {
        self.id = id
        residues = sequence.compactMap { Nucleotide.standard(code: $0, type: .rna) }
    }

    public init(residues: [Nucleotide]) {
        self.init(residues: residues, id: UUID())
    }

    public init(residues: [Nucleotide], id: UUID) {
        self.id = id
        self.residues = residues
    }

    public var complement: RNAChain {
        RNAChain(residues: residues.map(\.complement))
    }

    public var reverseComplement: RNAChain {
        RNAChain(residues: residues.reversed().map(\.complement))
    }
}

/// RNA contains one or more nucleotide strands.
public typealias RNA = BioMolecule<RNAChain>

extension BioMolecule where ChainType == RNAChain {
    public init(sequence: String) {
        self.init(chains: [RNAChain(sequence: sequence)])
    }

    public init(sequences: [String]) {
        self.init(chains: sequences.map(RNAChain.init(sequence:)))
    }

    public init(fastaRecord: FastaRecord) {
        var chain = RNAChain(sequence: fastaRecord.sequence)
        chain.name = fastaRecord.shortName.isEmpty ? fastaRecord.fullName : fastaRecord.shortName
        self.init(chains: [chain])
    }

    public init(residues: [Nucleotide]) {
        self.init(chains: [RNAChain(residues: residues)])
    }

    public func truncate(by range: Range<Int>) -> RNA {
        guard let chain = chains.first?.removing(range) else { return self }
        return RNA(chains: [chain])
    }

    public func nucleotide(at location: Int, for chainIndex: Int = 0) -> Nucleotide? {
        let values = nucleotides(for: chainIndex)
        guard values.indices.contains(location) else { return nil }
        return values[location]
    }

    public func nucleotides(for chainIndex: Int = 0) -> [Nucleotide] {
        residues(for: chainIndex) as? [Nucleotide] ?? []
    }
}
