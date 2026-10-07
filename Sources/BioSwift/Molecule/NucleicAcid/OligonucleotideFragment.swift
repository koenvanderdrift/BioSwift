//
//  OligonucleotideFragment.swift
//  BioSwift
//

import Foundation

/// McLuckey nomenclature for terminal fragments of single-stranded oligonucleotides.
public enum OligonucleotideFragmentType: String, CaseIterable, Codable, FragmentMassAdjusting, Identifiable, Sendable {
    case precursorIon
    case aIon
    case aIonMinusBase
    case bIon
    case cIon
    case dIon
    case wIon
    case xIon
    case yIon
    case zIon

    public var id: Self { self }

    public var isPrecursor: Bool { self == .precursorIon }

    public var isFivePrime: Bool {
        switch self {
        case .aIon, .aIonMinusBase, .bIon, .cIon, .dIon: true
        default: false
        }
    }

    public var isThreePrime: Bool {
        switch self {
        case .wIon, .xIon, .yIon, .zIon: true
        default: false
        }
    }

    public func massAdjustment(for residues: [any Residue]) -> MassContainer {
        switch self {
        case .precursorIon:
            zeroMass

        case .aIon, .zIon:
            bIonAdjustment - water.masses

        case .aIonMinusBase:
            bIonAdjustment - water.masses
                - ((residues.last as? Nucleotide)?.nucleobase?.masses ?? zeroMass)

        case .bIon, .yIon:
            bIonAdjustment

        case .cIon, .xIon:
            dIonAdjustment - water.masses

        case .dIon, .wIon:
            dIonAdjustment
        }
    }

    private var dIonAdjustment: MassContainer {
        zeroMass - hydroxyl.masses
    }

    private var bIonAdjustment: MassContainer {
        dIonAdjustment - water.masses - phosphateBackboneAdjustment + hydrogen.masses
    }
}

/// A DNA or RNA chain slice annotated with McLuckey fragmentation metadata.
public typealias OligonucleotideFragment<ChainType: NucleicAcidChain> =
    Fragment<ChainType, OligonucleotideFragmentType>

extension Fragment where ChainType: NucleicAcidChain,
    FragmentType == OligonucleotideFragmentType
{
    public var isPrecursor: Bool { fragmentType.isPrecursor }
    public var isFivePrime: Bool { fragmentType.isFivePrime }
    public var isThreePrime: Bool { fragmentType.isThreePrime }

    /// The nucleobase removed from the final nucleotide of an a−B fragment.
    public var lostBase: Nucleotide? {
        fragmentType == .aIonMinusBase ? residues.last : nil
    }
}

private extension Nucleotide {
    var nucleobase: FunctionalGroup? {
        switch oneLetterCode.uppercased() {
        case "A": adenine
        case "C": cytosine
        case "G": guanine
        case "T": thymine
        case "U": uracil
        default: nil
        }
    }
}

/// The PO₂ composition separating adjacent McLuckey cleavage series. This is a
/// mass delta within the phosphodiester backbone, not a discrete functional group.
private let phosphateBackboneAdjustment = phosphorus.masses + 2 * oxygen.masses
