//
//  Fasta.swift
//  BioSwift
//
//  Created by Koen van der Drift on 8/18/20.
//  Copyright © 2020 - 2024 Koen van der Drift. All rights reserved.

import Combine
import Foundation

public let zeroFastaRecord = FastaRecord(accession: "", entryName: "", proteinName: "", organism: "", sequence: "")

public func parseFastaData(from fileName: String) throws -> [FastaRecord] {
    do {
        let fastaData = try loadData(from: fileName, withExtension: "fasta")
        return try FastaDecoder().decode([FastaRecord].self, from: fastaData)
    } catch {
        throw LoadError.fileDecodingFailed(name: fileName)
    }
}

public func parseFastaDataFromBundle(from fileName: String) throws -> [FastaRecord] {
    do {
        let fastaData = try loadDataFromBundle(from: fileName, withExtension: "fasta")
        return try FastaDecoder().decode([FastaRecord].self, from: fastaData)
    } catch {
        throw LoadError.fileDecodingFailed(name: fileName)
    }
}

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
public func parseFastaData(from fileName: String) async throws -> [FastaRecord] {
    do {
        let fastaData = try loadData(from: fileName, withExtension: "fasta")
        return await FastaDecoder().decodeRecords(with: fastaData)
    } catch {
        throw LoadError.fileDecodingFailed(name: fileName)
    }
}

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
public func parseFastaDataFromBundle(from fileName: String) async throws -> [FastaRecord] {
    do {
        let fastaData = try loadDataFromBundle(from: fileName, withExtension: "fasta")
        return await FastaDecoder().decodeRecords(with: fastaData)
    } catch {
        throw LoadError.fileDecodingFailed(name: fileName)
    }
}

public struct FastaRecord: Codable, Hashable, Identifiable {
    // TODO: add DNA/RNA fasta parsing
    public let id: UUID
    public let accession: String
    public let entryName: String
    public let proteinName: String
    public let organism: String
    public let sequence: String

    public init(accession: String, entryName: String, proteinName: String, organism: String, sequence: String) {
        id = UUID()
        self.accession = accession
        self.entryName = entryName
        self.proteinName = proteinName
        self.organism = organism
        self.sequence = sequence
    }
}

private final class FastaParser {
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
        var proteinName: Substring = ""
        var org: Substring = ""

        let acc = entry.scan(until: { $0 == "|" })?.dropLast(3)
        let _ = entry.scan(count: 1)
        let entryName = entry.scan(until: { $0 == " " })

        if let nameRange = entry.range(of: " - ") {
            let nsRange = NSRange(nameRange, in: entry)
            proteinName = entry.scan(count: nsRange.location) ?? ""
        }

        let _ = entry.scan(count: 3)

        if let organismRange = entry.range(of: " ", options: .backwards) {
            let nsRange = NSRange(organismRange, in: entry)
            org = entry.scan(count: nsRange.location) ?? ""
        }

        let seq = entry

        return FastaRecord(accession: String(acc ?? ""),
                           entryName: String(entryName ?? ""),
                           proteinName: String(proteinName),
                           organism: String(org),
                           sequence: String(seq))
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

        var entry = input[...]

        entry.scan(until: { $0 == "|" })
        entry.scan(count: 1)

        let acc = entry.scan(until: { $0 == "|" })
        entry.scan(count: 1)

        let entryName = entry.scan(until: { $0 == " " })
        entry.scan(count: 1)

        let proteinName = entry.scan(until: { $0 == "=" })?.dropLast(3)
        entry.scan(count: 1)

        let org = entry.scan(until: { $0 == "=" })?.dropLast(3)
        let _ = entry.scan(until: { $0 == "\n" })

        let seq = entry

        return FastaRecord(accession: String(acc ?? ""),
                           entryName: String(entryName ?? ""),
                           proteinName: String(proteinName ?? ""),
                           organism: String(org ?? ""),
                           sequence: String(seq))
    }

    func parseIPI(_ input: Substring) -> FastaRecord {
        // IPI00300415 IPI:IPI00300415.9|SWISS-PROT:Q8N431-1|TREMBL:D3DWQ7|ENSEMBL:ENSP00000354963;ENSP00000377037|REFSEQ:NP_778232|H-INV:HIT000094619|VEGA:OTTHUMP00000161522;OTTHUMP00000161538 Tax_Id=9606 Gene_Symbol=RASGEF1C Isoform 1 of Ras-GEF domain-containing family member 1C
        let info = input.components(separatedBy: "|")
        let acc = info[1]
        let proteinName = info.last ?? ""

        return FastaRecord(accession: acc, entryName: "", proteinName: proteinName, organism: "", sequence: "")
    }

    func parseEnsemble(_ input: Substring) -> FastaRecord {
        // ENSP00000391493 pep:known chromosome:GRCh37:2:160609001:160624471:1 gene:ENSG00000136536 transcript:ENST00000420397
        let info = input.components(separatedBy: " ")
        let proteinName = info[0]

        return FastaRecord(accession: "", entryName: "", proteinName: proteinName, organism: "", sequence: "")
    }

    func parseUnspecified(_ input: Substring) -> FastaRecord {
        // DROME_HH_Q02936
        // DECOY_IPI00339224 Decoy sequence
        let proteinName = input.replacingOccurrences(of: "_", with: " ")

        return FastaRecord(accession: "", entryName: "", proteinName: proteinName, organism: "", sequence: "")
    }
}

public final class FastaDecoder: TopLevelDecoder {
    public init() {}

    public func decode<T: Decodable>(_: T.Type, from data: Data) throws -> T {
        var records = [FastaRecord]()

        if let fastaArray = String(data: data, encoding: .ascii)?.components(separatedBy: "\n>") {
            records = fastaArray.concurrentMap { fastaLine in
                self.decodeRecord(from: fastaLine)
            }
        }

        return records as! T
    }

    func decodeRecord(from fastaLine: String) -> FastaRecord {
        let decoder = _FastaDecoder(fastaLine)

        do {
            return try FastaRecord(from: decoder)
        } catch {
            debugPrint(error)
        }

        return zeroFastaRecord
    }
}

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
extension FastaDecoder {
    func decodeRecords(with fastaData: Data) async -> [FastaRecord] {
        if let fastaArray = String(data: fastaData, encoding: .ascii)?.components(separatedBy: "\n>") {
            return await withTaskGroup(of: FastaRecord.self) { taskGroup in
                var records = [FastaRecord]()

                for fastaLine in fastaArray {
                    taskGroup.addTask {
                        await self.decodeRecord(from: fastaLine)
                    }
                }

                for await record in taskGroup {
                    records.append(record)
                }

                return records
            }
        }

        return []
    }

    func decodeRecord(from fastaLine: String) async -> FastaRecord {
        let decoder = _FastaDecoder(fastaLine)

        do {
            return try FastaRecord(from: decoder)
        } catch {
            debugPrint(error)
        }

        return zeroFastaRecord
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
    func container<Key>(keyedBy _: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
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
        let parser = FastaParser()

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

        func decode<T>(_: T.Type, forKey _: Key) throws -> T where T: Decodable {
            UUID() as! T
        }

        func nestedContainer<NestedKey>(keyedBy _: NestedKey.Type, forKey _: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
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
