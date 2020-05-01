import Foundation

public let nTerm = AminoAcid(name: nTermString, oneLetterCode: "", formula: Formula("H"))
public let cTerm = AminoAcid(name: cTermString, oneLetterCode: "", formula: Formula("OH"))

public struct Protein: BioSequence, Chargeable {
    public var symbolLibrary: [Symbol] = uniAminoAcids
    public var residueSequence: [Residue] = []
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
    
    public var rangeInParent: Range<Int> = zeroSequenceRange
}

extension Protein {
    public init(sequence: String) {
        self.residueSequence = createResidueSequence(from: sequence)
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
