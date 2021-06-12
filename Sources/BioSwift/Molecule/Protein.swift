import Foundation

public let nTerm = AminoAcid(name: nTermString, oneLetterCode: "", formula: Formula("H"))
public let cTerm = AminoAcid(name: cTermString, oneLetterCode: "", formula: Formula("OH"))

public struct Protein: Chain {
    public var residues: [AminoAcid] = []

    public var name: String = ""
    public var symbolLibrary: [Symbol] = uniAminoAcids

    public var termini: (first: Residue, last: Residue)? = (nTerm, cTerm)    
    public var modifications: ModificationSet = [] {
        didSet {
            oldValue.forEach {
                removeModification(at: $0.location)
            }
            
            modifications.forEach {
                addModification($0)
            }
        }
    }

    public var adducts: [Adduct] = []
}

extension Protein {
    public init(sequence: String) {
        self.residues = createResidues(from: sequence)
    }
    
    public init(residues: [AminoAcid]) {
        self.residues = residues
    }

    public mutating func setNTerminalModification(_ mod: Modification) {
        if var first = termini?.first, let last = termini?.last {
            first.setModification(mod)
            
            setTermini(first: first, last: last)
        }
    }
    
    public mutating func setCTerminalModification(_ mod: Modification) {
        if let first = termini?.first, var last = termini?.last {
            last.setModification(mod)
            
            setTermini(first: first, last: last)
        }
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

extension Protein: Mass {
    public func calculateMasses() -> MassContainer {
        return mass(of: residues) + terminalMasses()
    }
}

extension Protein: Chargeable {}
