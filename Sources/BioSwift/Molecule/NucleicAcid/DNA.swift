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

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case residues
        case range
        case parentLength
    }

    public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(UUID.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            residues = try container.decode([Nucleotide].self, forKey: .residues)
            range = try container.decodeIfPresent(Range<Int>.self, forKey: .range) ?? zeroRange
            parentLength = try container.decodeIfPresent(Int.self, forKey: .parentLength) ?? 0
        } catch {
            throw BioSwiftDiagnostics.loggedDecodingFailure(error, from: decoder)
        }
    }
}

/// DNA contains one or more nucleotide strands.
public typealias DNA = BioMolecule<DNAChain>

