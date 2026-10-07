//
//  CrossLink.swift
//  BioSwift
//

import Foundation

/// Identifies a residue within a molecule independently of chain ordering.
public struct CrossLinkSite: Codable, Equatable, Hashable, Sendable {
    public let chainID: UUID
    public let residueIndex: Int

    public init(chainID: UUID, residueIndex: Int) {
        self.chainID = chainID
        self.residueIndex = residueIndex
    }
}

/// A modification connecting two residues in the same or different chains.
///
/// The modification describes the total elemental change caused by forming the
/// link and is therefore included once in the molecule's formula and mass.
public struct CrossLink: Codable, Equatable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let modification: Modification
    public let firstSite: CrossLinkSite
    public let secondSite: CrossLinkSite

    public init(
        id: UUID = UUID(), modification: Modification,
        firstSite: CrossLinkSite, secondSite: CrossLinkSite
    ) {
        self.id = id
        self.modification = modification
        self.firstSite = firstSite
        self.secondSite = secondSite
    }
}

public enum CrossLinkError: Error, Equatable, Sendable {
    case invalidChainIndex(Int)
    case invalidResidueIndex(chainIndex: Int, residueIndex: Int)
    case identicalSites
}
