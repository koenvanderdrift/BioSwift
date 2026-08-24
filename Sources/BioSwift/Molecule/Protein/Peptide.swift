//
//  Peptide.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/18/21.
//  Copyright © 2021 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

/// Peptide conforms to ``Chain`` using an ``AminoAcid`` array

public struct Peptide: AminoAcidChain, Codable, Equatable, Sendable {
    public var name: String = ""
    public var residues: [AminoAcid] = []
    public var nTerminal: Modification = hydrogenModification
    public var cTerminal: Modification = hydroxylModification
    public var adducts: [Adduct] = []
    public var range: Range<Int> = zeroRange
    public var parentLength: Int = 0

    public init(sequence: String) {
        self.init(sequence: sequence, aminoAcids: AminoAcidReferenceDefaults.bundled)
    }

    public init(sequence: String, aminoAcids: AminoAcidReferences) {
        residues = Self.createResidues(from: sequence, aminoAcids: aminoAcids)
    }

    public init(residues: [AminoAcid]) {
        self.residues = residues
    }

    private static func createResidues(from string: String, aminoAcids: AminoAcidReferences) -> [AminoAcid] {
        string.compactMap {
            char in aminoAcids.aminoAcid(identifier: String(char))
        }
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
