import Foundation

public struct Protein: BioSequence {
    
    public var sequenceType: SequenceType = .protein
    public var symbolLibrary: Symbols = aminoAcidLibrary
    public var sequence: String = ""
    public var modifications: [Modification] = []
    
    public init(sequence: String) {
        self.sequence = sequence
    }

    private var _charge = 0
}

extension Protein: MassChargeable {
    public var charge: Int {
        get {
            return _charge
        }
        set {
            _charge = newValue
        }
    }

    public var masses: MassContainer {
        return calculateMasses()
    }
    
    public func calculateMasses() -> MassContainer {
        if let sequenceMass = symbolSequence()?.compactMap({ $0 as? Mass })
            .reduce(zeroMass, {$0 + $1.masses}) {
            return sequenceMass + modificationMasses() + terminalMasses() + adductMasses()
        }
        
        return zeroMass
    }
    
    private func modificationMasses() -> MassContainer {
        return modifications.reduce(zeroMass, {$0 + $1.group.masses})
    }
    
    private func terminalMasses() -> MassContainer {
        return nterm.masses + cterm.masses
    }
    
    private func adductMasses() -> MassContainer {
        return zeroMass
    }
}

//extension Protein {

// let url = URL(string: "http://www.uniprot.org/uniprot/P01009.fasta")!

//    public init?(fasta: Fasta) {
//        guard let fastaRecord = fasta.serializer() else { return nil }
//
//        self.sequenceString = fastaRecord.sequence
//        self.sequenceType = .protein
////        super.init(sequence: fastaRecord.sequence, sequenceType: .protein)
//    }
//}

//public struct ProteinInfo {
//    public var fullName: String
//    public var altName: String
//    public var organism: String
//    public var accession: String
//    public var version: String
//    public var url: String
//    public var sequence: Protein
//
//    public init(fullName: String, altName: String, organism: String, accession: String, version: String, url: String, sequence: BioSequence) {
//        self.fullName = fullName
//        self.altName = altName
//        self.organism = organism
//        self.accession = accession
//        self.version = version
//        self.url = url
//        self.sequence = sequence
//    }
//
//    public init(with fasta: FastaRecord) {
//        fullName = fasta.name
//        altName = ""
//        organism = fasta.organism
//        accession = fasta.id
//        version = ""
//        url = ""
//        sequence = Protein(sequence: fasta.sequence, type: .protein)
//    }
//}


