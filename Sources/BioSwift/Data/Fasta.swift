//
//  Fasta.swift
//  BioSwift
//
//  Created by Koen van der Drift on 8/18/20.
//  Copyright © 2020 - 2026 Koen van der Drift. All rights reserved.

import Foundation

/// The recognized convention used to interpret a FASTA header.
public enum FastaHeaderFormat: String, Codable, Sendable {
    case peff
    case uniProt
    case ncbi
    case ups
    case ipi
    case ensembl
    /// No supported header convention matched; only generic metadata was extracted.
    case generic
}

public struct FastaRecord: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    /// The original FASTA header without the leading `>` character.
    public let header: String
    /// The convention used to interpret the header.
    public let headerFormat: FastaHeaderFormat
    public let accession: String
    public let shortName: String
    public let fullName: String
    public let organism: String
    public var sequence: String

    public init(
        accession: String,
        shortName: String,
        fullName: String,
        organism: String,
        sequence: String,
        header: String = "",
        headerFormat: FastaHeaderFormat = .generic
    ) {
        id = UUID()
        self.header = header
        self.headerFormat = headerFormat
        self.accession = accession
        self.shortName = shortName
        self.fullName = fullName
        self.organism = organism
        self.sequence = sequence
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case header
        case headerFormat
        case accession
        case shortName
        case fullName
        case organism
        case sequence
    }

    public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(UUID.self, forKey: .id)
            header = try container.decodeIfPresent(String.self, forKey: .header) ?? ""
            headerFormat = try container.decodeIfPresent(
                FastaHeaderFormat.self,
                forKey: .headerFormat
            ) ?? .generic
            accession = try container.decode(String.self, forKey: .accession)
            shortName = try container.decode(String.self, forKey: .shortName)
            fullName = try container.decode(String.self, forKey: .fullName)
            organism = try container.decode(String.self, forKey: .organism)
            sequence = try container.decode(String.self, forKey: .sequence)
        } catch {
            throw BioSwiftDiagnostics.loggedDecodingFailure(error, from: decoder)
        }
    }
}

private struct ParsedFastaHeader: Sendable {
    var format: FastaHeaderFormat = .generic
    var accession: String?
    var shortName: String?
    var fullName: String?
    var organism: String?
}

private protocol FastaHeaderParsing: Sendable {
    func parse(_ header: Substring) -> ParsedFastaHeader?
}

private struct UniProtFastaHeaderParser: FastaHeaderParsing {
    func parse(_ header: Substring) -> ParsedFastaHeader? {
        let (token, description) = splitFastaHeader(header)
        let components = token.split(separator: "|", omittingEmptySubsequences: false)

        guard components.count >= 3,
            ["sp", "tr", "swiss"].contains(components[0].lowercased())
        else {
            return nil
        }

        return ParsedFastaHeader(
            format: .uniProt,
            accession: nonemptyString(components[1]),
            shortName: nonemptyString(components[2]),
            fullName: fastaDescription(beforeTagsIn: description),
            organism: fastaTaggedValue("OS", in: description)
        )
    }
}

private struct UPSFastaHeaderParser: FastaHeaderParsing {
    func parse(_ header: Substring) -> ParsedFastaHeader? {
        let (token, description) = splitFastaHeader(header)
        guard let marker = token.range(of: "ups|", options: .caseInsensitive) else {
            return nil
        }

        let accession = token[..<marker.lowerBound]
        let shortName = token[marker.upperBound...]
        let descriptionParts = description.components(separatedBy: " - ")

        return ParsedFastaHeader(
            format: .ups,
            accession: nonemptyString(accession),
            shortName: nonemptyString(shortName),
            fullName: descriptionParts.first.flatMap(nonemptyString),
            organism: descriptionParts.dropFirst().first.flatMap(nonemptyString)
        )
    }
}

private struct NCBIFastaHeaderParser: FastaHeaderParsing {
    private static let databaseMarkers: Set<String> = [
        "ref", "gb", "emb", "dbj", "tpg", "tpe", "tpd", "pdb",
    ]

    private static let refSeqPrefixes: Set<String> = [
        "AC", "AP", "NC", "NG", "NM", "NP", "NR", "NT", "NW", "NZ", "WP", "XM",
        "XP", "XR", "YP", "ZP",
    ]

    func parse(_ header: Substring) -> ParsedFastaHeader? {
        let (token, description) = splitFastaHeader(header)
        let components = token.split(separator: "|", omittingEmptySubsequences: false)

        if let markerIndex = components.firstIndex(where: {
            Self.databaseMarkers.contains($0.lowercased())
        }), components.indices.contains(markerIndex + 1) {
            let accession = components[markerIndex + 1]
            let nameIndex = markerIndex + 2
            let shortName = components.indices.contains(nameIndex) ? components[nameIndex] : ""

            return ParsedFastaHeader(
                format: .ncbi,
                accession: nonemptyString(accession),
                shortName: nonemptyString(shortName),
                fullName: nonemptyString(description),
                organism: ncbiOrganism(in: description)
            )
        }

        guard isRefSeqAccession(token) || header.contains("[organism=") else {
            return nil
        }

        return ParsedFastaHeader(
            format: .ncbi,
            accession: nonemptyString(token),
            fullName: ncbiDescription(in: description),
            organism: ncbiOrganism(in: description)
        )
    }

    private func isRefSeqAccession(_ token: Substring) -> Bool {
        let parts = token.split(separator: "_", maxSplits: 1)
        guard parts.count == 2,
            Self.refSeqPrefixes.contains(parts[0].uppercased())
        else {
            return false
        }

        let versionParts = parts[1].split(separator: ".", maxSplits: 1)
        return !versionParts[0].isEmpty && versionParts[0].allSatisfy(\.isNumber)
            && (versionParts.count == 1
                || (!versionParts[1].isEmpty && versionParts[1].allSatisfy(\.isNumber)))
    }
}

private struct IPIFastaHeaderParser: FastaHeaderParsing {
    func parse(_ header: Substring) -> ParsedFastaHeader? {
        let (token, description) = splitFastaHeader(header)
        guard token.uppercased().hasPrefix("IPI") else {
            return nil
        }

        return ParsedFastaHeader(
            format: .ipi,
            accession: nonemptyString(token),
            fullName: nonemptyString(description)
        )
    }
}

private struct EnsemblFastaHeaderParser: FastaHeaderParsing {
    func parse(_ header: Substring) -> ParsedFastaHeader? {
        let (token, description) = splitFastaHeader(header)
        let tokenComponents = token.split(separator: "|", omittingEmptySubsequences: false)
        let accession = tokenComponents.first ?? token

        guard accession.uppercased().hasPrefix("ENS") || isCoordinateHeader(token) else {
            return nil
        }

        return ParsedFastaHeader(
            format: .ensembl,
            accession: nonemptyString(accession),
            fullName: nonemptyString(description) ?? nonemptyString(token)
        )
    }

    private func isCoordinateHeader(_ token: Substring) -> Bool {
        let components = token.split(separator: ":", omittingEmptySubsequences: false)
        guard components.count >= 6,
            ["chromosome", "scaffold", "contig", "supercontig"].contains(
                components[0].lowercased())
        else {
            return false
        }

        return components.suffix(3).dropLast().allSatisfy { Int($0) != nil }
            && ["1", "-1"].contains(String(components.last ?? ""))
    }
}

private func ncbiOrganism(in description: Substring) -> String? {
    if let tagged = bracketedFastaValue("organism", in: description) {
        return tagged
    }

    guard description.hasSuffix("]"),
        let openingBracket = description.lastIndex(of: "[")
    else {
        return nil
    }

    return nonemptyString(description[description.index(after: openingBracket)..<description.index(before: description.endIndex)])
}

private func ncbiDescription(in description: Substring) -> String? {
    guard let firstBracket = description.firstIndex(of: "[") else {
        return nonemptyString(description)
    }

    return nonemptyString(description[..<firstBracket])
}

private func bracketedFastaValue(_ key: String, in description: Substring) -> String? {
    let marker = "[\(key)="
    guard let markerRange = description.range(of: marker),
        let closingBracket = description[markerRange.upperBound...].firstIndex(of: "]")
    else {
        return nil
    }

    return nonemptyString(description[markerRange.upperBound..<closingBracket])
}

private func splitFastaHeader(_ header: Substring) -> (token: Substring, description: Substring) {
    guard let separator = header.firstIndex(where: \.isWhitespace) else {
        return (header, "")
    }

    let descriptionStart = header[separator...].firstIndex(where: { !$0.isWhitespace })
    let description = descriptionStart.map { header[$0...] } ?? ""
    return (header[..<separator], description)
}

private func nonemptyString<S: StringProtocol>(_ value: S) -> String? {
    let result = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return result.isEmpty ? nil : result
}

private func fastaDescription(beforeTagsIn description: Substring) -> String? {
    let markers = [" OS=", " OX=", " GN=", " PE=", " SV="]
    let end = markers.compactMap { description.range(of: $0)?.lowerBound }.min()
    let value = end.map { description[..<$0] } ?? description[...]
    return nonemptyString(value)
}

private func fastaTaggedValue(_ tag: String, in description: Substring) -> String? {
    let marker = " \(tag)="
    guard let markerRange = description.range(of: marker) else {
        return nil
    }

    let remainder = description[markerRange.upperBound...]
    let terminatingMarkers = [" OS=", " OX=", " GN=", " PE=", " SV="]
    let end = terminatingMarkers.compactMap { remainder.range(of: $0)?.lowerBound }.min()
    let value = end.map { remainder[..<$0] } ?? remainder[...]
    return nonemptyString(value)
}

public func fastaRecords(from fileName: String, in bundle: Bundle = .main) async throws -> [FastaRecord] {
    try await FastaParser().parse(fileName, in: bundle)
}

public func fastaRecord(from fileName: String, in bundle: Bundle = .main) async throws -> FastaRecord {
    let records = try await fastaRecords(from: fileName, in: bundle)

    guard let record = records.first else {
        throw BioSwiftDiagnostics.logged(
            LoadError.fileParsingFailed(name: "\(fileName).fasta", underlyingError: nil))
    }

    return record
}

public func fastaRecords(from data: Data) async throws -> [FastaRecord] {
    try await FastaParser().parse(data)
}

public func fastaRecords(fromText text: String) async throws -> [FastaRecord] {
    try await FastaParser().parseFasta(text)
}

public func proteins(fromFastaFile fileName: String, in bundle: Bundle = .main) async throws -> [Protein] {
    let records = try await fastaRecords(from: fileName, in: bundle)

    return try records.map {
        try Protein(fastaRecord: $0)
    }
}

public func protein(fromFastaFile fileName: String, in bundle: Bundle = .main) async throws -> Protein {
    let record = try await fastaRecord(from: fileName, in: bundle)

    return try Protein(fastaRecord: record)
}

public func dnas(fromFastaFile fileName: String, in bundle: Bundle = .main) async throws -> [DNA] {
    let records = try await fastaRecords(from: fileName, in: bundle)

    return try records.map {
        try DNA(fastaRecord: $0)
    }
}

public func dna(fromFastaFile fileName: String, in bundle: Bundle = .main) async throws -> DNA {
    let record = try await fastaRecord(from: fileName, in: bundle)

    return try DNA(fastaRecord: record)
}

public func rnas(fromFastaFile fileName: String, in bundle: Bundle = .main) async throws -> [RNA] {
    let records = try await fastaRecords(from: fileName, in: bundle)

    return try records.map {
        try RNA(fastaRecord: $0)
    }
}

public func rna(fromFastaFile fileName: String, in bundle: Bundle = .main) async throws -> RNA {
    let record = try await fastaRecord(from: fileName, in: bundle)

    return try RNA(fastaRecord: record)
}

/// FastaParser takes a text file as input and produces a ``FastaRecord`` array.
/// It recognizes common protein and nucleotide header conventions and safely falls back to generic metadata.
public final class FastaParser: Sendable {
    struct RawRecord {
        let info: String
        let sequence: String
    }

    public init() {
    }

    private static let headerParsers: [any FastaHeaderParsing] = [
        UniProtFastaHeaderParser(),
        NCBIFastaHeaderParser(),
        UPSFastaHeaderParser(),
        IPIFastaHeaderParser(),
        EnsemblFastaHeaderParser(),
    ]

    public func parse(_ fileName: String, in bundle: Bundle = .main) async throws -> [FastaRecord] {
        let fastaText = try loadText(from: fileName, withExtension: "fasta", in: bundle)
        let fullName = "\(fileName).fasta"

        do {
            return try await parseFasta(fastaText)
        } catch {
            throw BioSwiftDiagnostics.logged(
                LoadError.fileDecodingFailed(name: fullName, underlyingError: error))
        }
    }

    public func parse(_ data: Data) async throws -> [FastaRecord] {
        guard let fastaText = String(data: data, encoding: .utf8) else {
            throw BioSwiftDiagnostics.logged(
                LoadError.fileConversionFailed(name: "data", underlyingError: nil))
        }

        return try await parseFasta(fastaText)
    }

    public func parseBundleFile(_ fileName: String) async throws -> [FastaRecord] {
        try await parse(fileName, in: .module)
    }

    public func parseFasta(_ fastaText: String) async throws -> [FastaRecord] {
        let rawRecords = try splitRawRecords(from: fastaText)

        return try rawRecords.map(parseRecord)
    }
}

extension FastaParser {
    func splitRawRecords(from text: String) throws -> [RawRecord] {
        let normalizedText = text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(
            of: "\r", with: "\n")

        return try normalizedText.components(separatedBy: "\n>").map { recordText in
            try rawRecord(from: recordText)
        }.filter { !$0.info.isEmpty || !$0.sequence.isEmpty }
    }

    func rawRecord(from recordText: String) throws -> RawRecord {
        var cleanedRecordText = recordText.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanedRecordText.first == ">" {
            cleanedRecordText.removeFirst()
        }

        let parts = cleanedRecordText.split(
            separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)

        guard let infoPart = parts.first else {
            throw BioSwiftDiagnostics.logged(
                LoadError.fileParsingFailed(name: "records", underlyingError: nil))
        }

        let info = String(infoPart).trimmingCharacters(in: .whitespacesAndNewlines)

        let rawData = parts.count > 1 ? String(parts[1]) : ""

        let data = rawData.filter {
            !$0.isWhitespace
        }

        guard !info.isEmpty, !data.isEmpty else {
            throw BioSwiftDiagnostics.logged(
                LoadError.fileParsingFailed(name: "records", underlyingError: nil))
        }

        return RawRecord(info: info, sequence: data)
    }
}

extension FastaParser {
    func parseRecord(_ record: RawRecord) throws -> FastaRecord {
        let metadata = parseHeader(record.info[...])

        return FastaRecord(
            accession: metadata.accession ?? "",
            shortName: metadata.shortName ?? "",
            fullName: metadata.fullName ?? "",
            organism: metadata.organism ?? "",
            sequence: record.sequence,
            header: record.info,
            headerFormat: metadata.format
        )
    }

    func parseString(_ input: String) -> FastaRecord {
        var input = input[...]
        if input.hasPrefix(">") {
            input.remove(at: input.startIndex)
        }

        let header = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let metadata = parseHeader(header[...])
        return FastaRecord(
            accession: metadata.accession ?? "",
            shortName: metadata.shortName ?? "",
            fullName: metadata.fullName ?? "",
            organism: metadata.organism ?? "",
            sequence: "",
            header: header,
            headerFormat: metadata.format
        )
    }

    private func parseHeader(_ header: Substring) -> ParsedFastaHeader {
        for parser in Self.headerParsers {
            if let result = parser.parse(header) {
                return result
            }
        }

        let (token, _) = splitFastaHeader(header)
        return ParsedFastaHeader(
            accession: nonemptyString(token),
            fullName: nonemptyString(header.replacingOccurrences(of: "_", with: " "))
        )
    }
}
