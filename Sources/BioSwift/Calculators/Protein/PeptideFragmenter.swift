//
//  PeptideFragmenter.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/19/21.
//  Copyright © 2021 - 2026 Koen van der Drift. All rights reserved.
//

import Foundation

/// PeptideFragmenter calculates the common y- and b-type fragment ions for a ``Peptide``
/// The fragments are stored in an array of ``PeptideFragment``
///
public class PeptideFragmenter {
    // http://www.matrixscience.com/help/fragmentation_help.html

    public let peptide: Peptide

    public init(peptide: Peptide) {
        self.peptide = peptide
    }

    /// Positive adduct combinations supported by the fragment generator, preserving
    /// the precursor's actual adduct composition and charge.
    private var fragmentAdductStates: [[Adduct]] {
        let positiveAdducts = peptide.adducts.filter { $0.charge > 0 }
        var states: [[Adduct]] = []

        func addCombinations(startingAt index: Int, current: [Adduct], charge: Charge) {
            for adductIndex in index..<positiveAdducts.count {
                let adduct = positiveAdducts[adductIndex]
                let updatedCharge = charge + adduct.charge

                guard updatedCharge <= 2 else {
                    continue
                }

                let combination = current + [adduct]
                if states.contains(combination) == false {
                    states.append(combination)
                }

                addCombinations(
                    startingAt: adductIndex + 1,
                    current: combination,
                    charge: updatedCharge
                )
            }
        }

        addCombinations(startingAt: 0, current: [], charge: 0)
        return states.sorted { lhs, rhs in
            let lhsCharge = lhs.reduce(0) { $0 + $1.charge }
            let rhsCharge = rhs.reduce(0) { $0 + $1.charge }
            return lhsCharge < rhsCharge
        }
    }

    public lazy var fragments: [PeptideFragment] =
        precursorIons() + immoniumIons() + nTerminalIons() + cTerminalIons()

    func precursorIons() -> [PeptideFragment] {
        var result: [PeptideFragment] = []

        let precursorIon = PeptideFragment(
            residues: peptide.residues, fragmentType: .precursorIon, adducts: peptide.adducts)
        result.append(precursorIon)

        if precursorIon.canLoseWater {
            let precursorIonLossOfWater = PeptideFragment(
                residues: peptide.residues, fragmentType: .precursorIonMinusWater, adducts: peptide.adducts)
            result.append(precursorIonLossOfWater)
        }

        if precursorIon.canLoseAmmonia {
            let precursorIonLossOfAmmonia = PeptideFragment(
                residues: peptide.residues, fragmentType: .precursorIonMinusAmmonia,
                adducts: peptide.adducts)
            result.append(precursorIonLossOfAmmonia)
        }

        return result.map { fragment in
            var updatedFragment = fragment
            updatedFragment.parentLength = peptide.residueCount
            return updatedFragment
        }
    }

    func immoniumIons() -> [PeptideFragment] {
        guard let symbols = peptide.symbolSet as? Set<AminoAcid> else {
            return []
        }

        return symbols.map { symbol -> PeptideFragment in
            PeptideFragment(
                residues: [symbol], fragmentType: .immoniumIon, adducts: peptide.adducts,
                parentLength: peptide.parentLength)
        }
    }

    func nTerminalIons() -> [PeptideFragment] {
        var result = [PeptideFragment]()

        guard fragmentAdductStates.isEmpty == false else {
            return result
        }
        guard let firstResidue = peptide.residues.first else {
            return result
        }

        let startIndex = peptide.residues.startIndex

        for adducts in fragmentAdductStates {
            let charge = adducts.reduce(0) { $0 + $1.charge }
            // add c1
            let cIon = PeptideFragment(
                residues: [firstResidue], fragmentType: .cIon, index: 1,
                adducts: adducts, nTerm: peptide.nTerminal)

            if cIon.residues[0].oneLetterCode != "P" {
                if charge == 1 {
                    result.append(cIon)
                } else {
                    if cIon.monoisotopicMass
                        > peptide.monoisotopicMass
                    {
                        result.append(cIon)
                    }
                }
            }

            guard peptide.residues.count > 2 else {
                continue
            }

            for i in 2...peptide.residues.count - 1 {
                let index = peptide.residues.index(startIndex, offsetBy: i)

                let bIon = PeptideFragment(
                    residues: Array(peptide.residues[..<index]), fragmentType: .bIon, index: index,
                    adducts: adducts, nTerm: peptide.nTerminal)

                if charge == 1 {
                    result.append(bIon)
                } else {
                    if bIon.index == peptide.residues.count - 1 {
                        result.append(bIon)
                    }
                }

                if bIon.canLoseWater {
                    let bIonLossOfWater = PeptideFragment(
                        residues: bIon.residues, fragmentType: .bIonMinusWater, index: index,
                        adducts: bIon.adducts, nTerm: peptide.nTerminal)
                    if charge == 1 {
                        result.append(bIonLossOfWater)
                    } else {
                        if bIonLossOfWater.index == peptide.residues.count - 1 {
                            result.append(bIonLossOfWater)
                        }
                    }
                }

                if bIon.canLoseAmmonia {
                    let bIonLossOfAmmonia = PeptideFragment(
                        residues: bIon.residues, fragmentType: .bIonMinusAmmonia, index: index,
                        adducts: bIon.adducts, nTerm: peptide.nTerminal)
                    if charge == 1 {
                        result.append(bIonLossOfAmmonia)
                    } else {
                        if bIonLossOfAmmonia.index == peptide.residues.count - 1 {
                            result.append(bIonLossOfAmmonia)
                        }
                    }
                }

                let aIon = PeptideFragment(
                    residues: bIon.residues, fragmentType: .aIon, index: index, adducts: bIon.adducts,
                    nTerm: peptide.nTerminal)

                if charge == 1 {
                    result.append(aIon)
                } else {
                    if aIon.index == peptide.residues.count - 1 {
                        result.append(aIon)
                    }
                }

                if aIon.canLoseWater {
                    let aIonLossOfWater = PeptideFragment(
                        residues: bIon.residues, fragmentType: .aIonMinusWater, index: index,
                        adducts: bIon.adducts, nTerm: peptide.nTerminal)
                    if charge == 1 {
                        result.append(aIonLossOfWater)
                    } else {
                        if aIonLossOfWater.index == peptide.residues.count - 1 {
                            result.append(aIonLossOfWater)
                        }
                    }
                }

                if aIon.sequenceString.contains("Q") {
                    let aIonLossOfAmmonia = PeptideFragment(
                        residues: bIon.residues, fragmentType: .aIonMinusAmmonia, index: index,
                        adducts: bIon.adducts, nTerm: peptide.nTerminal)
                    if charge == 1 {
                        result.append(aIonLossOfAmmonia)
                    } else {
                        if aIonLossOfAmmonia.index == peptide.residues.count - 1 {
                            result.append(aIonLossOfAmmonia)
                        }
                    }
                }

                let cIon = PeptideFragment(
                    residues: bIon.residues, fragmentType: .cIon, index: index,
                    adducts: bIon.adducts,
                    nTerm: peptide.nTerminal)

                if cIon.residues.last?.oneLetterCode != "P" {
                    if charge == 1 {
                        result.append(cIon)
                    } else {
                        if cIon.index == peptide.residues.count - 1 {
                            result.append(cIon)
                        }
                    }
                }
            }
        }

        return result.map { fragment in
            var updatedFragment = fragment
            updatedFragment.parentLength = peptide.residueCount
            return updatedFragment
        }
    }

    func cTerminalIons() -> [PeptideFragment] {
        var result = [PeptideFragment]()

        guard fragmentAdductStates.isEmpty == false else {
            return result
        }
        guard peptide.residues.count > 1 else {
            return result
        }

        let endIndex = peptide.residues.endIndex

        for adducts in fragmentAdductStates {
            for i in (1...peptide.residues.count - 1).reversed() {
                let index = peptide.residues.index(endIndex, offsetBy: -i)

                let yIon = PeptideFragment(
                    residues: Array(peptide.residues[index..<endIndex]), fragmentType: .yIon, index: i,
                    adducts: adducts, cTerm: peptide.cTerminal)
                result.append(yIon)

                if i > 1, yIon.canLoseWater {
                    let yIonLossOfWater = PeptideFragment(
                        residues: yIon.residues, fragmentType: .yIonMinusWater, index: i,
                        adducts: yIon.adducts, cTerm: peptide.cTerminal)
                    result.append(yIonLossOfWater)
                }

                if yIon.canLoseAmmonia {
                    let yIonLossOfAmmonia = PeptideFragment(
                        residues: yIon.residues, fragmentType: .yIonMinusAmmonia, index: i,
                        adducts: yIon.adducts, cTerm: peptide.cTerminal)
                    result.append(yIonLossOfAmmonia)
                }

                let xIon = PeptideFragment(
                    residues: yIon.residues, fragmentType: .xIon, index: i,
                    adducts: yIon.adducts,
                    cTerm: peptide.cTerminal)
                result.append(xIon)

                let zIon = PeptideFragment(
                    residues: yIon.residues, fragmentType: .zIon, index: i,
                    adducts: yIon.adducts,
                    cTerm: peptide.cTerminal)

                if zIon.residues.first?.oneLetterCode != "P" {
                    result.append(zIon)
                }
            }
        }

        return result.reversed().map { fragment in
            var updatedFragment = fragment
            updatedFragment.parentLength = peptide.residueCount
            return updatedFragment
        }
    }

    public func fragment(at index: Int, for type: PeptideFragmentType, with charge: Charge = 1)
        -> PeptideFragment?
    {
        guard precursorIons().isEmpty == false else {
            return nil
        }

        let ions = fragments.filter {
            $0.fragmentType == type
        }

        return ions.filter {
            $0.index == index && $0.charge == charge
        }.first
    }
}
