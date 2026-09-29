//
//  RNA.swift
//  BioSwift
//

import Foundation

public struct RNAChain: NucleicAcidChain, Ionizable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var residues: [Nucleotide]
    public var adducts: [Adduct] = []
    public var range: Range<Int> = zeroRange
    public var parentLength: Int = 0

    public init(sequence: String, name: String = "", id: UUID = UUID()) {
        self.id = id
        self.name = name
        residues = sequence.compactMap { Nucleotide.standard(code: $0, type: .rna) }
    }

    public init(residues: [Nucleotide]) {
        self.init(residues: residues, name: "")
    }

    public init(residues: [Nucleotide], id: UUID) {
        self.init(residues: residues, name: "", id: id)
    }

    public init(residues: [Nucleotide], name: String, id: UUID = UUID()) {
        self.id = id
        self.name = name
        self.residues = residues
    }

    public var complement: RNAChain {
        transformed(residues: residues.map(\.complement))
    }

    public var reverse: RNAChain {
        transformed(residues: Array(residues.reversed()))
    }

    public var reverseComplement: RNAChain {
        transformed(residues: residues.reversed().map(\.complement))
    }

    private func transformed(residues: [Nucleotide]) -> RNAChain {
        var chain = RNAChain(residues: residues, name: name)
        chain.adducts = adducts
        chain.range = range
        chain.parentLength = parentLength
        return chain
    }
}

/// RNA contains one or more nucleotide strands.
public typealias RNA = BioMolecule<RNAChain>

extension BioMolecule where ChainType == RNAChain {
    public var complement: RNA {
        RNA(chains: chains.map(\.complement))
    }

    public var reverse: RNA {
        RNA(chains: chains.map(\.reverse))
    }

    public var reverseComplement: RNA {
        RNA(chains: chains.map(\.reverseComplement))
    }

    public init(sequence: String) {
        self.init(chains: [RNAChain(sequence: sequence)])
    }

    public init(sequences: [String]) {
        self.init(chains: sequences.map { RNAChain(sequence: $0) })
    }

    public init(fastaRecord: FastaRecord) {
        let name = fastaRecord.shortName.isEmpty ? fastaRecord.fullName : fastaRecord.shortName
        self.init(chains: [RNAChain(sequence: fastaRecord.sequence, name: name)])
    }

    public init(residues: [Nucleotide]) {
        self.init(chains: [RNAChain(residues: residues)])
    }

    public func truncate(by range: Range<Int>) -> RNA {
        guard let chain = chains.first?.removing(range) else { return self }
        return RNA(chains: [chain])
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
