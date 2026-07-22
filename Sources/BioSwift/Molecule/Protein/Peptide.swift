//
//  Peptide.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/18/21.
//  Copyright © 2021 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

/// Peptide conforms to ``Chain`` using an ``AminoAcid`` array

public struct Peptide: Chain, Codable, Equatable, Sendable {
    public var name: String = ""
    public var residues: [AminoAcid] = []
    public var nTerminal: Modification = hydrogenModification
    public var cTerminal: Modification = hydroxylModification
    public var adducts: [Adduct] = []
    public var range: Range<Int> = zeroRange
    public var parentLength: Int = 0

    public init(sequence: String) {
        residues = createResidues(from: sequence)
    }

    public init(residues: [AminoAcid]) {
        self.residues = residues
    }

    public func createResidues(from string: String) -> [AminoAcid] {
        string.compactMap { char in
            aminoAcidLibrary.first(where: { $0.identifier == String(char) })
        }
    }
}

public extension Peptide {
    func hydropathyValues(for hydropathyType: String) -> [Double] {
        let values = Hydropathy(residues: residues).hydrophathyValues(for: hydropathyType)

        return residues.compactMap { values[$0.oneLetterCode] }
    }

    func isoelectricPoint() -> Double {
        return Hydropathy(residues: residues).isoElectricPoint()
    }
}

extension Peptide: Chargeable {
    public var masses: MassContainer {
        massOverCharge()
    }

    public func calculateMasses() -> MassContainer {
        if residues.isEmpty {
            return zeroMass
        }

        return residueMasses() + terminalMasses()
    }

    func residueMasses() -> MassContainer {
        residues.reduce(zeroMass) { $0 + $1.masses }
    }

    func terminalMasses() -> MassContainer {
        return nTerminal.masses + cTerminal.masses
    }
}
