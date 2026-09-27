//
//  PeptideFragment.swift
//  BioSwift
//
//  Created by Koen van der Drift on 2/17/24.
//  Copyright © 2024 - 2026 Koen van der Drift. All rights reserved.
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
        switch self {
        case .precursorIon, .precursorIonMinusWater, .precursorIonMinusAmmonia:
            true
        default:
            false
        }
    }

    public var isImmonium: Bool {
        self == .immoniumIon
    }

    public var isNTerminal: Bool {
        switch self {
        case .aIon, .aIonMinusWater, .aIonMinusAmmonia,
            .bIon, .bIonMinusWater, .bIonMinusAmmonia, .cIon:
            true
        default:
            false
        }
    }

    public var isCTerminal: Bool {
        switch self {
        case .yIon, .yIonMinusWater, .yIonMinusAmmonia, .xIon, .zIon:
            true
        default:
            false
        }
    }

    var masses: MassContainer {
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

extension Fragmenting {
    public var isPrecursor: Bool {
        fragmentType.isPrecursor
    }

    public var isImmonium: Bool {
        fragmentType.isImmonium
    }

    public var isNTerminal: Bool {
        fragmentType.isNTerminal
    }

    public var isCTerminal: Bool {
        fragmentType.isCTerminal
    }
}

/// PeptideFragment is generated from a ``Peptide`` by ``PeptideFragmenter``
public struct PeptideFragment: AminoAcidChain, Codable, Fragmenting, Sendable {
    public let id: UUID
    public var name: String = ""
    public var residues: [AminoAcid] = []
    public var nTerminal: Modification = zeroModification
    public var cTerminal: Modification = zeroModification
    public var adducts: [Adduct] = []
    public var range: Range<Int> = zeroRange
    public var fragmentType: PeptideFragmentType = .undefined
    public var parentLength: Int = 0
    public var index = -1

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

    public init(residues: [AminoAcid], type: PeptideFragmentType, index: Int = -1, adducts: [Adduct], nTerm: Modification = zeroModification, cTerm: Modification = zeroModification, parentLength: Int = 0, id: UUID = UUID()) {
        self.id = id
        self.residues = residues
        self.fragmentType = type
        self.index = index
        self.adducts = adducts
        self.nTerminal = nTerm
        self.cTerminal = cTerm
        self.parentLength = parentLength
    }
}

extension PeptideFragment: Ionizable {
    public var massContainer: MassContainer {
        masses.applying(adducts: adducts)
    }

    var masses: MassContainer {
        if residues.isEmpty {
            return zeroMass
        }

        return residueMasses() + terminalMasses() + fragmentType.masses
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

    public func maxNumberOfCharges() -> Int {
        return residues.filter { $0.properties.contains(.chargedPositive) }.count
    }
}
