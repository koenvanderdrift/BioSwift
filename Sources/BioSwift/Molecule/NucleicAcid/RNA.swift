//
//  RNA.swift
//  BioSwift
//

import Foundation

public struct RNAChain: NucleicAcidChain, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var residues: [Nucleotide]
    public var range: Range<Int> = zeroRange
    public var parentLength: Int = 0

    public init(sequence: String, name: String = "", id: UUID = UUID()) throws {
        self.id = id
        self.name = name
        residues = try Self.createResidues(from: sequence, type: .rna)
    }

    public init(residues: [Nucleotide], name: String, id: UUID) {
        self.id = id
        self.name = name
        self.residues = residues
    }

}

/// RNA contains one or more nucleotide strands.
public typealias RNA = BioMolecule<RNAChain>

