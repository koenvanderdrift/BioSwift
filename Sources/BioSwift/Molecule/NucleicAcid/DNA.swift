//
//  DNA.swift
//  BioSwift
//

import Foundation

public struct DNAChain: NucleicAcidChain, Ionizable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var residues: [Nucleotide]
    public var adducts: [Adduct] = []
    public var range: Range<Int> = zeroRange
    public var parentLength: Int = 0

    public init(sequence: String, name: String = "", id: UUID = UUID()) throws {
        self.id = id
        self.name = name
        residues = try sequence.enumerated().map { position, character in
            guard let nucleotide = Nucleotide.standard(code: character, type: .dna) else {
                throw BioSwiftDiagnostics.logged(
                    SequenceValidationError.invalidResidue(
                        character, position: position, sequenceType: "DNA"))
            }
            return nucleotide
        }
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

    public var complement: DNAChain {
        transformed(residues: residues.map(\.complement))
    }

    public var reverse: DNAChain {
        transformed(residues: Array(residues.reversed()))
    }

    public var reverseComplement: DNAChain {
        transformed(residues: residues.reversed().map(\.complement))
    }

    private func transformed(residues: [Nucleotide]) -> DNAChain {
        var chain = DNAChain(residues: residues, name: name)
        chain.adducts = adducts
        chain.range = range
        chain.parentLength = parentLength
        return chain
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

    public init(sequence: String) throws {
        self.init(chains: [try DNAChain(sequence: sequence)])
    }

    public init(sequences: [String]) throws {
        self.init(chains: try sequences.map { try DNAChain(sequence: $0) })
    }

    public init(fastaRecord: FastaRecord) throws {
        let name = fastaRecord.shortName.isEmpty ? fastaRecord.fullName : fastaRecord.shortName
        self.init(chains: [try DNAChain(sequence: fastaRecord.sequence, name: name)])
    }

    public init(residues: [Nucleotide]) {
        self.init(chains: [DNAChain(residues: residues)])
    }

    public func truncate(by range: Range<Int>) throws -> DNA {
        guard let chain = chains.first else {
            throw BioSwiftDiagnostics.logged(CrossLinkError.invalidChainIndex(0))
        }
        return DNA(chains: [try chain.removingResidues(in: range)])
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
