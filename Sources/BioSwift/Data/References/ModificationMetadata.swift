//
//  ModificationMetadata.swift
//  BioSwift
//

import Foundation

public struct TaxonomicRange: Codable, Hashable, Sendable {
    public let name: String
    public let taxonIdentifier: Int

    public init(name: String, taxonIdentifier: Int) {
        self.name = name
        self.taxonIdentifier = taxonIdentifier
    }
}

public struct ModificationCrossReference: Codable, Hashable, Sendable {
    public let database: String
    public let identifier: String

    public init(database: String, identifier: String) {
        self.database = database
        self.identifier = identifier
    }
}

public struct ModificationMetadata: Codable, Sendable {
    public let taxonomicRanges: [TaxonomicRange]
    public let keywords: [String]
    public let cellularLocations: [String]
    public let crossReferences: [ModificationCrossReference]

    public init(
        taxonomicRanges: [TaxonomicRange] = [],
        keywords: [String] = [],
        cellularLocations: [String] = [],
        crossReferences: [ModificationCrossReference] = []
    ) {
        self.taxonomicRanges = taxonomicRanges
        self.keywords = keywords
        self.cellularLocations = cellularLocations
        self.crossReferences = crossReferences
    }
}

