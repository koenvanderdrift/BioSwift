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

    public init(sequence: String, name: String = "", id: UUID = UUID()) throws {
        self.id = id
        self.name = name
        residues = try sequence.enumerated().map { position, character in
            guard let nucleotide = Nucleotide.standard(code: character, type: .rna) else {
                throw BioSwiftDiagnostics.logged(
                    SequenceValidationError.invalidResidue(
                        character, position: position, sequenceType: "RNA"))
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

    public init(sequence: String) throws {
        self.init(chains: [try RNAChain(sequence: sequence)])
    }

    public init(sequences: [String]) throws {
        self.init(chains: try sequences.map { try RNAChain(sequence: $0) })
    }

    public init(fastaRecord: FastaRecord) throws {
        let name = fastaRecord.shortName.isEmpty ? fastaRecord.fullName : fastaRecord.shortName
        self.init(chains: [try RNAChain(sequence: fastaRecord.sequence, name: name)])
    }

    public init(residues: [Nucleotide]) {
        self.init(chains: [RNAChain(residues: residues)])
    }

    public func truncate(by range: Range<Int>) throws -> RNA {
        guard let chain = chains.first else {
            throw BioSwiftDiagnostics.logged(CrossLinkError.invalidChainIndex(0))
        }
        return RNA(chains: [try chain.removingResidues(in: range)])
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
