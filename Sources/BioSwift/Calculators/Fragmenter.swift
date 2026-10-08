//
//  Fragmenter.swift
//  BioSwift
//
//  Created by Koen van der Drift on 10/8/26.
//  Copyright © 2026 Koen van der Drift. All rights reserved.
//

import Foundation

/// Common behavior for generating charged fragments from a molecular chain.
///
/// Conforming fragmenters supply the domain-specific fragment series while this
/// protocol provides adduct handling, ionization, and fragment lookup.
public protocol Fragmenter {
    associatedtype ChainType: Chain & Structure
    associatedtype FragmentType: FragmentMassAdjusting & Equatable

    var precursor: Ion<ChainType> { get }
    var fragments: [Ion<Fragment<ChainType, FragmentType>>] { get }

    static var defaultFragmentCharge: Charge { get }
}

extension Fragmenter {
    var productAdductCombinations: [[Adduct]] {
        precursor.adductCombinations(maximumAbsoluteCharge: 2)
    }

    func ionize(
        _ fragment: Fragment<ChainType, FragmentType>,
        with adducts: [Adduct]
    ) -> Ion<Fragment<ChainType, FragmentType>>? {
        try? fragment.ionized(with: adducts)
    }

    public func fragment(
        at index: Int,
        for type: FragmentType,
        with charge: Charge
    ) -> Ion<Fragment<ChainType, FragmentType>>? {
        fragments.first {
            $0.structure.fragmentType == type
                && $0.structure.index == index
                && $0.charge == charge
        }
    }

    public func fragment(
        at index: Int,
        for type: FragmentType
    ) -> Ion<Fragment<ChainType, FragmentType>>? {
        fragment(at: index, for: type, with: Self.defaultFragmentCharge)
    }
}
