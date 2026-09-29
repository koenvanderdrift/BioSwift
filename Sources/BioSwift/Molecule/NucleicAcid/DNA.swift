//
//  DNA.swift
//  BioSwift
//

import Foundation

public struct DNAChain: NucleicAcidChain, Ionizable, Codable, Equatable, Sendable {
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
        residues = sequence.compactMap { Nucleotide.standard(code: $0, type: .dna) }
    }

    public init(residues: [Nucleotide]) {
        self.init(residues: residues, id: UUID())
    }

    public init(residues: [Nucleotide], id: UUID) {
        self.id = id
        self.residues = residues
    }

    public var complement: DNAChain {
        DNAChain(residues: residues.map(\.complement))
    }

    public var reverse: DNAChain {
        DNAChain(residues: Array(residues.reversed()))
    }

    public var reverseComplement: DNAChain {
        DNAChain(residues: residues.reversed().map(\.complement))
    }
}

/// DNA contains one or more nucleotide strands.
public typealias DNA = BioMolecule<DNAChain>

extension BioMolecule where ChainType == DNAChain {
    public var complement: DNA {
        DNA(chains: chains.map(\.complement))
    }

    public var reverse: DNA {
        DNA(chains: chains.map(\.reverse))
    }

    public var reverseComplement: DNA {
        DNA(chains: chains.map(\.reverseComplement))
    }

    public init(sequence: String) {
        self.init(chains: [DNAChain(sequence: sequence)])
    }

    public init(sequences: [String]) {
        self.init(chains: sequences.map(DNAChain.init(sequence:)))
    }

    public init(fastaRecord: FastaRecord) {
        var chain = DNAChain(sequence: fastaRecord.sequence)
        chain.name = fastaRecord.shortName.isEmpty ? fastaRecord.fullName : fastaRecord.shortName
        self.init(chains: [chain])
    }

    public init(residues: [Nucleotide]) {
        self.init(chains: [DNAChain(residues: residues)])
    }

    public func truncate(by range: Range<Int>) -> DNA {
        guard let chain = chains.first?.removing(range) else { return self }
        return DNA(chains: [chain])
    }

    public func nucleotide(at location: Int, chainIndex: Int = 0) -> Nucleotide? {
        let values = nucleotides(chainIndex: chainIndex)
        guard values.indices.contains(location) else { return nil }
        return values[location]
    }

    public func nucleotide(at location: Int, chainName: String) -> Nucleotide? {
        guard let values = nucleotides(chainName: chainName), values.indices.contains(location) else {
            return nil
        }
        return values[location]
    }

    public var nucleotides: [Nucleotide] {
        nucleotides(chainIndex: 0)
    }

    public func nucleotides(chainIndex: Int) -> [Nucleotide] {
        residues(chainIndex: chainIndex) as? [Nucleotide] ?? []
    }

    public func nucleotides(chainName: String) -> [Nucleotide]? {
        chain(named: chainName)?.residues
    }
}
