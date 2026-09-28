//
//  Fragment.swift
//  BioSwift
//
//  Created by Koen van der Drift on 9/28/26.
//  Copyright © 2026 Koen van der Drift. All rights reserved.
//

import Foundation

/// A fragment of a molecular chain together with its fragmentation metadata.
public struct Fragment<ChainType: Chain, FragmentType>: Identifiable {
    public let id: UUID
    public var chain: ChainType
    public var fragmentType: FragmentType
    public var index: Int

    public var sequenceString: String {
        chain.sequenceString
    }

    public var residues: [ChainType.ResidueType] {
        get { chain.residues }
        set { chain.residues = newValue }
    }

    public var adducts: [Adduct] {
        get { chain.adducts }
        set { chain.adducts = newValue }
    }

    public var charge: Charge {
        chain.charge
    }

    public var parentLength: Int {
        get { chain.parentLength }
        set { chain.parentLength = newValue }
    }

    public init(
        chain: ChainType,
        fragmentType: FragmentType,
        index: Int = -1,
        id: UUID = UUID()
    ) {
        self.id = id
        self.chain = chain
        self.fragmentType = fragmentType
        self.index = index
    }
}

extension Fragment: Codable where ChainType: Codable, FragmentType: Codable {}
extension Fragment: Sendable where ChainType: Sendable, FragmentType: Sendable {}
