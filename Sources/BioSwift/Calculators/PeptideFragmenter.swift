//
//  PeptideFragmenter.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/19/21.
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

        let precursorIon = PeptideFragment(residues: peptide.aminoAcids, type: .precursorIon, adducts: peptide.adducts)
        result.append(precursorIon)

        if precursorIon.canLoseWater() {
            let precursorIonLossOfWater = PeptideFragment(residues: peptide.aminoAcids, type: .precursorIonMinusWater, adducts: peptide.adducts)
            result.append(precursorIonLossOfWater)
        }

        if precursorIon.canLoseAmmonia() {
            let precursorIonLossOfAmmonia = PeptideFragment(residues: peptide.aminoAcids, type: .precursorIonMinusAmmonia, adducts: peptide.adducts)
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
            let cIon = PeptideFragment(residues: [peptide.aminoAcids[0]], type: .cIon, index: 1, adducts: Array(repeatElement(protonAdduct, count: z)))

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

                let bIon = PeptideFragment(residues: Array(peptide.aminoAcids[..<index]), type: .bIon, index: index, adducts: Array(repeatElement(protonAdduct, count: z)), modifications: peptide.modifications)

                if z == 1 {
                    result.append(bIon)
                } else {
                    if bIon.index == peptide.residues.count - 1 {
                        result.append(bIon)
                    }
                }

                if bIon.canLoseWater() {
                    let bIonLossOfWater = PeptideFragment(residues: bIon.aminoAcids, type: .bIonMinusWater, index: index, adducts: bIon.adducts)
                    if z == 1 {
                        result.append(bIonLossOfWater)
                    } else {
                        if bIonLossOfWater.index == peptide.residues.count - 1 {
                            result.append(bIonLossOfWater)
                        }
                    }
                }

                if bIon.canLoseAmmonia() {
                    let bIonLossOfAmmonia = PeptideFragment(residues: bIon.aminoAcids, type: .bIonMinusAmmonia, index: index, adducts: bIon.adducts)
                    if z == 1 {
                        result.append(bIonLossOfAmmonia)
                    } else {
                        if bIonLossOfAmmonia.index == peptide.residues.count - 1 {
                            result.append(bIonLossOfAmmonia)
                        }
                    }
                }

                let aIon = PeptideFragment(residues: bIon.aminoAcids, type: .aIon, adducts: bIon.adducts)

                if z == 1 {
                    result.append(aIon)
                } else {
                    if aIon.index == peptide.residues.count - 1 {
                        result.append(aIon)
                    }
                }

                if aIon.canLoseWater() {
                    let aIonLossOfWater = PeptideFragment(residues: bIon.aminoAcids, type: .aIonMinusWater, index: index, adducts: bIon.adducts)
                    if z == 1 {
                        result.append(aIonLossOfWater)
                    } else {
                        if aIonLossOfWater.index == peptide.residues.count - 1 {
                            result.append(aIonLossOfWater)
                        }
                    }
                }

                if aIon.sequenceString.contains("Q") {
                    let aIonLossOfAmmonia = PeptideFragment(residues: bIon.aminoAcids, type: .aIonMinusAmmonia, index: index, adducts: bIon.adducts)
                    if z == 1 {
                        result.append(aIonLossOfAmmonia)
                    } else {
                        if aIonLossOfAmmonia.index == peptide.residues.count - 1 {
                            result.append(aIonLossOfAmmonia)
                        }
                    }
                }

                let cIon = PeptideFragment(residues: bIon.aminoAcids, type: .cIon, index: index, adducts: bIon.adducts)

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

                let yIon = PeptideFragment(residues: Array(peptide.aminoAcids[index ..< endIndex]), type: .yIon, index: i, adducts: Array(repeatElement(protonAdduct, count: z)))
                result.append(yIon)

                if i > 1 && yIon.canLoseWater() {
                    let yIonLossOfWater = PeptideFragment(residues: yIon.aminoAcids, type: .yIonMinusWater, index: i, adducts: yIon.adducts)
                    result.append(yIonLossOfWater)
                }

                if yIon.canLoseAmmonia() {
                    let yIonLossOfAmmonia = PeptideFragment(residues: yIon.aminoAcids, type: .yIonMinusAmmonia, index: i, adducts: yIon.adducts)
                    result.append(yIonLossOfAmmonia)
                }

                let xIon = PeptideFragment(residues: yIon.aminoAcids, type: .xIon, index: i, adducts: yIon.adducts)
                result.append(xIon)

                let zIon = PeptideFragment(residues: yIon.aminoAcids, type: .zIon, index: i, adducts: yIon.adducts)

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

