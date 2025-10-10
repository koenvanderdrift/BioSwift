//
//  Peptide.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/18/21.
//  Copyright © 2021 - 2024 Koen van der Drift. All rights reserved.
//

import Foundation

public typealias Peptide = Chain<AminoAcid>

public extension Peptide {
    func hydropathyValues(for hydropathyType: String) -> [Double] {
        let values = Hydropathy(residues: residues).hydrophathyValues(for: hydropathyType)

        return residues.compactMap { values[$0.oneLetterCode] }
    }

    func isoelectricPoint() -> Double {
        return Hydropathy(residues: residues).isoElectricPoint()
    }
}

// public struct Peptide: Chain {
//    public var rangeInParent: ChainRange = zeroChainRange
//    public var name: String = ""
//    public var termini: (first: Modification, last: Modification)? = (nTermModification, cTermModification)
//    public var modifications: [LocalizedModification] = []
//    public var residues: [Residue] = []
//    public var adducts: [Adduct] = []
//
//    public func createResidues(from string: String) -> [Residue] {
//        string.compactMap { char in
//            aminoAcidLibrary.first(where: { $0.identifier == String(char) })
//        }
//    }
//
//    public var aminoAcids: [AminoAcid] {
//        residues as? [AminoAcid] ?? []
//    }
// }
//
