//
//  OligonucleotideFragmenter.swift
//  BioSwift
//

// References:
// McLuckey SA, van Berkel GJ, Glish GL. Tandem Mass Spectrometry of Small,
// Multiply Charged Oligonucleotides. J Am Soc Mass Spectrom. 1992;3:60–70.
// https://doi.org/10.1016/1044-0305(92)85019-G
//
// Hannauer F et al. Review of fragmentation of synthetic single-stranded
// oligonucleotides by tandem mass spectrometry from 2014 to 2022.
// Rapid Commun Mass Spectrom. 2023;37:e9596.
// https://doi.org/10.1002/rcm.9596
//
// Mongo Oligo Mass Calculator v2.07, used to validate a−B, w, y, and d−H₂O
// monoisotopic product-ion masses:
// https://asog.iecb.u-bordeaux.fr/oligomass/

import Foundation

/// Calculates McLuckey terminal product ions from an explicitly charged oligonucleotide.
public final class OligonucleotideFragmenter<ChainType: NucleicAcidChain> {
    public let precursor: Ion<ChainType>

    public init(precursor: Ion<ChainType>) {
        self.precursor = precursor
    }

    public var oligonucleotide: ChainType { precursor.structure }

    private var productAdductCombinations: [[Adduct]] {
        precursor.adductCombinations(maximumAbsoluteCharge: 2)
    }

    public lazy var fragments: [Ion<OligonucleotideFragment<ChainType>>] =
        precursorIons() + fivePrimeIons() + threePrimeIons()

    private func ionize(
        _ fragment: OligonucleotideFragment<ChainType>,
        with adducts: [Adduct]
    ) -> Ion<OligonucleotideFragment<ChainType>>? {
        try? fragment.ionized(with: adducts)
    }

    public func precursorIons() -> [Ion<OligonucleotideFragment<ChainType>>] {
        let fragment = OligonucleotideFragment(
            chain: fragmentChain(
                residues: oligonucleotide.residues,
                range: oligonucleotide.residues.startIndex..<oligonucleotide.residues.endIndex),
            fragmentType: .precursorIon)

        return ionize(fragment, with: precursor.adducts).map { [$0] } ?? []
    }

    public func fivePrimeIons() -> [Ion<OligonucleotideFragment<ChainType>>] {
        guard !productAdductCombinations.isEmpty, oligonucleotide.residues.count > 1 else {
            return []
        }

        let fragmentTypes: [OligonucleotideFragmentType] = [
            .aIon, .aIonMinusBase, .bIon, .cIon, .dIon,
        ]
        var result: [Ion<OligonucleotideFragment<ChainType>>] = []

        for adducts in productAdductCombinations {
            for index in 1..<oligonucleotide.residues.count {
                let range = oligonucleotide.residues.startIndex..<index
                let chain = fragmentChain(
                    residues: Array(oligonucleotide.residues[range]),
                    range: range)

                for type in fragmentTypes {
                    let fragment = OligonucleotideFragment(
                        chain: chain,
                        fragmentType: type,
                        index: index)
                    if let product = ionize(fragment, with: adducts) {
                        result.append(product)
                    }
                }
            }
        }

        return result
    }

    public func threePrimeIons() -> [Ion<OligonucleotideFragment<ChainType>>] {
        guard !productAdductCombinations.isEmpty, oligonucleotide.residues.count > 1 else {
            return []
        }

        let fragmentTypes: [OligonucleotideFragmentType] = [.wIon, .xIon, .yIon, .zIon]
        var result: [Ion<OligonucleotideFragment<ChainType>>] = []
        let endIndex = oligonucleotide.residues.endIndex

        for adducts in productAdductCombinations {
            for index in 1..<oligonucleotide.residues.count {
                let startIndex = oligonucleotide.residues.index(endIndex, offsetBy: -index)
                let range = startIndex..<endIndex
                let chain = fragmentChain(
                    residues: Array(oligonucleotide.residues[range]),
                    range: range)

                for type in fragmentTypes {
                    let fragment = OligonucleotideFragment(
                        chain: chain,
                        fragmentType: type,
                        index: index)
                    if let product = ionize(fragment, with: adducts) {
                        result.append(product)
                    }
                }
            }
        }

        return result
    }

    public func fragment(
        at index: Int,
        for type: OligonucleotideFragmentType,
        with charge: Charge = -1
    ) -> Ion<OligonucleotideFragment<ChainType>>? {
        fragments.first {
            $0.structure.fragmentType == type
                && $0.structure.index == index
                && $0.charge == charge
        }
    }

    private func fragmentChain(residues: [Nucleotide], range: Range<Int>) -> ChainType {
        var chain = ChainType(residues: residues)
        chain.name = oligonucleotide.name
        chain.range = range
        chain.parentLength = oligonucleotide.residueCount
        return chain
    }
}
