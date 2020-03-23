import Foundation

public let nTermMod = Modification(name: nTermString, reactions: [.add(hydrogen)])
public let cTermMod = Modification(name: cTermString, reactions: [.add(hydroxyl)])

public class Protein: BioSequence, Chargeable {    
    public var adducts: [Adduct] = []
    
    public required init(residues: [Residue]) {
        super.init(residues: residues)

        setUpTermini()
    }

    public init(sequence: String) {
        super.init(sequence: sequence)

        setUpTermini()
    }
    
    public required init(residues: [Residue], library: [Symbol]) {
        fatalError("init(residues:library:) has not been implemented")
    }
    
    private func setUpTermini() {
        self.termini = (zeroAminoAcid, zeroAminoAcid)
        
        setNTerminalModification(nTermMod)
        setCTerminalModification(cTermMod)
    }
    
    public var masses: MassContainer {
        return calculateMasses()
    }
    
    public func calculateMasses() -> MassContainer {
        if symbolLibrary.count == 0 {
            symbolLibrary = uniAminoAcids
        }
        
        let result = mass(of: residueSequence) + terminalMasses()

        return result
    }
    
    public func setNTerminalModification(_ mod: Modification) {
        termini?.0.setModification(mod)
    }
    
    public func setCTerminalModification(_ mod: Modification) {
        termini?.1.setModification(mod)
    }
    
    public func nTerminalModification() -> Modification? {
        if let mod = termini?.0.modification {
            return mod
        }
        
        return nil
    }

    public func cTerminalModification() -> Modification? {
        if let mod = termini?.1.modification {
            return mod
        }
        
        return nil
    }

    func terminalMasses() -> MassContainer {
        var result = zeroMass
        
        if let nTerminal = termini?.0, nTerminal.name.isEmpty {
            result += nTerminal.masses
        }
        
        if let cTerminal = termini?.1, cTerminal.name.isEmpty {
            result += cTerminal.masses
        }
        
        return result
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


