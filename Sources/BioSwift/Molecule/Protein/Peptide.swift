//
//  Peptide.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/18/21.
//  Copyright © 2021 - 2026 Koen van der Drift. All rights reserved.
//

import Foundation

/// Peptide conforms to ``Chain`` using an ``AminoAcid`` array

public struct Peptide: AminoAcidChain, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var residues: [AminoAcid] = []
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

    public init(proteinChain: ProteinChain) {
        self.init(proteinChain: proteinChain, id: proteinChain.id)
    }

    init(proteinChain: ProteinChain, id: UUID) {
        self.id = id
        name = proteinChain.name
        residues = proteinChain.residues
        nTerminal = proteinChain.nTerminal
        cTerminal = proteinChain.cTerminal
        range = proteinChain.range
        parentLength = proteinChain.parentLength
    }
}
