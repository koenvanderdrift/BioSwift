import Foundation

public class Protein: BioSequence, Chargeable {    
    public var adducts: [Adduct] = []
    
    public required init(residues: [Residue]) {
        super.init(residues: residues)
        
        self.termini = (zeroAminoAcid, zeroAminoAcid)
    }

    public init(sequence: String) {
        super.init(sequence: sequence)

        self.termini = (zeroAminoAcid, zeroAminoAcid)
    }
    
    public required init(residues: [Residue], library: [Symbol]) {
        fatalError("init(residues:library:) has not been implemented")
    }
    
    public var masses: MassContainer {
        return calculateMasses()
    }
    
    public func calculateMasses() -> MassContainer {
        if symbolLibrary.count == 0 {
            symbolLibrary = uniAminoAcids
        }
        
        let result = mass(of: residueSequence) + terminalMasses() + adductMasses()

        return result
    }
    
    public func setNTerminalModification(_ mod: Modification) {
        termini?.0.setModification(mod)
    }
    
    public func setCTerminalModification(_ mod: Modification) {
        termini?.1.setModification(mod)
    }

    func terminalMasses() -> MassContainer {
        if let nTerminal = termini?.0, nTerminal.name.isEmpty, let res = uniAminoAcids.first(where: { $0.name == "N-term" }) {
            termini?.0 = res
        }
        
        if let cTerminal = termini?.1, cTerminal.name.isEmpty, let res = uniAminoAcids.first(where: { $0.name == "C-term" }) {
            termini?.1 = res
        }
        
        return (termini?.0.masses ?? zeroMass) + (termini?.1.masses ?? zeroMass)
    }
    
    func adductMasses() -> MassContainer {
        return adducts.reduce(zeroMass, {$0 + $1.group.masses})
    }
}

//extension Protein {

// let url = URL(string: "http://www.uniprot.org/uniprot/P01009.fasta")!

//    public init?(fasta: Fasta) {
//        guard let fastaRecord = fasta.serializer() else { return nil }
//
//        self.sequenceString = fastaRecord.sequence
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


