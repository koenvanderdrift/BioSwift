//
//  PeptideFragment.swift
//  BioSwift
//
//  Created by Koen van der Drift on 2/17/24.
//  Copyright © 2024 Koen van der Drift. All rights reserved.
//

import Foundation

public enum PeptideFragmentType: CaseIterable, Codable {
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

    public var isPrecursor: Bool { [.precursorIon, .precursorIonMinusWater, .precursorIonMinusAmmonia].contains(self) }
    public var isImmonium: Bool { [.immoniumIon].contains(self) }
    public var isNTerminal: Bool { [.aIon, .aIonMinusWater, .aIonMinusAmmonia, .bIon, .bIonMinusWater, .bIonMinusAmmonia, .cIon].contains(self) }
    public var isCTerminal: Bool { [.yIon, .yIonMinusWater, .yIonMinusAmmonia, .xIon, .zIon].contains(self) }

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

        default:
            return zeroMass
        }
    }
}

public protocol Fragmenting {
    var fragmentType: PeptideFragmentType { get set }
    var index: Int { get set }
}

public struct PeptideFragment: Chain, Codable, Fragmenting {
    public var name: String = ""
    public var sequence: String = ""
    public var residues: [AminoAcid] = []
    public var nTerminal: Modification = zeroModification
    public var cTerminal: Modification = zeroModification
    public var modifications: [LocalizedModification] = []
    public var adducts: [Adduct] = []
    public var rangeInParent: ChainRange = zeroChainRange
    public var library: [AminoAcid] = aminoAcidLibrary
    public var fragmentType: PeptideFragmentType = .undefined
    public var index = -1

    public init(sequence: String) {
        self.sequence = sequence
        self.residues = createResidues(from: sequence)
    }

    public init(residues: [AminoAcid]) {
        self.residues = residues
    }

    public init(residues: [AminoAcid], type: PeptideFragmentType, index: Int = -1, adducts: [Adduct], modifications: [LocalizedModification] = [], nTerm: Modification = zeroModification, cTerm: Modification = zeroModification) {
        self.residues = residues
        self.fragmentType = type
        self.index = index
        self.adducts = adducts
        self.modifications = modifications
        self.nTerminal = nTerm
        self.cTerminal = cTerm
    }

    public func createResidues(from string: String) -> [AminoAcid] {
        string.compactMap { char in
            aminoAcidLibrary.first(where: { $0.identifier == String(char) })
        }
    }
}

extension PeptideFragment: Chargeable {
    public var masses: MassContainer {
        calculateMasses()
    }

    public func calculateMasses() -> MassContainer {
        residueMasses() + modificationMasses() + terminalMasses() + fragmentType.masses
    }

    func residueMasses() -> MassContainer {
        residues.reduce(zeroMass) { $0 + $1.masses }
    }

    func modificationMasses() -> MassContainer {
        modifications.reduce(zeroMass) { $0 + $1.modification.masses }
    }

    func terminalMasses() -> MassContainer {
        return nTerminal.masses + cTerminal.masses
    }
}

public extension PeptideFragment {
    func canLoseWater() -> Bool {
        return sequenceString.containsCharactersFrom(substring: "STED")

//        if fragmentType == .bIon, let last = sequenceString.last {
//            if "RQNKW".contains(last) {
//                result = false
//            }
//        }
//
//        return result
    }

    func canLoseAmmonia() -> Bool {
        return sequenceString.containsCharactersFrom(substring: "RQNK")
    }

    func isPrecursor() -> Bool {
        return fragmentType.isPrecursor
    }

    func isImmonium() -> Bool {
        return fragmentType.isImmonium
    }

    func isNterminal() -> Bool {
        return fragmentType.isNTerminal
    }

    func isCterminal() -> Bool {
        return fragmentType.isCTerminal
    }

    func maxNumberOfCharges() -> Int {
        // if let aa = residues as? [AminoAcid] {
        return residues.filter { $0.properties.contains([.chargedPos]) }.count
        // }

        // return 0
    }
}
