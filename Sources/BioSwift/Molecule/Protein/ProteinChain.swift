//
//  ProteinChain.swift
//  BioSwift
//

import Foundation

/// A polypeptide chain belonging to a protein.
public struct ProteinChain: AminoAcidChain, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var residues: [AminoAcid]
    public var nTerminal: Modification = hydrogenModification
    public var cTerminal: Modification = hydroxylModification
    public var range: Range<Int> = zeroRange
    public var parentLength: Int = 0

    public init(sequence: String, name: String = "", id: UUID = UUID()) throws {
        self.id = id
        self.name = name
        residues = try Self.createResidues(from: sequence)
    }

    public init(residues: [AminoAcid]) {
        self.init(residues: residues, name: "")
    }

    public init(residues: [AminoAcid], name: String, id: UUID = UUID()) {
        self.id = id
        self.name = name
        self.residues = residues
    }
}
