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
    public var name: String = ""
    public var residues: [AminoAcid] = []
    public var nTerminal: Modification = hydrogenModification
    public var cTerminal: Modification = hydroxylModification
    public var adducts: [Adduct] = []
    public var range: Range<Int> = zeroRange
    public var parentLength: Int = 0

    public init(sequence: String) {
        self.init(sequence: sequence, id: UUID())
    }

    public init(sequence: String, id: UUID) {
        self.id = id
        residues = Self.createResidues(from: sequence)
    }

    public init(residues: [AminoAcid]) {
        self.init(residues: residues, id: UUID())
    }

    public init(residues: [AminoAcid], id: UUID) {
        self.id = id
        self.residues = residues
    }
}

extension Peptide: Ionizable {
    public var masses: MassContainer {
        massOverCharge()
    }

    public func calculateMasses() -> MassContainer {
        if residues.isEmpty {
            return zeroMass
        }

        return aminoAcidResidueMasses() + terminalMasses()
    }

}
