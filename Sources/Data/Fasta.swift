import Foundation

public typealias Fasta = String

public struct FastaRecord {
    public let id: String
    public let name: String
    public let organism: String
    public var sequence: String
}

extension Fasta {
    public func serializer() -> FastaRecord? {
        // split the record in lines
        let lines = components(separatedBy: "\n")

        // info is in first line
        var record = parseInfo(input: lines.first!)

        // sequence is the rest
        record.sequence = lines.dropFirst().joined()

        return record
    }

//    "(?<!-)>"

//    public func proteins() -> [Protein] {
//        let indices = self.indices(of: "(?<!-)>", options: .regularExpression)
//        dump(indices)
//        return components(separatedBy: ">")
//            .dropFirst()
//            .compactMap(Protein.init)
//    }

    func parseInfo(input: String) -> FastaRecord {
        // You can save repeated application of the `input` parameter by doing it
        // just once at the end (see the `return` of this func).
        let parse: (String) -> FastaRecord

        // The predicate of choice is made, in this case, String.hasPrefix.
        let hasPrefix = apply(instanceMethod: String.hasPrefix)

        // The switch calls `~=` for every case, giving it hasPrefix(...) and "input"
        // as args. The first case that makes `~=` yield `true` is executed.
        switch input {
        case hasPrefix("sp"), hasPrefix("swiss"):
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
        // sp|P01009|A1AT_HUMAN Alpha-1-antitrypsin OS=Homo sapiens GN=SERPINA1 PE=1 SV=3
        let info = input.components(separatedBy: "|")
        let id = info[1]
        let name = info[2]

        return FastaRecord(id: id, name: name, organism: "", sequence: "")
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
