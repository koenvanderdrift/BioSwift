//
//  FastaRecord.swift
//  BioSwift
//
//  Created by Koen van der Drift on 8/12/20.
//  Copyright © 2020 Koen van der Drift. All rights reserved.
//

import Foundation

public typealias Fasta = String

public struct FastaRecord: Hashable {
    public let id: String
    public let name: String
    public let organism: String
    public var sequence: String
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }
}

extension Fasta {
    public func serialize() -> FastaRecord? {
        // split the record in lines
        let lines = components(separatedBy: "\n")

        if let firstLine = lines.first {
            
            // info is in first line
            var record = parseInfo(input: firstLine)

            // sequence is the rest
            record.sequence = lines.dropFirst().joined()
            
            return record
        }

        return nil
    }

    func parseInfo(input: String) -> FastaRecord {
        // https://www.uniprot.org/help/fasta-headers
        // You can save repeated application of the `input` parameter by doing it
        // just once at the end (see the `return` of this func).
        let parse: (String) -> FastaRecord

        // The predicate of choice is made, in this case, String.hasPrefix.
        let hasPrefix = apply(instanceMethod: String.hasPrefix)

        // The switch calls `~=` for every case, giving it hasPrefix(...) and "input"
        // as args. The first case that makes `~=` yield `true` is executed.
        switch input {
        case hasPrefix("sp"), hasPrefix("swiss"), hasPrefix("tr"):
            parse = parseSwissProt
        case hasPrefix("IPI"):
            parse = parseIPI
        case hasPrefix("ENS"):
            parse = parseEnsemble
        default:
            parse = parseUnspecified
        }

        return parse(input)
    }

    func parseSwissProt(input: String) -> FastaRecord {
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
            return FastaRecord(id: "", name: "", organism: "", sequence: "")
        }
        
        return FastaRecord(id: id, name: n, organism: o, sequence: "")
    }

    func parseIPI(input: String) -> FastaRecord {
        // IPI00300415 IPI:IPI00300415.9|SWISS-PROT:Q8N431-1|TREMBL:D3DWQ7|ENSEMBL:ENSP00000354963;ENSP00000377037|REFSEQ:NP_778232|H-INV:HIT000094619|VEGA:OTTHUMP00000161522;OTTHUMP00000161538 Tax_Id=9606 Gene_Symbol=RASGEF1C Isoform 1 of Ras-GEF domain-containing family member 1C
        let info = input.components(separatedBy: "|")
        let id = info[1]
        let name = info.last!

        return FastaRecord(id: id, name: name, organism: "", sequence: "")
    }

    func parseEnsemble(input: String) -> FastaRecord {
        // ENSP00000391493 pep:known chromosome:GRCh37:2:160609001:160624471:1 gene:ENSG00000136536 transcript:ENST00000420397
        let info = input.components(separatedBy: " ")
        let name = info[0]

        return FastaRecord(id: "", name: name, organism: "", sequence: "")
    }

    func parseUnspecified(input: String) -> FastaRecord {
        // DROME_HH_Q02936
        // DECOY_IPI00339224 Decoy sequence
        let name = input.replacingOccurrences(of: "_", with: " ")

        return FastaRecord(id: "", name: name, organism: "", sequence: "")
    }
}
