//
//  PeptideFragment.swift
//  BioSwift
//
//  Created by Koen van der Drift on 2/17/24.
//  Copyright © 2024 Koen van der Drift. All rights reserved.
//

import Foundation

public enum PeptideFragmentType: CaseIterable, Codable, Identifiable, Sendable {
    case precursorIon
    case precursorIonMinusWater
    case precursorIonMinusAmmonia
    case immoniumIon
    case aIon
    case aIonMinusWater
    case aIonMinusAmmonia
    case bIon
    case bIonMinusWater
    case bIonMinusAmmonia
    case cIon
    case yIon
    case yIonMinusWater
    case yIonMinusAmmonia
    case xIon
    case zIon
    case undefined

    public var id: Self {
        self
    }

    public var isPrecursor: Bool {
        [.precursorIon, .precursorIonMinusWater, .precursorIonMinusAmmonia].contains(self)
    }

    public var isImmonium: Bool {
        [.immoniumIon].contains(self)
    }

    public var isNTerminal: Bool {
        [
            .aIon, .aIonMinusWater, .aIonMinusAmmonia, .bIon, .bIonMinusWater, .bIonMinusAmmonia,
            .cIon,
        ].contains(self)
    }

    public var isCTerminal: Bool {
        [.yIon, .yIonMinusWater, .yIonMinusAmmonia, .xIon, .zIon].contains(self)
    }

    public var masses: MassContainer {
        switch self {
        case .precursorIon:
            return water.masses

        case .precursorIonMinusAmmonia:
            return water.masses - ammonia.masses

        case .aIon:
            return zeroMass - carbonyl.masses

        case .aIonMinusWater:
            return zeroMass - carbonyl.masses + water.masses

        case .aIonMinusAmmonia:
            return zeroMass - carbonyl.masses + ammonia.masses

        case .bIon:
            return zeroMass - hydrogen.masses

        case .bIonMinusWater:
            return zeroMass - water.masses - hydrogen.masses

        case .bIonMinusAmmonia:
            return zeroMass - ammonia.masses - hydrogen.masses

        case .cIon:
            return ammonia.masses - hydrogen.masses

        case .yIon:
            return hydrogen.masses

        case .yIonMinusWater:
            return hydrogen.masses - water.masses

        case .yIonMinusAmmonia:
            return hydrogen.masses - ammonia.masses

        case .xIon:
            return carbonyl.masses - hydrogen.masses

        case .zIon:
            return zeroMass - ammonia.masses + 2 * hydrogen.masses

        default: return zeroMass
        }
    }
}

public protocol Fragmenting {
    var fragmentType: PeptideFragmentType {
        get set
    }

    var index: Int {
        get set
    }
}

/// PeptideFragment is generated from a ``Peptide`` by ``PeptideFragmenter``
public struct PeptideFragment: Chain, Codable, Fragmenting, Sendable {
    public var name: String = ""
    public var sequence: String = ""
    public var residues: [AminoAcid] = []
    public var nTerminal: Modification = zeroModification
    public var cTerminal: Modification = zeroModification
    public var adducts: [Adduct] = []
    public var range: Range<Int> = zeroRange
    public var fragmentType: PeptideFragmentType = .undefined
    public var parentLength: Int = 0
    public var index = -1

    public init(sequence: String) {
        self.init(sequence: sequence, aminoAcids: AminoAcidReferenceDefaults.bundled)
    }

    public init(
        sequence: String,
        aminoAcids: AminoAcidReferences
    ) {
        self.sequence = sequence
        residues = Self.createResidues(from: sequence, aminoAcids: aminoAcids)
    }

    public init(residues: [AminoAcid]) {
        self.residues = residues
    }

    public init(
        residues: [AminoAcid], type: PeptideFragmentType, index: Int = -1, adducts: [Adduct],
        nTerm: Modification = zeroModification, cTerm: Modification = zeroModification,
        parentLength: Int = 0
    ) {
        self.residues = residues
        self.fragmentType = type
        self.index = index
        self.adducts = adducts
        self.nTerminal = nTerm
        self.cTerminal = cTerm
        self.parentLength = parentLength
    }

    private static func createResidues(
        from string: String,
        aminoAcids: AminoAcidReferences
    ) -> [AminoAcid] {
        string.compactMap {
            char in aminoAcids.aminoAcid(identifier: String(char))
        }
    }
}

extension PeptideFragment: Ionizable {
    public var masses: MassContainer {
        massOverCharge()
    }

    public func calculateMasses() -> MassContainer {
        if residues.isEmpty {
            return zeroMass
        }

        return residueMasses() + terminalMasses() + fragmentType.masses  // + modificationMasses()
    }

    func residueMasses() -> MassContainer { residues.reduce(zeroMass) { $0 + $1.masses } }

    func terminalMasses() -> MassContainer {
        nTerminal.masses + cTerminal.masses
    }
}

extension PeptideFragment {
    public func canLoseWater() -> Bool {
        return sequenceString.containsAnyCharacter(in: "STED")

        //        if fragmentType == .bIon, let last = sequenceString.last {
        //            if "RQNKW".contains(last) {
        //                result = false
        //            }
        //        }
        //
        //        return result
    }

    public func canLoseAmmonia() -> Bool {
        return sequenceString.containsAnyCharacter(in: "RQNK")
    }

    public func isPrecursor() -> Bool {
        return fragmentType.isPrecursor
    }

    public func isImmonium() -> Bool {
        return fragmentType.isImmonium
    }

    public func isNterminal() -> Bool {
        return fragmentType.isNTerminal
    }

    public func isCterminal() -> Bool {
        return fragmentType.isCTerminal
    }

    public func maxNumberOfCharges() -> Int {
        // if let aa = residues as? [AminoAcid] {
        return residues.filter { $0.properties.contains(.chargedPositive) }.count  // }

        // return 0
    }
}
