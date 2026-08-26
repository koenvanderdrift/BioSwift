//
//  Fasta.swift
//  BioSwift
//
//  Created by Koen van der Drift on 8/18/20.
//  Copyright © 2020 - 2026 Koen van der Drift. All rights reserved.

import Foundation

public let zeroFastaRecord = FastaRecord(
    accession: "", shortName: "", fullName: "", organism: "", sequence: "")

public struct FastaRecord: Codable, Hashable, Identifiable, Sendable {
    // TODO: add DNA/RNA fasta parsing
    public let id: UUID
    public let accession: String
    public let shortName: String
    public let fullName: String
    public let organism: String
    public var sequence: String

    public init(
        accession: String, shortName: String, fullName: String, organism: String, sequence: String
    ) {
        id = UUID()
        self.accession = accession
        self.shortName = shortName
        self.fullName = fullName
        self.organism = organism
        self.sequence = sequence
    }
}

public func fastaRecords(from fileName: String, in bundle: Bundle = .main) async throws -> [FastaRecord] {
    try await FastaParser().parse(fileName, in: bundle)
}

public func fastaRecords(from data: Data) async throws -> [FastaRecord] {
    try await FastaParser().parse(data)
}

public func fastaRecords(fromText text: String) async throws -> [FastaRecord] {
    try await FastaParser().parseFasta(text)
}

public func proteins(fromFastaFile fileName: String, in bundle: Bundle = .main) async throws -> [Protein] {
    let records = try await fastaRecords(from: fileName, in: bundle)

    return records.map {
        Protein(fastaRecord: $0)
    }
}

/// FastaParser takes a text file as input and produces a ``FastaRecord`` array.
/// Currently, it can process SwissProt, UPS, IPI, and Ensemble files
public final class FastaParser {
    struct RawRecord {
        let info: String
        let sequence: String
    }

    public init() {
    }

    public func parse(_ fileName: String, in bundle: Bundle = .main) async throws -> [FastaRecord] {
        let fastaText = try loadText(from: fileName, withExtension: "fasta", in: bundle)
        let fullName = "\(fileName).fasta"

        do {
            return try await parseFasta(fastaText)
        } catch {
            throw LoadError.fileDecodingFailed(name: fullName, underlyingError: error)
        }
    }

    public func parse(_ data: Data) async throws -> [FastaRecord] {
        guard let fastaText = String(data: data, encoding: .utf8) else {
            throw LoadError.fileConversionFailed(name: "data", underlyingError: nil)
        }

        return try await parseFasta(fastaText)
    }

    public func parseBundleFile(_ fileName: String) async throws -> [FastaRecord] {
        try await parse(fileName, in: .module)
    }

    public func parseFasta(_ fastaText: String) async throws -> [FastaRecord] {
        let rawRecords = try splitRawRecords(from: fastaText)

        return try await rawRecords.concurrentMap {
            rawRecord in try self.parseRecord(rawRecord)
        }
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
            throw LoadError.fileParsingFailed(name: "records", underlyingError: nil)
        }

        let info = String(infoPart).trimmingCharacters(in: .whitespacesAndNewlines)

        let rawData = parts.count > 1 ? String(parts[1]) : ""

        let data = rawData.filter {
            !$0.isWhitespace
        }

        guard !info.isEmpty, !data.isEmpty else {
            throw LoadError.fileParsingFailed(name: "records", underlyingError: nil)
        }

        return RawRecord(info: info, sequence: data)
    }
}

extension FastaParser {
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

    func parseString(_ input: String) -> FastaRecord {
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
            let count = entry.distance(from: input.startIndex, to: nameRange.lowerBound)

            fullName = entry.skip(count) ?? ""
        }

        entry.skip(3)

        if let organismRange = entry.range(of: " ", options: .backwards) {
            let count = entry.distance(from: input.startIndex, to: organismRange.lowerBound)
            org = entry.skip(count) ?? ""
        }

        return FastaRecord(
            accession: String(acc ?? ""), shortName: String(shortName ?? ""),
            fullName: String(fullName), organism: String(org), sequence: "")
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

        return FastaRecord(
            accession: String(acc ?? ""), shortName: String(shortName ?? ""),
            fullName: String(fullName ?? ""), organism: String(org ?? ""), sequence: "")
    }

    func parseIPI(_ input: Substring) -> FastaRecord {
        // IPI00300415 IPI:IPI00300415.9|SWISS-PROT:Q8N431-1|TREMBL:D3DWQ7|ENSEMBL:ENSP00000354963;ENSP00000377037|REFSEQ:NP_778232|H-INV:HIT000094619|VEGA:OTTHUMP00000161522;OTTHUMP00000161538
        // Tax_Id=9606 Gene_Symbol=RASGEF1C Isoform 1 of Ras-GEF domain-containing family member 1C
        let info = input.components(separatedBy: "|")
        let acc = info.count > 1 ? info[1] : info.first ?? ""
        let fullName = info.last ?? ""

        // TODO: implement

        return FastaRecord(
            accession: acc, shortName: "", fullName: fullName, organism: "", sequence: "")
    }

    func parseEnsemble(_ input: Substring) -> FastaRecord {
        // ENSP00000391493 pep:known chromosome:GRCh37:2:160609001:160624471:1 gene:ENSG00000136536 transcript:ENST00000420397
        let info = input.components(separatedBy: " ")
        let fullName = info[0]

        // TODO: implement

        return FastaRecord(
            accession: "", shortName: "", fullName: fullName, organism: "", sequence: "")
    }

    func parseUnspecified(_ input: Substring) -> FastaRecord {
        // DROME_HH_Q02936
        // DECOY_IPI00339224 Decoy sequence
        let fullName = input.replacingOccurrences(of: "_", with: " ")

        // TODO: implement

        return FastaRecord(
            accession: "", shortName: "", fullName: fullName, organism: "", sequence: "")
    }
}

