//
//  PeptideFragment.swift
//  BioSwift
//
//  Created by Koen van der Drift on 2/17/24.
//  Copyright © 2024 Koen van der Drift. All rights reserved.
//

import Foundation

public enum PeptideFragmentType: CaseIterable {
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

        case .bIonMinusWater:
            return zeroMass - water.masses

        case .bIonMinusAmmonia:
            return zeroMass - ammonia.masses

        case .cIon:
            return ammonia.masses

        case .yIon:
            return water.masses

        case .yIonMinusAmmonia:
            return water.masses - ammonia.masses

        case .xIon:
            return water.masses + carbonyl.masses - 2 * hydrogen.masses

        case .zIon:
            return water.masses - ammonia.masses + hydrogen.masses

        default:
            return zeroMass
        }
    }
}

public protocol Fragmenting {
    var fragmentType: PeptideFragmentType { get set }
    var index: Int { get set }
}

public typealias PeptideFragment = Chain<AminoAcid>

extension PeptideFragment: Fragmenting {
    init(residues: [AminoAcid], type: PeptideFragmentType, index: Int = -1, adducts: [Adduct], modifications: [LocalizedModification] = []) {
        self.residues = residues
        self.fragmentType = type
        self.index = index
        self.adducts = adducts
        self.modifications = modifications
    }

    init(sequence: String) {
        self.sequence = sequence
        self.residues = createResidues(from: sequence)
    }

    init(residues: [T]) {
        self.residues = residues
    }

    func calculateMasses() -> MassContainer {
        residueMasses() + modificationMasses() + terminalMasses() + fragmentType.masses
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
        //if let aa = residues as? [AminoAcid] {
            return residues.filter { $0.properties.contains([.chargedPos]) }.count
        //}

        //return 0
    }
}

//public struct PeptideFragment: Chain {
//    public var rangeInParent: ChainRange = zeroChainRange
//    public var name: String = ""
//    public var termini: (first: Modification, last: Modification)?
//    public var residues: [Residue] = []
//    public var adducts: [Adduct] = []
//    public var fragmentType: PeptideFragmentType = .undefined
//    public var index: Int = -1
//    public var modifications: [LocalizedModification] = []
//
//    public var aminoAcids: [AminoAcid] {
//        residues as? [AminoAcid] ?? []
//    }
//}

