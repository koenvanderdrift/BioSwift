//
//  PEFF.swift
//  BioSwift
//

import Foundation

public struct PEFFKeyValue: Hashable, Codable, Sendable {
    public let key: String
    public let value: String

    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

/// A PEFF sequence entry. Unknown annotation keys are preserved in `annotations`.
public struct PEFFRecord: Hashable, Codable, Sendable {
    public let prefix: String
    public let accession: String
    public let annotations: [PEFFKeyValue]
    public let sequence: String

    public init(prefix: String, accession: String, annotations: [PEFFKeyValue], sequence: String) {
        self.prefix = prefix
        self.accession = accession
        self.annotations = annotations
        self.sequence = sequence
    }

    public func values(for key: String) -> [String] {
        annotations.filter { $0.key == key }.map(\.value)
    }

    public var fastaRecord: FastaRecord {
        let header = serializedHeader
        return FastaRecord(
            accession: accession,
            shortName: values(for: "GName").first ?? "",
            fullName: values(for: "PName").first ?? "",
            organism: values(for: "TaxName").first ?? "",
            sequence: sequence,
            header: header,
            headerFormat: .peff
        )
    }

    public var serializedHeader: String {
        let fields = annotations.map { "\\\($0.key)=\($0.value)" }.joined(separator: " ")
        return fields.isEmpty ? "\(prefix):\(accession)" : "\(prefix):\(accession) \(fields)"
    }
}

/// A PSI Extended FASTA document with ordered metadata and sequence records.
public struct PEFFDocument: Hashable, Codable, Sendable {
    public let version: String
    public let metadata: [PEFFKeyValue]
    public let records: [PEFFRecord]

    public init(version: String, metadata: [PEFFKeyValue], records: [PEFFRecord]) {
        self.version = version
        self.metadata = metadata
        self.records = records
    }

    public func metadataValues(for key: String) -> [String] {
        metadata.filter { $0.key == key }.map(\.value)
    }

    public var peffString: String {
        var lines = ["# PEFF \(version)", "# //"]
        lines += metadata.map { "# \($0.key)=\($0.value)" }
        lines.append("# //")
        for record in records {
            lines.append(">\(record.serializedHeader)")
            lines.append(record.sequence)
        }
        return lines.joined(separator: "\n") + "\n"
    }
}

public enum PEFFError: Error, Equatable, Sendable, LocalizedError {
    case missingSignature
    case malformedMetadata(String)
    case malformedRecordHeader(String)
    case sequenceWithoutHeader

    public var errorDescription: String? {
        switch self {
        case .missingSignature: "The document does not begin with a PEFF signature."
        case .malformedMetadata(let line): "Malformed PEFF metadata: \(line)."
        case .malformedRecordHeader(let line): "Malformed PEFF record header: \(line)."
        case .sequenceWithoutHeader: "PEFF sequence data appeared before a record header."
        }
    }
}

public struct PEFFParser: Sendable {
    public init() {}

    public func parse(_ data: Data) throws -> PEFFDocument {
        guard let text = String(data: data, encoding: .utf8) else {
            throw PEFFError.missingSignature
        }
        return try parse(text)
    }

    public func parse(_ text: String) throws -> PEFFDocument {
        let lines = text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
        guard let first = lines.first else { throw PEFFError.missingSignature }
        let signature = first.trimmingCharacters(in: .whitespaces)
        guard signature.hasPrefix("# PEFF ") else { throw PEFFError.missingSignature }
        let version = String(signature.dropFirst("# PEFF ".count)).trimmingCharacters(in: .whitespaces)

        var metadata: [PEFFKeyValue] = []
        var records: [PEFFRecord] = []
        var currentHeader: String?
        var sequence = ""

        func finishRecord() throws -> PEFFRecord? {
            guard let currentHeader else { return nil }
            let parsed = try parseHeader(currentHeader)
            return PEFFRecord(
                prefix: parsed.prefix,
                accession: parsed.accession,
                annotations: parsed.annotations,
                sequence: sequence
            )
        }

        for rawLine in lines.dropFirst() {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line == "# //" { continue }
            if line.hasPrefix("#") {
                guard currentHeader == nil else { continue }
                let content = line.dropFirst().trimmingCharacters(in: .whitespaces)
                guard let equals = content.firstIndex(of: "=") else {
                    throw PEFFError.malformedMetadata(String(line))
                }
                metadata.append(.init(
                    key: String(content[..<equals]),
                    value: String(content[content.index(after: equals)...])
                ))
            } else if line.hasPrefix(">") {
                if let record = try finishRecord() { records.append(record) }
                currentHeader = String(line.dropFirst())
                sequence = ""
            } else {
                guard currentHeader != nil else { throw PEFFError.sequenceWithoutHeader }
                sequence += line.filter { !$0.isWhitespace }
            }
        }
        if let record = try finishRecord() { records.append(record) }
        return PEFFDocument(version: version, metadata: metadata, records: records)
    }

    private func parseHeader(_ header: String) throws -> (
        prefix: String, accession: String, annotations: [PEFFKeyValue]
    ) {
        let firstBackslash = header.firstIndex(of: "\\")
        let identifier = header[..<(firstBackslash ?? header.endIndex)]
            .trimmingCharacters(in: .whitespaces)
        guard let colon = identifier.firstIndex(of: ":") else {
            throw PEFFError.malformedRecordHeader(header)
        }
        let prefix = String(identifier[..<colon])
        let accession = String(identifier[identifier.index(after: colon)...])
        guard !prefix.isEmpty, !accession.isEmpty else {
            throw PEFFError.malformedRecordHeader(header)
        }

        guard let firstBackslash else { return (prefix, accession, []) }
        let annotationText = header[firstBackslash...]
        var annotations: [PEFFKeyValue] = []
        var cursor = annotationText.startIndex
        while cursor < annotationText.endIndex {
            guard annotationText[cursor] == "\\" else {
                cursor = annotationText.index(after: cursor)
                continue
            }
            let keyStart = annotationText.index(after: cursor)
            guard let equals = annotationText[keyStart...].firstIndex(of: "=") else {
                throw PEFFError.malformedRecordHeader(header)
            }
            let key = String(annotationText[keyStart..<equals])
            var valueEnd = annotationText.endIndex
            var depth = 0
            var scan = annotationText.index(after: equals)
            while scan < annotationText.endIndex {
                if annotationText[scan] == "(" { depth += 1 }
                if annotationText[scan] == ")" { depth = max(0, depth - 1) }
                if annotationText[scan] == "\\", depth == 0 {
                    valueEnd = scan
                    break
                }
                scan = annotationText.index(after: scan)
            }
            let value = annotationText[annotationText.index(after: equals)..<valueEnd]
                .trimmingCharacters(in: .whitespaces)
            guard !key.isEmpty else { throw PEFFError.malformedRecordHeader(header) }
            annotations.append(.init(key: key, value: value))
            cursor = valueEnd
        }
        return (prefix, accession, annotations)
    }
}

