//
//  ModificationLibrary.swift
//  BioSwift
//

import Foundation

public enum ModificationVocabulary: String, Codable, Sendable {
    case unimod
    case psiMod
    case uniProtPTM
}

/// Provides direct iteration and indexed access in reference-library order.
extension ModificationLibrary: RandomAccessCollection {
    public var startIndex: Int { modifications.startIndex }
    public var endIndex: Int { modifications.endIndex }

    public subscript(position: Int) -> Modification {
        modifications[position]
    }

    public func index(after index: Int) -> Int {
        modifications.index(after: index)
    }

    public func index(before index: Int) -> Int {
        modifications.index(before: index)
    }
}

public struct ModificationLibrary: Sendable {
    public let vocabulary: ModificationVocabulary
    public let version: String
    public let modifications: [Modification]

    private let modificationsByName: [String: Modification]
    private let modificationsByAccession: [String: Modification]
    private let metadataByAccession: [String: ModificationMetadata]

    public init(
        vocabulary: ModificationVocabulary,
        version: String,
        modifications: [Modification],
        metadataByAccession: [String: ModificationMetadata] = [:]
    ) {
        self.vocabulary = vocabulary
        self.version = version
        self.modifications = modifications
        // Preserve the first definition when names or accessions repeat.
        self.modificationsByName = Dictionary(
            modifications.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
        self.modificationsByAccession = Dictionary(
            modifications.compactMap { modification in
                modification.accession.map { ($0, modification) }
            },
            uniquingKeysWith: { first, _ in first }
        )
        self.metadataByAccession = metadataByAccession
    }

    public func modification(named name: String) -> Modification? {
        modificationsByName[name]
    }

    public func modification(accession: String) -> Modification? {
        modificationsByAccession[accession]
    }

    public func modifications(matching query: String, applicableTo residue: String? = nil) -> [Modification] {
        let normalizedQuery = query.folding(
            options: [.caseInsensitive, .diacriticInsensitive], locale: .current)

        return modifications.filter { modification in
            let searchableNames = [modification.name, modification.fullName] + modification.synonyms
            let matchesName = searchableNames.contains { name in
                name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                    .contains(normalizedQuery)
            }
            let matchesResidue = residue == nil || modification.specificities.contains {
                $0.site == residue || $0.site == "X"
            }

            return matchesName && matchesResidue
        }
    }

    public func modifications(applicableTo residueIdentifier: String) -> [Modification] {
        modifications.filter { modification in
            modification.specificities.contains {
                $0.site == residueIdentifier
            }
        }
    }

    public func metadata(for modification: Modification) -> ModificationMetadata? {
        modification.accession.flatMap { metadataByAccession[$0] }
    }

    public func modifications(taxonIdentifier: Int) -> [Modification] {
        modifications.filter { modification in
            metadata(for: modification)?.taxonomicRanges.contains {
                $0.taxonIdentifier == taxonIdentifier
            } == true
        }
    }
}

