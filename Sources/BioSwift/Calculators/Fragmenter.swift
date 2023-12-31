//
//  Fragmenter.swift
//
//
//  Created by Koen van der Drift on 7/19/21.
//

import Foundation

public enum PeptideFragmentType { // this is only for peptides...
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
}

public class PeptideFragmenter {
    public let peptide: Peptide

    public lazy var fragments: [PeptideFragment] = precursorIons() + immoniumIons() + nTerminalIons() + cTerminalIons()

    public init(peptide: Peptide) {
        self.peptide = peptide
    }

    public func fragment() -> [PeptideFragment] {
        // http://www.matrixscience.com/help/fragmentation_help.html
        precursorIons() + immoniumIons() + nTerminalIons() + cTerminalIons()
    }

    func precursorIons() -> [PeptideFragment] {
        var result: [PeptideFragment] = []

        let precursorIon = PeptideFragment(residues: peptide.residues, type: .precursorIon, adducts: peptide.adducts)
        result.append(precursorIon)

        if precursorIon.canLoseWater() {
            let precursorIonLossOfWater = PeptideFragment(residues: peptide.residues, type: .precursorIonMinusWater, adducts: peptide.adducts)
            result.append(precursorIonLossOfWater)
        }

        if precursorIon.canLoseAmmonia() {
            let precursorIonLossOfAmmonia = PeptideFragment(residues: peptide.residues, type: .precursorIonMinusAmmonia, adducts: peptide.adducts)
            result.append(precursorIonLossOfAmmonia)
        }

        return result
    }

    func immoniumIons() -> [PeptideFragment] {
        guard let symbols = peptide.symbolSet as? Set<AminoAcid> else { return [] }

        let result = symbols.map { symbol -> PeptideFragment in
            PeptideFragment(residues: [symbol], type: .immoniumIon, adducts: peptide.adducts)
        }

        return result
    }

    func nTerminalIons() -> [PeptideFragment] {
        var result = [PeptideFragment]()

        guard peptide.adducts.count > 0 else { return result }

        let startIndex = peptide.residues.startIndex

        for z in 1 ... min(2, peptide.adducts.count) {
            // add c1
            let cIon = PeptideFragment(residues: [peptide.residues[0]], type: .cIon, index: 1, adducts: Array(repeatElement(protonAdduct, count: z)))

            if cIon.residues[0].oneLetterCode != "P" {
                if z == 1 {
                    result.append(cIon)
                } else {
                    if cIon.pseudomolecularIon().monoisotopicMass > peptide.pseudomolecularIon().monoisotopicMass {
                        result.append(cIon)
                    }
                }
            }

            for i in 2 ... peptide.residues.count - 1 {
                let index = peptide.residues.index(startIndex, offsetBy: i)

                let bIon = PeptideFragment(residues: Array(peptide.residues[..<index]), type: .bIon, index: index, adducts: Array(repeatElement(protonAdduct, count: z)), modifications: peptide.modifications)

                if z == 1 {
                    result.append(bIon)
                } else {
                    if bIon.index == peptide.residues.count {
                        result.append(bIon)
                    }
                }

                if bIon.canLoseWater() {
                    let bIonLossOfWater = PeptideFragment(residues: bIon.residues, type: .bIonMinusWater, index: index, adducts: bIon.adducts)
                    result.append(bIonLossOfWater)
                }

                if bIon.canLoseAmmonia() {
                    let bIonLossOfAmmonia = PeptideFragment(residues: bIon.residues, type: .bIonMinusAmmonia, index: index, adducts: bIon.adducts)
                    result.append(bIonLossOfAmmonia)
                }

                let aIon = PeptideFragment(residues: bIon.residues, type: .aIon, adducts: bIon.adducts)

                if z == 1 {
                    result.append(aIon)
                } else {
                    if aIon.pseudomolecularIon().monoisotopicMass > peptide.pseudomolecularIon().monoisotopicMass {
                        result.append(aIon)
                    }
                }

                if aIon.canLoseWater() {
                    let aIonLossOfWater = PeptideFragment(residues: bIon.residues, type: .aIonMinusWater, index: index, adducts: bIon.adducts)
                    result.append(aIonLossOfWater)
                }

                if aIon.sequenceString.contains("Q") {
                    let aIonLossOfAmmonia = PeptideFragment(residues: bIon.residues, type: .aIonMinusAmmonia, index: index, adducts: bIon.adducts)
                    result.append(aIonLossOfAmmonia)
                }

                let cIon = PeptideFragment(residues: bIon.residues, type: .cIon, index: index, adducts: bIon.adducts)

                if cIon.residues.last?.oneLetterCode != "P" {
                    if z == 1 {
                        result.append(cIon)
                    } else {
                        if cIon.pseudomolecularIon().monoisotopicMass > peptide.pseudomolecularIon().monoisotopicMass {
                            result.append(cIon)
                        }
                    }
                }
                
            }
        }
        return result
    }

    func cTerminalIons() -> [PeptideFragment] {
        var result = [PeptideFragment]()

        guard peptide.adducts.count > 0 else { return result }

        let endIndex = peptide.residues.endIndex

        for z in 1 ... min(2, peptide.adducts.count) {
            for i in (1 ... peptide.residues.count - 1).reversed() {
                let index = peptide.residues.index(endIndex, offsetBy: -i)

                let yIon = PeptideFragment(residues: Array(peptide.residues[index ..< endIndex]), type: .yIon, index: i, adducts: Array(repeatElement(protonAdduct, count: z)))
                result.append(yIon)

                if i > 1 && yIon.canLoseWater() {
                    let yIonLossOfWater = PeptideFragment(residues: yIon.residues, type: .yIonMinusWater, index: i, adducts: yIon.adducts)
                    result.append(yIonLossOfWater)
                }

                if yIon.canLoseAmmonia() {
                    let yIonLossOfAmmonia = PeptideFragment(residues: yIon.residues, type: .yIonMinusAmmonia, index: i, adducts: yIon.adducts)
                    result.append(yIonLossOfAmmonia)
                }

                let xIon = PeptideFragment(residues: yIon.residues, type: .xIon, index: i, adducts: yIon.adducts)
                result.append(xIon)

                let zIon = PeptideFragment(residues: yIon.residues, type: .zIon, index: i, adducts: yIon.adducts)

                if zIon.residues.first?.oneLetterCode != "P" {
                    result.append(zIon)
                }
            }
        }

        return result.reversed()
    }

    public func fragment(at index: Int, for type: PeptideFragmentType, with charge: Int = 1) -> PeptideFragment? {
        guard precursorIons().isEmpty == false else { return nil }

        let ions = fragments.filter { $0.fragmentType == type }

        return ions.filter { $0.index == index && $0.charge == charge }.first
    }
}

public struct PeptideFragment: RangedChain {
    public var name: String = ""
    public var symbolLibrary: [Symbol] = aminoAcidLibrary

    public var residues: [AminoAcid] = []

    public var termini: (first: AminoAcid, last: AminoAcid)? = (nTerm, cTerm)
    public var adducts: [Adduct] = []
    public var modifications: [LocalizedModification] = []

    public var rangeInParent: ChainRange = zeroChainRange

    public var fragmentType: PeptideFragmentType = .undefined
    public var index: Int = -1
}

public extension PeptideFragment {
    init(sequence: String) {
        self.residues = createResidues(from: sequence)
    }

    init(residues: [AminoAcid]) {
        self.residues = residues
    }

    init(residues: [AminoAcid], type: PeptideFragmentType, index: Int = -1, adducts: [Adduct], modifications: [LocalizedModification] = []) {
        self.residues = residues
        self.fragmentType = type
        self.index = index
        self.adducts = adducts
        self.modifications = modifications
    }
}

public extension PeptideFragment {
    var masses: MassContainer {
        calculateMasses()
    }

    func calculateMasses() -> MassContainer {
        var result = mass(of: residues) + modificationMasses() + terminalMasses()
        
        switch fragmentType {
            
        case .precursorIon:
            result += water.masses
            
        case .precursorIonMinusWater:
            result += zeroMass

        case .precursorIonMinusAmmonia:
            result += (water.masses - ammonia.masses)

        case .immoniumIon:
            result += zeroMass

        case .aIon:
            result -= carbonyl.masses

        case .aIonMinusWater:
            result -= (carbonyl.masses + water.masses)

        case .aIonMinusAmmonia:
            result -= (carbonyl.masses + ammonia.masses)

        case .bIon:
            result += zeroMass

        case .bIonMinusWater:
            result -= water.masses

        case .bIonMinusAmmonia:
            result -= ammonia.masses

        case .cIon:
            result += ammonia.masses

        case .yIon:
            result += water.masses

        case .yIonMinusWater:
            result += zeroMass

        case .yIonMinusAmmonia:
            result += (water.masses - ammonia.masses)

        case .xIon:
            result += (water.masses + carbonyl.masses - 2 * hydrogen.masses)

        case .zIon:
            result += (water.masses - ammonia.masses + hydrogen.masses)

        case .undefined:
            result += zeroMass

        }

        return result
    }

    func terminalMasses() -> MassContainer {
        return zeroMass
    }

    func canLoseWater() -> Bool {
        var result = sequenceString.containsCharactersFrom(substring: "STED")

        if fragmentType == .bIon, let last = sequenceString.last {
            if "RQNKW".contains(last) {
                result = false
            }
        }

        return result
    }

    func canLoseAmmonia() -> Bool {
        return sequenceString.containsCharactersFrom(substring: "RQNK")
    }
}
