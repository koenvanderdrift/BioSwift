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

    public init(residues: [AminoAcid], name: String, id: UUID) {
        self.id = id
        self.name = name
        self.residues = residues
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case residues
        case nTerminal
        case cTerminal
        case range
        case parentLength
    }

    public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(UUID.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            residues = try container.decode([AminoAcid].self, forKey: .residues)
            nTerminal = try container.decodeIfPresent(Modification.self, forKey: .nTerminal)
                ?? hydrogenModification
            cTerminal = try container.decodeIfPresent(Modification.self, forKey: .cTerminal)
                ?? hydroxylModification
            range = try container.decodeIfPresent(Range<Int>.self, forKey: .range) ?? zeroRange
            parentLength = try container.decodeIfPresent(Int.self, forKey: .parentLength) ?? 0
        } catch {
            throw BioSwiftDiagnostics.loggedDecodingFailure(error, from: decoder)
        }
    }
}
