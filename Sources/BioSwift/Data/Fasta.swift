//
//  Fasta.swift
//  BioSwift
//
//  Created by Koen van der Drift on 8/18/20.
//

import Foundation
import Combine

public struct FastaRecord: Codable, Hashable {
    public let accession: String
    public let name: String
    public let organism: String
    public let sequence: String
    
    public init(accession: String, name: String, organism: String, sequence: String) {
        self.accession = accession
        self.name = name
        self.organism = organism
        self.sequence = sequence
    }
}

let zeroFastaRecord = FastaRecord(accession: "", name: "", organism: "", sequence: "")

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

public struct FastaDecoder: TopLevelDecoder {
    //
    // TODO: MORE ERROR CHECKING
    //
    public init() {}
    
    public func decode<T : Decodable>(_ type: T.Type, from data: Data) throws -> T {
        var records: [FastaRecord] = []
        
        if let fastaArray = String(data: data, encoding: .utf8)?
            .components(separatedBy: ">")
            .dropFirst() {
            
            records = Array(fastaArray).concurrentMap2( { fastaLine in
                var result: FastaRecord = zeroFastaRecord
                let decoder = _FastaDecoder(fastaLine)
                
                do {
                    result = try FastaRecord(from: decoder)
                } catch {
                    debugPrint(error)
                }
                
                return result
            })
        }
        
        return records as! T
    }
}

private final class _FastaDecoder: Decoder {
    
    //
    // via: https://talk.objc.io/episodes/S01E115-building-a-custom-xml-decoder
    //
    
    let codingPath: [CodingKey] = []
    let userInfo: [CodingUserInfoKey:Any] = [:]
    let input: String
    
    init(_ input: String) {
        self.input = input
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        return KeyedDecodingContainer(KDC(input))
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        fatalError("TODO")
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        fatalError("TODO")
    }
    
    struct KDC<Key: CodingKey>: KeyedDecodingContainerProtocol {
        var codingPath: [CodingKey] = []
        var allKeys: [Key] = []
        
        let lines: [String]
        var record: FastaRecord = zeroFastaRecord
        
        init(_ input: String) {
            self.lines = input.components(separatedBy: "\n")
            
            if let header = lines.first {
                self.record = parseHeader(input: header)
            }
        }
        
        func contains(_ key: Key) -> Bool {
            return true
        }
        
        func decodeNil(forKey key: Key) throws -> Bool {
            return true
        }
        
        func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
            return true
        }
        
        func decode(_ type: String.Type, forKey key: Key) throws -> String {
            switch key.stringValue {
            case "accession":
                return self.record.accession
            case "name":
                return self.record.name
            case "organism":
                return self.record.organism
            case "sequence":
                return lines.dropFirst().joined()
            default:
                return ""
            }
        }
        
        func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
            return 0
        }
        
        func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
            return 0
        }
        
        func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
            return 0
        }
        
        func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
            return 0
        }
        
        func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
            return 0
        }
        
        func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
            return 0
        }
        
        func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
            return 0
        }
        
        func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
            return 0
        }
        
        func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
            return 0
        }
        
        func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
            return 0
        }
        
        func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
            return 0
        }
        
        func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
            return 0
        }
        
        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
            fatalError("TODO")
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            fatalError("TODO")
        }
        
        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            fatalError("TODO")
        }
        
        func superDecoder() throws -> Decoder {
            fatalError("TODO")
        }
        
        func superDecoder(forKey key: Key) throws -> Decoder {
            fatalError("TODO")
        }
        
        func parseHeader(input: String) -> FastaRecord {
            // https://www.uniprot.org/help/fasta-headers
            
            let parser = FastaParser()
            
            if input.hasPrefix("sp") || input.hasPrefix("swiss") || input.hasPrefix("tr") {
                return parser.parseSwissProt(input)
            }
            else if input.hasPrefix("IPI") {
                return parser.parseIPI(input)
            }
            else if input.hasPrefix("ENS") {
                return parser.parseEnsemble(input)
            }
            
            return parser.parseUnspecified(input)
        }
    }
}

public struct FastaParser {
    func parseSwissProt(_ input: String) -> FastaRecord {
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
        
        var acc, name, org: NSString?
        
        let scanner = Scanner(string: input)
        scanner.scanUpTo("|", into: nil)
        scanner.scanString("|", into: nil)
        scanner.scanUpTo("|", into: &acc)
        scanner.scanUpTo(" ", into: nil)
        scanner.scanUpTo(" OS=", into: &name)
        
        let pattern = "([A-Z]{2}=)((.(?![A-Z]{2}=))*)"
        if let regex = try? NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options(rawValue: 0)) {
            let matches = regex.matches(in: input,
                                        options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                        range: NSMakeRange(0, input.count))
            for match in matches {
                if let s = input.substring(with: match.range), s.hasPrefix("OS")  {
                    org = s.components(separatedBy: "=").last as NSString?
                }
            }
        }
        
        guard let id = acc as String?, let n = name as String?, let o = org as String? else {
            return FastaRecord(accession: "", name: "", organism: "", sequence: "")
        }
        
        return FastaRecord(accession: id, name: n, organism: o, sequence: "")
    }
    
    func parseIPI(_ input: String) -> FastaRecord {
        // IPI00300415 IPI:IPI00300415.9|SWISS-PROT:Q8N431-1|TREMBL:D3DWQ7|ENSEMBL:ENSP00000354963;ENSP00000377037|REFSEQ:NP_778232|H-INV:HIT000094619|VEGA:OTTHUMP00000161522;OTTHUMP00000161538 Tax_Id=9606 Gene_Symbol=RASGEF1C Isoform 1 of Ras-GEF domain-containing family member 1C
        let info = input.components(separatedBy: "|")
        let acc = info[1]
        let name = info.last!
        
        return FastaRecord(accession: acc, name: name, organism: "", sequence: "")
    }
    
    func parseEnsemble(_ input: String) -> FastaRecord {
        // ENSP00000391493 pep:known chromosome:GRCh37:2:160609001:160624471:1 gene:ENSG00000136536 transcript:ENST00000420397
        let info = input.components(separatedBy: " ")
        let name = info[0]
        
        return FastaRecord(accession: "", name: name, organism: "", sequence: "")
    }
    
    func parseUnspecified(_ input: String) -> FastaRecord {
        // DROME_HH_Q02936
        // DECOY_IPI00339224 Decoy sequence
        let name = input.replacingOccurrences(of: "_", with: " ")
        
        return FastaRecord(accession: "", name: name, organism: "", sequence: "")
    }
}
