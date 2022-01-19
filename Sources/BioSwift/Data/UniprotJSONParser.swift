//
//  UniprotJSONParser.swift
//  BioSwift
//
//  Created by Koen van der Drift on 1/19/22.
//  Copyright © 2022 Koen van der Drift. All rights reserved.
//


// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   public let entry = try? newJSONDecoder().decode(Entry.self, from: jsonData)

import Foundation

// MARK: - Entry
public struct Entry: Codable {
    public let entryType, primaryAccession: String
    public let secondaryAccessions: [String]
    public let uniProtkbID: String
    public let entryAudit: EntryAudit
    public let annotationScore: Double
    public let organism: Organism
    public let proteinExistence: String
    public let proteinDescription: ProteinDescription
    public let genes: [Gene]
    public let comments: [Comment]
    public let features: [Feature]
    public let keywords: [Keyword]
    public let references: [Reference]
    public let uniProtKBCrossReferences: [UniProtKBCrossReference]
    public let sequence: Sequence
    public let extraAttributes: ExtraAttributes

    enum CodingKeys: String, CodingKey {
        case entryType, primaryAccession, secondaryAccessions
        case uniProtkbID = "uniProtkbId"
        case entryAudit, annotationScore, organism, proteinExistence, proteinDescription, genes, comments, features, keywords, references, uniProtKBCrossReferences, sequence, extraAttributes
    }
}

// MARK: - Comment
public struct Comment: Codable {
    public let texts: [GeneName]?
    public let commentType: String
    public let note: Note?
    public let subcellularLocations: [SubcellularLocation]?
}

// MARK: - Note
public struct Note: Codable {
    public let texts: [GeneName]
}

// MARK: - GeneName
public struct GeneName: Codable {
    public let evidences: [Evidence]
    public let value: String
}

// MARK: - Evidence
public struct Evidence: Codable {
    public let evidenceCode: EvidenceCode
    public let source: Source?
    public let id: String?
}

public enum EvidenceCode: String, Codable {
    case eco0000269 = "ECO:0000269"
    case eco0000303 = "ECO:0000303"
    case eco0000305 = "ECO:0000305"
    case eco0000312 = "ECO:0000312"
}

public enum Source: String, Codable {
    case embl = "EMBL"
    case pubMed = "PubMed"
}

// MARK: - SubcellularLocation
public struct SubcellularLocation: Codable {
    public let location, topology: TopologyClass
}

// MARK: - TopologyClass
public struct TopologyClass: Codable {
    public let evidences: [Evidence]
    public let value, id: String
}

// MARK: - EntryAudit
public struct EntryAudit: Codable {
    public let firstPublicDate, lastAnnotationUpdateDate, lastSequenceUpdateDate: String
    public let entryVersion, sequenceVersion: Int
}

// MARK: - ExtraAttributes
public struct ExtraAttributes: Codable {
    public let countByCommentType: CountByCommentType
    public let countByFeatureType: CountByFeatureType
    public let uniPARCID: String

    enum CodingKeys: String, CodingKey {
        case countByCommentType, countByFeatureType
        case uniPARCID = "uniParcId"
    }
}

// MARK: - CountByCommentType
public struct CountByCommentType: Codable {
    public let function, subcellularLocation, developmentalStage, ptm: Int
    public let miscellaneous, caution: Int

    enum CodingKeys: String, CodingKey {
        case function = "FUNCTION"
        case subcellularLocation = "SUBCELLULAR LOCATION"
        case developmentalStage = "DEVELOPMENTAL STAGE"
        case ptm = "PTM"
        case miscellaneous = "MISCELLANEOUS"
        case caution = "CAUTION"
    }
}

// MARK: - CountByFeatureType
public struct CountByFeatureType: Codable {
    public let signal, chain, propeptide, lipidation: Int
    public let glycosylation, disulfideBond: Int

    enum CodingKeys: String, CodingKey {
        case signal = "Signal"
        case chain = "Chain"
        case propeptide = "Propeptide"
        case lipidation = "Lipidation"
        case glycosylation = "Glycosylation"
        case disulfideBond = "Disulfide bond"
    }
}

// MARK: - Feature
public struct Feature: Codable {
    public let type: String
    public let location: FeatureLocation
    public let featureDescription: String
    public let evidences: [Evidence]?
    public let featureID: String?

    enum CodingKeys: String, CodingKey {
        case type, location
        case featureDescription = "description"
        case evidences
        case featureID = "featureId"
    }
}

// MARK: - FeatureLocation
public struct FeatureLocation: Codable {
    public let start, end: End
}

// MARK: - End
public struct End: Codable {
    public let value: Int
    public let modifier: Modifier
}

public enum Modifier: String, Codable {
    case exact = "EXACT"
}

// MARK: - Gene
public struct Gene: Codable {
    public let geneName: GeneName
    public let synonyms: [GeneName]
}

// MARK: - Keyword
public struct Keyword: Codable {
    public let id, category, name: String
}

// MARK: - Organism
public struct Organism: Codable {
    public let scientificName, commonName: String
    public let synonyms: [String]
    public let taxonID: Int
    public let lineage: [String]

    enum CodingKeys: String, CodingKey {
        case scientificName, commonName, synonyms
        case taxonID = "taxonId"
        case lineage
    }
}

// MARK: - ProteinDescription
public struct ProteinDescription: Codable {
    public let recommendedName: RecommendedName
    public let alternativeNames: [AlternativeName]
    public let flag: String
}

// MARK: - AlternativeName
public struct AlternativeName: Codable {
    public let fullName: GeneName
}

// MARK: - RecommendedName
public struct RecommendedName: Codable {
    public let fullName: FullName
    public let shortNames: [GeneName]
}

// MARK: - FullName
public struct FullName: Codable {
    public let value: String
}

// MARK: - Reference
public struct Reference: Codable {
    public let citation: Citation
    public let referencePositions: [String]
    public let referenceComments: [ReferenceComment]?
    public let evidences: [Evidence]
}

// MARK: - Citation
public struct Citation: Codable {
    public let id, citationType: String
    public let authors: [String]
    public let citationCrossReferences: [CitationCrossReference]
    public let title, publicationDate, journal, firstPage: String
    public let lastPage, volume: String
}

// MARK: - CitationCrossReference
public struct CitationCrossReference: Codable {
    public let database: Database
    public let id: String
}

public enum Database: String, Codable {
    case doi = "DOI"
    case pubMed = "PubMed"
}

// MARK: - ReferenceComment
public struct ReferenceComment: Codable {
    public let evidences: [Evidence]
    public let value, type: String
}

// MARK: - Sequence
public struct Sequence: Codable {
    public let value: String
    public let length, molWeight: Int
    public let crc64, md5: String
}

// MARK: - UniProtKBCrossReference
public struct UniProtKBCrossReference: Codable {
    public let database, id: String
    public let properties: [Property]
}

// MARK: - Property
public struct Property: Codable {
    public let key, value: String
}
