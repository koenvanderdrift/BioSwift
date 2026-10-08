//
//  PeptideFragmenter.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/19/21.
//  Copyright © 2021 - 2026 Koen van der Drift. All rights reserved.
//

import Foundation

/// Calculates common peptide product ions from an explicitly charged precursor ion.
public final class PeptideFragmenter: Fragmenter {
    public typealias ChainType = Peptide
    public typealias FragmentType = PeptideFragmentType

    public static var defaultFragmentCharge: Charge { 1 }

    public let precursor: Ion<Peptide>

    public init(precursor: Ion<Peptide>) {
        self.precursor = precursor
    }

    public var peptide: Peptide { precursor.structure }

    public lazy var fragments: [Ion<PeptideFragment>] =
        precursorIons() + immoniumIons() + nTerminalIons() + cTerminalIons()

    func precursorIons() -> [Ion<PeptideFragment>] {
        let precursorFragment = PeptideFragment(
            residues: peptide.residues,
            fragmentType: .precursorIon,
            parentLength: peptide.residueCount)

        var neutralFragments = [precursorFragment]
        if precursorFragment.canLoseWater {
            neutralFragments.append(PeptideFragment(
                residues: peptide.residues,
                fragmentType: .precursorIonMinusWater,
                parentLength: peptide.residueCount))
        }
        if precursorFragment.canLoseAmmonia {
            neutralFragments.append(PeptideFragment(
                residues: peptide.residues,
                fragmentType: .precursorIonMinusAmmonia,
                parentLength: peptide.residueCount))
        }

        return neutralFragments.compactMap { ionize($0, with: precursor.adducts) }
    }

    func immoniumIons() -> [Ion<PeptideFragment>] {
        guard let symbols = peptide.symbolSet as? Set<AminoAcid> else { return [] }

        return symbols.compactMap { symbol in
            ionize(
                PeptideFragment(
                    residues: [symbol],
                    fragmentType: .immoniumIon,
                    parentLength: peptide.parentLength),
                with: precursor.adducts)
        }
    }

    func nTerminalIons() -> [Ion<PeptideFragment>] {
        guard !productAdductCombinations.isEmpty, let firstResidue = peptide.residues.first else {
            return []
        }

        var result: [Ion<PeptideFragment>] = []
        let startIndex = peptide.residues.startIndex

        for adducts in productAdductCombinations {
            let charge = adducts.reduce(0) { $0 + $1.charge }
            let c1 = PeptideFragment(
                residues: [firstResidue], fragmentType: .cIon, index: 1,
                nTerm: peptide.nTerminal, parentLength: peptide.residueCount)
            if c1.residues[0].oneLetterCode != "P", let c1Ion = ionize(c1, with: adducts) {
                if charge == 1 || c1Ion.monoisotopicMass > peptide.monoisotopicMass {
                    result.append(c1Ion)
                }
            }

            guard peptide.residues.count > 2 else { continue }

            for i in 2...peptide.residues.count - 1 {
                let index = peptide.residues.index(startIndex, offsetBy: i)
                let residues = Array(peptide.residues[..<index])

                func append(_ type: PeptideFragmentType, when condition: Bool = true) {
                    guard condition else { return }
                    let fragment = PeptideFragment(
                        residues: residues, fragmentType: type, index: index,
                        nTerm: peptide.nTerminal, parentLength: peptide.residueCount)
                    guard charge == 1 || fragment.index == peptide.residues.count - 1,
                          let product = ionize(fragment, with: adducts)
                    else { return }
                    result.append(product)
                }

                let base = PeptideFragment(
                    residues: residues, fragmentType: .bIon, index: index,
                    nTerm: peptide.nTerminal, parentLength: peptide.residueCount)
                append(.bIon)
                append(.bIonMinusWater, when: base.canLoseWater)
                append(.bIonMinusAmmonia, when: base.canLoseAmmonia)
                append(.aIon)
                append(.aIonMinusWater, when: base.canLoseWater)
                append(.aIonMinusAmmonia, when: base.sequenceString.contains("Q"))
                append(.cIon, when: base.residues.last?.oneLetterCode != "P")
            }
        }

        return result
    }

    func cTerminalIons() -> [Ion<PeptideFragment>] {
        guard !productAdductCombinations.isEmpty, peptide.residues.count > 1 else { return [] }

        var result: [Ion<PeptideFragment>] = []
        let endIndex = peptide.residues.endIndex

        for adducts in productAdductCombinations {
            for i in (1...peptide.residues.count - 1).reversed() {
                let index = peptide.residues.index(endIndex, offsetBy: -i)
                let residues = Array(peptide.residues[index..<endIndex])

                func append(_ type: PeptideFragmentType, when condition: Bool = true) {
                    guard condition else { return }
                    let fragment = PeptideFragment(
                        residues: residues, fragmentType: type, index: i,
                        cTerm: peptide.cTerminal, parentLength: peptide.residueCount)
                    if let product = ionize(fragment, with: adducts) {
                        result.append(product)
                    }
                }

                let base = PeptideFragment(
                    residues: residues, fragmentType: .yIon, index: i,
                    cTerm: peptide.cTerminal, parentLength: peptide.residueCount)
                append(.yIon)
                append(.yIonMinusWater, when: i > 1 && base.canLoseWater)
                append(.yIonMinusAmmonia, when: base.canLoseAmmonia)
                append(.xIon)
                append(.zIon, when: base.residues.first?.oneLetterCode != "P")
            }
        }

        return result.reversed()
    }

}
