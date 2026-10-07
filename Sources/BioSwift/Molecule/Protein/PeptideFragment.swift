//
//  PeptideFragment.swift
//  BioSwift
//
//  Created by Koen van der Drift on 2/17/24.
//  Copyright © 2024 - 2026 Koen van der Drift. All rights reserved.
//

import Foundation

public enum PeptideFragmentType: CaseIterable, Codable, FragmentMassAdjusting, Identifiable, Sendable {
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

    public func massAdjustment(for residues: [any Residue]) -> MassContainer {
        switch self {
        case .precursorIon:
            return water.masses

        case .precursorIonMinusAmmonia:
            return water.masses - ammonia.masses

        case .aIon:
            return zeroMass - carbonyl.masses - hydrogen.masses

        case .aIonMinusWater:
            return zeroMass - carbonyl.masses - hydrogen.masses - water.masses

        case .aIonMinusAmmonia:
            return zeroMass - carbonyl.masses - hydrogen.masses - ammonia.masses

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

/// A peptide chain annotated with its fragmentation metadata.
public typealias PeptideFragment = Fragment<Peptide, PeptideFragmentType>

extension Fragment where ChainType == Peptide, FragmentType == PeptideFragmentType {
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

    public init(sequence: String) throws {
        try self.init(sequence: sequence, id: UUID())
    }

    public init(sequence: String, id: UUID) throws {
        var peptide = try Peptide(sequence: sequence, id: id)
        peptide.setTermini(nTerm: zeroModification, cTerm: zeroModification)
        self.init(chain: peptide, fragmentType: .undefined, id: id)
    }

    public init(residues: [AminoAcid]) {
        self.init(residues: residues, id: UUID())
    }

    public init(residues: [AminoAcid], id: UUID) {
        var peptide = Peptide(residues: residues, id: id)
        peptide.setTermini(nTerm: zeroModification, cTerm: zeroModification)
        self.init(chain: peptide, fragmentType: .undefined, id: id)
    }

    public init(residues: [AminoAcid], fragmentType: PeptideFragmentType, index: Int = -1, nTerm: Modification = zeroModification, cTerm: Modification = zeroModification, parentLength: Int = 0, id: UUID = UUID()) {
        var peptide = Peptide(residues: residues, id: id)
        peptide.parentLength = parentLength
        peptide.setTermini(nTerm: nTerm, cTerm: cTerm)
        self.init(chain: peptide, fragmentType: fragmentType, index: index, id: id)
    }

    public var nTerminal: Modification {
        get { chain.nTerminal }
        set { chain.nTerminal = newValue }
    }

    public var cTerminal: Modification {
        get { chain.cTerminal }
        set { chain.cTerminal = newValue }
    }

    public var canLoseWater: Bool {
        return sequenceString.containsAnyCharacter(in: "STED")

        //        if fragmentType == .bIon, let last = sequenceString.last {
        //            if "RQNKW".contains(last) {
        //                result = false
        //            }
        //        }
        //
        //        return result
    }

    public var canLoseAmmonia: Bool {
        return sequenceString.containsAnyCharacter(in: "RQNK")
    }

    public var maximumChargeCount: Int {
        return residues.filter { $0.properties.contains(.chargedPositive) }.count
    }
}

extension Ion where StructureType == PeptideFragment {
    public var fragmentType: PeptideFragmentType { structure.fragmentType }
    public var index: Int { structure.index }
    public var residues: [AminoAcid] { structure.residues }
    public var sequenceString: String { structure.sequenceString }
    public var parentLength: Int { structure.parentLength }
    public var isPrecursor: Bool { structure.isPrecursor }
    public var isImmonium: Bool { structure.isImmonium }
    public var isNTerminal: Bool { structure.isNTerminal }
    public var isCTerminal: Bool { structure.isCTerminal }
    public var canLoseWater: Bool { structure.canLoseWater }
    public var canLoseAmmonia: Bool { structure.canLoseAmmonia }
    public var maximumChargeCount: Int { structure.maximumChargeCount }
}
