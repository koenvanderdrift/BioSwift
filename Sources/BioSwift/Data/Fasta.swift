//
//  Fasta.swift
//  BioSwift
//
//  Created by Koen van der Drift on 8/18/20.
//  Copyright © 2020 - 2025 Koen van der Drift. All rights reserved.

import Foundation

public let zeroFastaRecord = FastaRecord(accession: "", shortName: "", fullName: "", organism: "", sequence: "")

public struct FastaRecord: Codable, Hashable, Identifiable {
    // TODO: add DNA/RNA fasta parsing
    public let id: UUID
    public let accession: String
    public let shortName: String
    public let fullName: String
    public let organism: String
    public var sequence: String

    public init(accession: String, shortName: String, fullName: String, organism: String, sequence: String) {
        id = UUID()
        self.accession = accession
        self.shortName = shortName
        self.fullName = fullName
        self.organism = organism
        self.sequence = sequence
    }
}

public final class FastaDecoder {
    public struct RawRecord {
        let info: String
        let sequence: String
    }

    public init() {}

    public func parseFastaFile(_ fileName: String) throws -> [FastaRecord] {
        let fastaText = try loadText(from: fileName, withExtension: "fasta")
        let fullName = "\(fileName).fasta"

        do {
            return try parseText(fastaText)

        } catch {
            throw LoadError.fileDecodingFailed(name: fullName, underlyingError: error)
        }
    }

    public func parseFastaFileFromBundle(_ fileName: String) throws -> [FastaRecord] {
        let fastaText = try loadText(from: fileName, withExtension: "fasta", in: .module)
        let fullName = "\(fileName).fasta"

        do {
            return try parseText(fastaText)

        } catch {
            throw LoadError.fileDecodingFailed(name: fullName, underlyingError: error)
        }
    }

    public func parseFastaData(_ data: Data) throws -> [FastaRecord] {
        guard let fastaText = String(data: data, encoding: .utf8) else {
            throw LoadError.fileConversionFailed(name: "data", underlyingError: nil)
        }

        return try parseText(fastaText)
    }

    func parseText(_ fastaText: String) throws -> [FastaRecord] {
        let rawRecords = try splitRawRecords(from: fastaText)

        return try rawRecords.concurrentMap { rawRecord in
            try self.parseRecord(rawRecord)
        }
    }

    func splitRawRecords(from text: String) throws -> [RawRecord] {
        let normalizedText = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        return try normalizedText
            .components(separatedBy: "\n>")
            .map { recordText in
                try rawRecord(from: recordText)
            }
            .filter { !$0.info.isEmpty || !$0.sequence.isEmpty }
    }

    func rawRecord(from recordText: String) throws -> RawRecord {
        var cleanedRecordText = recordText
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanedRecordText.first == ">" {
            cleanedRecordText.removeFirst()
        }

        let parts = cleanedRecordText.split(
            separator: "\n",
            maxSplits: 1,
            omittingEmptySubsequences: false
        )

        guard let infoPart = parts.first else {
            throw LoadError.fileParsingFailed(
                name: "records",
                underlyingError: nil
            )
        }

        let info = String(infoPart)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let rawData = parts.count > 1
            ? String(parts[1])
            : ""

        let data = rawData.filter {
            !$0.isWhitespace
        }

        guard !info.isEmpty, !data.isEmpty else {
            throw LoadError.fileParsingFailed(
                name: "records",
                underlyingError: nil
            )
        }

        return RawRecord(
            info: info,
            sequence: data
        )
    }
}

extension FastaDecoder {
    func parseRecord(_ record: RawRecord) throws -> FastaRecord {
        let input = record.info[...]

        var result: FastaRecord = zeroFastaRecord

        if input.contains("ups|") {
            result = parseUPS(input)
        } else if input.hasPrefix("sp") || input.hasPrefix("swiss") || input.hasPrefix("tr") {
            result = parseSwissProt(input)
        } else if input.hasPrefix("IPI") {
            result = parseIPI(input)
        } else if input.hasPrefix("ENS") {
            result = parseEnsemble(input)
        } else {
            result = parseUnspecified(input)
        }

        result.sequence = record.sequence

        return result
    }

    func parse(_ input: String) -> FastaRecord {
        // https://www.uniprot.org/help/fasta-headers

        var input = input[...]

        if input.hasPrefix(">") {
            input.remove(at: input.startIndex)
        }

        if input.contains("ups|") {
            return parseUPS(input)
        } else if input.hasPrefix("sp") || input.hasPrefix("swiss") || input.hasPrefix("tr") {
            return parseSwissProt(input)
        } else if input.hasPrefix("IPI") {
            return parseIPI(input)
        } else if input.hasPrefix("ENS") {
            return parseEnsemble(input)
        }

        return parseUnspecified(input)
    }

    func parseUPS(_ input: Substring) -> FastaRecord {
        // >P02768ups|ALBU_HUMAN_UPS Serum albumin (Chain 26-609) - Homo sapiens (Human) AHKSEVAHRFKDLGEENF…
        var entry = input
        var fullName: Substring = ""
        var org: Substring = ""

        let acc = entry.scanUntil("|")?.dropLast(3)
        entry.skip(1)

        let shortName = entry.scanUntil(" ")

        if let nameRange = entry.range(of: " - ") {
            let nsRange = NSRange(nameRange, in: entry)
            fullName = entry.skip(nsRange.location) ?? ""
        }

        entry.skip(3)

        if let organismRange = entry.range(of: " ", options: .backwards) {
            let nsRange = NSRange(organismRange, in: entry)
            org = entry.skip(nsRange.location) ?? ""
        }

        return FastaRecord(accession: String(acc ?? ""),
                           shortName: String(shortName ?? ""),
                           fullName: String(fullName),
                           organism: String(org),
                           sequence: "")
    }

    func parseSwissProt(_ input: Substring) -> FastaRecord {
        /*
         * >db|UniqueIdentifier|EntryName ProteinName OS=OrganismName OX=OrganismIdentifier [GN=GeneName ]PE=ProteinExistence SV=SequenceVersion
         * >tr|Q8ADX7|Q8ADX7_9HIV1 Envelope glycoprotein gp160 OS=Human immunodeficiency virus 1 OX=11676 GN=env PE=3 SV=1
         *
         * db is ‘sp’ for UniProtKB/Swiss-Prot and ‘tr’ for UniProtKB/TrEMBL.
         * UniqueIdentifier is the primary accession number of the UniProtKB entry.
         * EntryName is the entry name of the UniProtKB entry.
         * ProteinName is the recommended name of the UniProtKB entry as annotated in the RecName field. For UniProtKB/TrEMBL entries without a RecName field, the SubName field is used. In case of multiple SubNames, the first one is used. The ‘precursor’ attribute is excluded, ‘Fragment’ is included with the name if applicable.
         * OrganismName is the scientific name of the organism of the UniProtKB entry.
         * OrganismIdentifier is the unique identifier of the source organism, assigned by the NCBI.
         * GeneName is the first gene name of the UniProtKB entry. If there is no gene name, OrderedLocusName or ORFname, the GN field is not listed.
         * ProteinExistence is the numerical value describing the evidence for the existence of the protein.
         * SequenceVersion is the version number of the sequence.
         */

        var input = input[...]
        input.skipThrough("|")

        let acc = input.scanUntil("|")
        input.skip(1)

        let shortName = input.scanUntil(" ")
        input.skip(1)

        let fullName = input.scanUntil("=")?.dropLast(3)
        input.skip(1)

        let org = input.scanUntil("=")?.dropLast(3)

        return FastaRecord(accession: String(acc ?? ""),
                           shortName: String(shortName ?? ""),
                           fullName: String(fullName ?? ""),
                           organism: String(org ?? ""),
                           sequence: "")
    }

    func parseIPI(_ input: Substring) -> FastaRecord {
        // IPI00300415 IPI:IPI00300415.9|SWISS-PROT:Q8N431-1|TREMBL:D3DWQ7|ENSEMBL:ENSP00000354963;ENSP00000377037|REFSEQ:NP_778232|H-INV:HIT000094619|VEGA:OTTHUMP00000161522;OTTHUMP00000161538 Tax_Id=9606 Gene_Symbol=RASGEF1C Isoform 1 of Ras-GEF domain-containing family member 1C
        let info = input.components(separatedBy: "|")
        let acc = info[1]
        let fullName = info.last ?? ""

        // TODO: implement

        return FastaRecord(accession: acc, shortName: "", fullName: fullName, organism: "", sequence: "")
    }

    func parseEnsemble(_ input: Substring) -> FastaRecord {
        // ENSP00000391493 pep:known chromosome:GRCh37:2:160609001:160624471:1 gene:ENSG00000136536 transcript:ENST00000420397
        let info = input.components(separatedBy: " ")
        let fullName = info[0]

        // TODO: implement

        return FastaRecord(accession: "", shortName: "", fullName: fullName, organism: "", sequence: "")
    }

    func parseUnspecified(_ input: Substring) -> FastaRecord {
        // DROME_HH_Q02936
        // DECOY_IPI00339224 Decoy sequence
        let fullName = input.replacingOccurrences(of: "_", with: " ")

        // TODO: implement

        return FastaRecord(accession: "", shortName: "", fullName: fullName, organism: "", sequence: "")
    }
}

/*
 public enum FastaDecoderError: LocalizedError {
    case unsupportedType

    public var errorDescription: String? {
        switch self {
        case .unsupportedType:
            return "This decoder only supports decoding Fastarecord arrays."
        }
    }
 }

 public func parseFastaFile(_ fileName: String) throws -> [FastaRecord] {
    let fullName = "\(fileName).fasta"
    let fastaData = try loadData(from: fileName, withExtension: "fasta")

    do {
        return try FastaDecoder().decode([FastaRecord].self, from: fastaData)

    } catch {
        throw LoadError.fileDecodingFailed(name: fullName, underlyingError: error)
    }
 }

 public func parseFastaFileFromBundle(_ fileName: String) throws -> [FastaRecord] {
    let fullName = "\(fileName).fasta"
    let fastaData = try loadDataFromBundle(from: fileName, withExtension: "fasta")

    do {
        return try FastaDecoder().decode([FastaRecord].self, from: fastaData)
    } catch {
        throw LoadError.fileDecodingFailed(name: fullName, underlyingError: error)
    }
 }

 public func fastaRecords(from _: Data) throws -> [FastaRecord] {
    []
 }

 public func parseFastaData(from fileName: String) throws -> [FastaRecord] {
    let fullName = "\(fileName).fasta"
    let fastaData = try loadData(from: fileName, withExtension: "fasta")

    do {
        return try FastaDecoder().decodeRecords(with: fastaData)
    } catch {
        throw LoadError.fileDecodingFailed(
            name: fullName,
            underlyingError: error
        )
    }
 }

 public final class FastaDecoder: TopLevelDecoder {
    public init() {}

    public func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data
    ) throws -> T {
        guard type == [FastaRecord].self else {
            throw LoadError.fileDecodingFailed(name: "records", underlyingError: FastaDecoderError.unsupportedType)
        }

        guard let text = String(data: data, encoding: .ascii) else {
            throw LoadError.fileConversionFailed(
                name: "records",
                underlyingError: nil
            )
        }

        let recordTexts = text.components(
            separatedBy: "\n>"
        )

        let records = try recordTexts.map { recordText in
            let cleanedRecordText = recordText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            return try decodeRecord(from: cleanedRecordText)
        }

        guard let typedRecords = records as? T else {
            throw LoadError.fileDecodingFailed(
                name: "records",
                underlyingError: FastaDecoderError.unsupportedType
            )
        }

        return typedRecords
    }

    public func decodeRecord(from fastaLine: String) throws -> FastaRecord {
        let decoder = _FastaDecoder(fastaLine)

        return try FastaRecord(from: decoder)
    }
 }

 public extension FastaDecoder {
    func decodeRecords(with fastaData: Data) throws -> [FastaRecord] {
        guard let text = String(data: fastaData, encoding: .utf8) else {
            throw LoadError.fileConversionFailed(name: "records", underlyingError: nil)
        }

        let recordTexts = text.components(
            separatedBy: "\n>"
        )

        return try recordTexts.concurrentMap { recordText in
            let cleanedRecordText = recordText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            return try self.decodeRecord(from: cleanedRecordText)
        }
    }
 }

 private final class _FastaDecoder {
    // via: https://talk.objc.io/episodes/S01E115-building-a-custom-xml-decoder

    let codingPath: [CodingKey] = []
    let userInfo: [CodingUserInfoKey: Any] = [:]
    let input: String

    init(_ input: String) {
        self.input = input
    }
 }

 extension _FastaDecoder: Decoder {
    func container<Key: CodingKey>(keyedBy _: Key.Type) throws -> KeyedDecodingContainer<Key> {
        KeyedDecodingContainer(KDC(input))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self, .init(codingPath: [], debugDescription: "no unkeyed container", underlyingError: nil))
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        throw DecodingError.valueNotFound(SingleValueDecodingContainer.self, .init(codingPath: [], debugDescription: "no single value container", underlyingError: nil))
    }

    class KDC<Key: CodingKey>: KeyedDecodingContainerProtocol {
        let codingPath: [CodingKey] = []
        let allKeys: [Key] = []

        let record: FastaRecord
        let parser = FastaParser(fileName: "")

        init(_ input: String) {
            record = parser.parse(input)
        }

        func contains(_ key: Key) -> Bool {
            allKeys.contains(where: { $0.stringValue == key.stringValue })
        }

        func decodeNil(forKey key: Key) throws -> Bool {
            if contains(key) {
                return false
            } else {
                throw DecodingError.keyNotFound(key, .init(codingPath: [], debugDescription: "key not found", underlyingError: nil))
            }
        }

        func decode(_: Bool.Type, forKey _: Key) throws -> Bool {
            throw DecodingError.typeMismatch(Bool.self, .init(codingPath: [], debugDescription: "type mismatch", underlyingError: nil))
        }

        func decode(_: String.Type, forKey key: Key) throws -> String {
            switch key.stringValue {
            case "accession":
                return record.accession
            case "entryName":
                return record.entryName
            case "proteinName":
                return record.proteinName
            case "organism":
                return record.organism
            case "sequence":
                return record.sequence
            default:
                return ""
            }
        }

        func decode(_: Double.Type, forKey _: Key) throws -> Double {
            throw DecodingError.typeMismatch(Double.self, .init(codingPath: [], debugDescription: "type mismatch", underlyingError: nil))
        }

        func decode(_: Float.Type, forKey _: Key) throws -> Float {
            throw DecodingError.typeMismatch(Float.self, .init(codingPath: [], debugDescription: "type mismatch", underlyingError: nil))
        }

        func decode(_: Int.Type, forKey _: Key) throws -> Int {
            throw DecodingError.typeMismatch(Int.self, .init(codingPath: [], debugDescription: "type mismatch", underlyingError: nil))
        }

        func decode(_: Int8.Type, forKey _: Key) throws -> Int8 {
            throw DecodingError.typeMismatch(Int8.self, .init(codingPath: [], debugDescription: "type mismatch", underlyingError: nil))
        }

        func decode(_: Int16.Type, forKey _: Key) throws -> Int16 {
            throw DecodingError.typeMismatch(Int16.self, .init(codingPath: [], debugDescription: "type mismatch", underlyingError: nil))
        }

        func decode(_: Int32.Type, forKey _: Key) throws -> Int32 {
            throw DecodingError.typeMismatch(Int32.self, .init(codingPath: [], debugDescription: "type mismatch", underlyingError: nil))
        }

        func decode(_: Int64.Type, forKey _: Key) throws -> Int64 {
            throw DecodingError.typeMismatch(Int64.self, .init(codingPath: [], debugDescription: "type mismatch", underlyingError: nil))
        }

        func decode(_: UInt.Type, forKey _: Key) throws -> UInt {
            throw DecodingError.typeMismatch(UInt.self, .init(codingPath: [], debugDescription: "type mismatch", underlyingError: nil))
        }

        func decode(_: UInt8.Type, forKey _: Key) throws -> UInt8 {
            throw DecodingError.typeMismatch(UInt8.self, .init(codingPath: [], debugDescription: "type mismatch", underlyingError: nil))
        }

        func decode(_: UInt16.Type, forKey _: Key) throws -> UInt16 {
            throw DecodingError.typeMismatch(UInt16.self, .init(codingPath: [], debugDescription: "type mismatch", underlyingError: nil))
        }

        func decode(_: UInt32.Type, forKey _: Key) throws -> UInt32 {
            throw DecodingError.typeMismatch(UInt32.self, .init(codingPath: [], debugDescription: "type mismatch", underlyingError: nil))
        }

        func decode(_: UInt64.Type, forKey _: Key) throws -> UInt64 {
            throw DecodingError.typeMismatch(UInt64.self, .init(codingPath: [], debugDescription: "type mismatch", underlyingError: nil))
        }

        func decode<T: Decodable>(_: T.Type, forKey _: Key) throws -> T {
            UUID() as! T
        }

        func nestedContainer<NestedKey: CodingKey>(keyedBy _: NestedKey.Type, forKey _: Key) throws -> KeyedDecodingContainer<NestedKey> {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<NestedKey>.self, .init(codingPath: [], debugDescription: "no nested container", underlyingError: nil))
        }

        func nestedUnkeyedContainer(forKey _: Key) throws -> UnkeyedDecodingContainer {
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self, .init(codingPath: [], debugDescription: "no nested container", underlyingError: nil))
        }

        func superDecoder() throws -> Decoder {
            throw DecodingError.valueNotFound(Decoder.self, .init(codingPath: [], debugDescription: "no super decoder", underlyingError: nil))
        }

        func superDecoder(forKey _: Key) throws -> Decoder {
            throw DecodingError.valueNotFound(Decoder.self, .init(codingPath: [], debugDescription: "no super decoder", underlyingError: nil))
        }
    }
 }
 */
