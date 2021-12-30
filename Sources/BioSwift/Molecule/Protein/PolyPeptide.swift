import Foundation

public let nTerm = AminoAcid(name: nTermString, oneLetterCode: "", formula: Formula("H"))
public let cTerm = AminoAcid(name: cTermString, oneLetterCode: "", formula: Formula("OH"))

public let lossOfWater = Modification(name: "Loss of Water", reactions: [.remove(water)], sites: ["S", "T", "E", "D"])
public let lossOfAmmonia = Modification(name: "Loss of Ammonia", reactions: [.remove(ammonia)], sites: ["R", "Q", "N", "K"])

public struct PolyPeptide: RangedChain {
    public var name: String = ""
    public var symbolLibrary: [Symbol] = uniAminoAcids
    
    public var residues: [AminoAcid] = []
    
    public var termini: (first: AminoAcid, last: AminoAcid)? = (nTerm, cTerm)
    public var adducts: [Adduct] = []
    public var modifications: ModificationSet = ModificationSet()
    
    public var rangeInParent: ChainRange = zeroChainRange
}

extension PolyPeptide {
    public init(sequence: String) {
        self.residues = createResidues(from: sequence)
    }
    
    public init(residues: [AminoAcid]) {
        self.residues = residues
    }
    
    public var nTerminalModification: Modification? {
        get {
            if let mod = termini?.first.modification {
                return mod
            }
            
            return nil
        }
        set {
            if var first = termini?.first, let last = termini?.last {
                first.setModification(newValue)
                
                setTermini(first: first, last: last)
            }
        }
    }

    public var cTerminalModification: Modification? {
        get {
            if let mod = termini?.last.modification {
                return mod
            }
            
            return nil
        }
        set {
            if let first = termini?.first, var last = termini?.last {
                last.setModification(newValue)
                
                setTermini(first: first, last: last)
            }
        }
    }
}

extension PolyPeptide: Mass, Chargeable {
    public var masses: MassContainer {
        return calculateMasses()
    }
    
    public func calculateMasses() -> MassContainer {
        return mass(of: residues) + terminalMasses()
    }
}
