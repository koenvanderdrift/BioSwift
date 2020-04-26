import Foundation

public let nTerm = AminoAcid(name: nTermString, oneLetterCode: "", formula: Formula("H"))
public let cTerm = AminoAcid(name: cTermString, oneLetterCode: "", formula: Formula("OH"))

public struct Protein: BioSequence, Chargeable {
    public var name: String = ""
    public var symbolLibrary: [Symbol] = uniAminoAcids
    public var residueSequence: [Residue] = []
    public var sequence: String = ""

    public var modifications: ModificationSet = ModificationSet()
    public var termini: (first: Residue, last: Residue)? = (nTerm, cTerm)
    public var adducts: [Adduct] = []
    public var rangeInParent: Range<Int> = 0..<0
}

extension Protein {
    public init(sequence: String) {
        self.sequence = sequence
    }
    
    public init(residues: [Residue]) {
        self.residueSequence = residues
    }

    public var masses: MassContainer {
        return calculateMasses()
    }
    
    public func calculateMasses() -> MassContainer {
        return mass(of: residueSequence) + terminalMasses()
    }
    
    public func setNTerminalModification(_ mod: Modification) {
//        termini?.first.setModification(mod)
    }
    
    public func setCTerminalModification(_ mod: Modification) {
//        termini?.last.setModification(mod)
    }
    
    public func nTerminalModification() -> Modification? {
        if let mod = termini?.first.modification {
            return mod
        }
        
        return nil
    }
    
    public func cTerminalModification() -> Modification? {
        if let mod = termini?.last.modification {
            return mod
        }
        
        return nil
    }
}

//public class Protein: BioSequence, Chargeable {
//    public var adducts: [Adduct] = []
//
//    public convenience init(residues: [Residue]) {
//        self.init(residues: residues, library: uniAminoAcids)
//
//        setUpTermini()
//    }
//
//    public init(sequence: String) {
//        super.init(sequence: sequence, library: uniAminoAcids)
//
//        setUpTermini()
//    }
//
//    public required init(residues: [Residue], library _: [Symbol]) {
//        super.init(residues: residues, library: uniAminoAcids)
//
//        setUpTermini()
//    }
//
//    private func setUpTermini() {
//        termini = (first: nTerm, last: cTerm)
//    }
//
//    public var masses: MassContainer {
//        return calculateMasses()
//    }
//
//    public func calculateMasses() -> MassContainer {
//        return mass(of: residueSequence) + terminalMasses()
//    }
//
//    public func setNTerminalModification(_ mod: Modification) {
//        termini?.first.setModification(mod)
//    }
//
//    public func setCTerminalModification(_ mod: Modification) {
//        termini?.last.setModification(mod)
//    }
//
//    public func nTerminalModification() -> Modification? {
//        if let mod = termini?.first.modification {
//            return mod
//        }
//
//        return nil
//    }
//
//    public func cTerminalModification() -> Modification? {
//        if let mod = termini?.last.modification {
//            return mod
//        }
//
//        return nil
//    }
//
//    func terminalMasses() -> MassContainer {
//        var result = zeroMass
//
//        if let nTerminal = termini?.first {
//            result += nTerminal.masses
//        }
//
//        if let cTerminal = termini?.last {
//            result += cTerminal.masses
//        }
//
//        return result
//    }
//}
//
//// extension Protein {
//
//// let url = URL(string: "http://www.uniprot.org/uniprot/P01009.fasta")!
//
////    public init?(fasta: Fasta) {
////        guard let fastaRecord = fasta.serializer() else { return nil }
////
////        self.sequenceString = fastaRecord.sequence
//////        super.init(sequence: fastaRecord.sequence, sequenceType: .protein)
////    }
//// }
//
//// public struct ProteinInfo {
////    public var fullName: String
////    public var altName: String
////    public var organism: String
////    public var accession: String
////    public var version: String
////    public var url: String
////    public var sequence: Protein
////
////    public init(fullName: String, altName: String, organism: String, accession: String, version: String, url: String, sequence: BioSequence) {
////        self.fullName = fullName
////        self.altName = altName
////        self.organism = organism
////        self.accession = accession
////        self.version = version
////        self.url = url
////        self.sequence = sequence
////    }
////
////    public init(with fasta: FastaRecord) {
////        fullName = fasta.name
////        altName = ""
////        organism = fasta.organism
////        accession = fasta.id
////        version = ""
////        url = ""
////        sequence = Protein(sequence: fasta.sequence, type: .protein)
////    }
//// }
