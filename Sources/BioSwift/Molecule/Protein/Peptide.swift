//
//  Peptide.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/18/21.
//  Copyright © 2021 - 2024 Koen van der Drift. All rights reserved.
//

import Foundation

public struct Peptide: Chain {
    public typealias T = AminoAcid

    public var name: String = ""
    public var residues: [AminoAcid] = []
    public var termini: (first: Modification, last: Modification)?
    public var modifications: [LocalizedModification] = []
    public var adducts: [Adduct] = []
    public var rangeInParent: ChainRange = zeroChainRange
    public var library: [AminoAcid] = aminoAcidLibrary

    public init(sequence: String) {
        self.residues = createResidues(from: sequence)
        self.residues.isEmpty == false ? self.termini = (hydrogenModification, hydroxylModification) : nil
    }

    public init(residues: [AminoAcid]) {
        self.residues = residues
        self.residues.isEmpty == false ? self.termini = (hydrogenModification, hydroxylModification) : nil
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
        calculateMasses()
    }

    public func calculateMasses() -> MassContainer {
        residueMasses() + modificationMasses() + terminalMasses()
    }

    func residueMasses() -> MassContainer {
        residues.reduce(zeroMass) { $0 + $1.masses }
    }

    func modificationMasses() -> MassContainer {
        modifications.reduce(zeroMass) { $0 + $1.modification.masses }
    }

    func terminalMasses() -> MassContainer {
        if let termini {
            return termini.first.masses + termini.last.masses
        }

        return zeroMass
    }
}
