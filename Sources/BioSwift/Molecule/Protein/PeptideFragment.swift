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

    var neutralMasses: MassContainer {
        switch self {
        case .precursorIon:
            return water.neutralMasses

        case .precursorIonMinusAmmonia:
            return water.neutralMasses - ammonia.neutralMasses

        case .aIon:
            return zeroMass - carbonyl.neutralMasses

        case .aIonMinusWater:
            return zeroMass - carbonyl.neutralMasses + water.neutralMasses

        case .aIonMinusAmmonia:
            return zeroMass - carbonyl.neutralMasses + ammonia.neutralMasses

        case .bIon:
            return zeroMass - hydrogen.neutralMasses

        case .bIonMinusWater:
            return zeroMass - water.neutralMasses - hydrogen.neutralMasses

        case .bIonMinusAmmonia:
            return zeroMass - ammonia.neutralMasses - hydrogen.neutralMasses

        case .cIon:
            return ammonia.neutralMasses - hydrogen.neutralMasses

        case .yIon:
            return hydrogen.neutralMasses

        case .yIonMinusWater:
            return hydrogen.neutralMasses - water.neutralMasses

        case .yIonMinusAmmonia:
            return hydrogen.neutralMasses - ammonia.neutralMasses

        case .xIon:
            return carbonyl.neutralMasses - hydrogen.neutralMasses

        case .zIon:
            return zeroMass - ammonia.neutralMasses + 2 * hydrogen.neutralMasses

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
public struct PeptideFragment: AminoAcidChain, Codable, Fragmenting, Sendable {
    public let id: UUID
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
        self.init(sequence: sequence, id: UUID())
    }

    public init(sequence: String, id: UUID) {
        self.id = id
        self.sequence = sequence
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
    public var monoisotopicMass: Dalton {
        neutralMasses.applying(adducts: adducts).monoisotopicMass
    }

    public var averageMass: Dalton {
        neutralMasses.applying(adducts: adducts).averageMass
    }

    public var nominalMass: Int {
        neutralMasses.applying(adducts: adducts).nominalMass
    }

    var neutralMasses: MassContainer {
        if residues.isEmpty {
            return zeroMass
        }

        return residueMasses() + terminalMasses() + fragmentType.neutralMasses
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
        return residues.filter { $0.properties.contains(.chargedPositive) }.count
    }
}
