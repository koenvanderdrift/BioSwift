//
//  DNA.swift
//  BioSwift
//

import Foundation

public struct DNAChain: NucleicAcidChain, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var residues: [Nucleotide]
    public var range: Range<Int> = zeroRange
    public var parentLength: Int = 0

    public init(sequence: String, name: String = "", id: UUID = UUID()) throws {
        self.id = id
        self.name = name
        residues = try Self.createResidues(from: sequence, type: .dna)
    }

    public init(residues: [Nucleotide], name: String, id: UUID) {
        self.id = id
        self.name = name
        self.residues = residues
    }

}

/// DNA contains one or more nucleotide strands.
public typealias DNA = BioMolecule<DNAChain>

