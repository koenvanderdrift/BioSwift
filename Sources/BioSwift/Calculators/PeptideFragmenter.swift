//
//  PeptideFragmenter.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/19/21.
//  Copyright © 2021 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

public class PeptideFragmenter {
    // http://www.matrixscience.com/help/fragmentation_help.html

    public let peptide: Peptide

    public init(peptide: Peptide) {
        self.peptide = peptide
    }

    public lazy var fragments: [PeptideFragment] = precursorIons() + immoniumIons() + nTerminalIons() + cTerminalIons()

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
            let cIon = PeptideFragment(residues: [peptide.residues[0]], type: .cIon, index: 1, adducts: Array(repeatElement(protonAdduct, count: z)), modifications: peptide.modifications, nTerm: peptide.nTerminal)

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

                let bIon = PeptideFragment(residues: Array(peptide.residues[..<index]), type: .bIon, index: index, adducts: Array(repeatElement(protonAdduct, count: z)), modifications: peptide.modifications, nTerm: peptide.nTerminal)

                if z == 1 {
                    result.append(bIon)
                } else {
                    if bIon.index == peptide.residues.count - 1 {
                        result.append(bIon)
                    }
                }

                if bIon.canLoseWater() {
                    let bIonLossOfWater = PeptideFragment(residues: bIon.residues, type: .bIonMinusWater, index: index, adducts: bIon.adducts, modifications: peptide.modifications, nTerm: peptide.nTerminal)
                    if z == 1 {
                        result.append(bIonLossOfWater)
                    } else {
                        if bIonLossOfWater.index == peptide.residues.count - 1 {
                            result.append(bIonLossOfWater)
                        }
                    }
                }

                if bIon.canLoseAmmonia() {
                    let bIonLossOfAmmonia = PeptideFragment(residues: bIon.residues, type: .bIonMinusAmmonia, index: index, adducts: bIon.adducts, modifications: peptide.modifications, nTerm: peptide.nTerminal)
                    if z == 1 {
                        result.append(bIonLossOfAmmonia)
                    } else {
                        if bIonLossOfAmmonia.index == peptide.residues.count - 1 {
                            result.append(bIonLossOfAmmonia)
                        }
                    }
                }

                let aIon = PeptideFragment(residues: bIon.residues, type: .aIon, adducts: bIon.adducts, modifications: peptide.modifications, nTerm: peptide.nTerminal)

                if z == 1 {
                    result.append(aIon)
                } else {
                    if aIon.index == peptide.residues.count - 1 {
                        result.append(aIon)
                    }
                }

                if aIon.canLoseWater() {
                    let aIonLossOfWater = PeptideFragment(residues: bIon.residues, type: .aIonMinusWater, index: index, adducts: bIon.adducts, modifications: peptide.modifications, nTerm: peptide.nTerminal)
                    if z == 1 {
                        result.append(aIonLossOfWater)
                    } else {
                        if aIonLossOfWater.index == peptide.residues.count - 1 {
                            result.append(aIonLossOfWater)
                        }
                    }
                }

                if aIon.sequenceString.contains("Q") {
                    let aIonLossOfAmmonia = PeptideFragment(residues: bIon.residues, type: .aIonMinusAmmonia, index: index, adducts: bIon.adducts, modifications: peptide.modifications, nTerm: peptide.nTerminal)
                    if z == 1 {
                        result.append(aIonLossOfAmmonia)
                    } else {
                        if aIonLossOfAmmonia.index == peptide.residues.count - 1 {
                            result.append(aIonLossOfAmmonia)
                        }
                    }
                }

                let cIon = PeptideFragment(residues: bIon.residues, type: .cIon, index: index, adducts: bIon.adducts, modifications: peptide.modifications, nTerm: peptide.nTerminal)

                if cIon.residues.last?.oneLetterCode != "P" {
                    if z == 1 {
                        result.append(cIon)
                    } else {
                        if cIon.index == peptide.residues.count - 1 {
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

                let yIon = PeptideFragment(residues: Array(peptide.residues[index ..< endIndex]), type: .yIon, index: i, adducts: Array(repeatElement(protonAdduct, count: z)), modifications: peptide.modifications, cTerm: peptide.cTerminal)
                result.append(yIon)

                if i > 1, yIon.canLoseWater() {
                    let yIonLossOfWater = PeptideFragment(residues: yIon.residues, type: .yIonMinusWater, index: i, adducts: yIon.adducts, modifications: peptide.modifications, cTerm: peptide.cTerminal)
                    result.append(yIonLossOfWater)
                }

                if yIon.canLoseAmmonia() {
                    let yIonLossOfAmmonia = PeptideFragment(residues: yIon.residues, type: .yIonMinusAmmonia, index: i, adducts: yIon.adducts, modifications: peptide.modifications, cTerm: peptide.cTerminal)
                    result.append(yIonLossOfAmmonia)
                }

                let xIon = PeptideFragment(residues: yIon.residues, type: .xIon, index: i, adducts: yIon.adducts, modifications: peptide.modifications, cTerm: peptide.cTerminal)
                result.append(xIon)

                let zIon = PeptideFragment(residues: yIon.residues, type: .zIon, index: i, adducts: yIon.adducts, modifications: peptide.modifications, cTerm: peptide.cTerminal)

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
