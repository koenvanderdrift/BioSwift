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

extension PolyPeptide {
    public func fragment() -> [PeptideFragment] {
        return precursorIons() + immoniumIons() + nTerminalIons() + cTerminalIons()
    }
    
    func precursorIons() -> [PeptideFragment] {
        var fragment = PeptideFragment(residues: residues, type: .precursor, adducts: self.adducts)
        
        if canLoseAmmonia() {
            fragment.addModification(LocalizedModification(lossOfAmmonia, at: -1))
        }
        
        if canLoseWater() {
            fragment.addModification(LocalizedModification(lossOfWater, at: -1))
        }
        
        return [fragment]
    }
    
    func immoniumIons() -> [PeptideFragment] {
        guard let symbols = symbolSet as? Set<AminoAcid> else { return [] }
        
        let fragments = symbols.map { symbol -> PeptideFragment in
            let fragment = PeptideFragment(residues: [symbol], type: .immonium, adducts: self.adducts)
            
            return fragment
        }
        
        return fragments
    }
    
    func nTerminalIons() -> [PeptideFragment] { // b fragments
        var fragments = [PeptideFragment]()
        
        guard adducts.count > 0 else { return fragments }
        
        let startIndex = residues.startIndex
        
        for z in 1 ... min(2, adducts.count) {
            for i in 2 ... residues.count - 1 {
                let index = residues.index(startIndex, offsetBy: i)
                
                let fragment = PeptideFragment(residues: Array(residues[..<index]), type: .nTerminal, adducts: Array(repeatElement(protonAdduct, count: z)))
                
                if z == 1 {
                    fragments.append(fragment)
                } else {
                    if fragment.pseudomolecularIon().monoisotopicMass > pseudomolecularIon().monoisotopicMass {
                        fragments.append(fragment)
                    }
                }
            }
        }
        
        return fragments
    }
    
    func cTerminalIons() -> [PeptideFragment] { // y fragments
        var fragments = [PeptideFragment]()
        
        guard adducts.count > 0 else { return fragments }
        
        let endIndex = residues.endIndex
        
        for z in 1 ... min(2, adducts.count) {
            for i in 1 ... residues.count - 1 {
                let index = residues.index(endIndex, offsetBy: -i)
                
                let fragment = PeptideFragment(residues: Array(residues[..<index]), type: .cTerminal, adducts: Array(repeatElement(protonAdduct, count: z)))
                
                fragments.append(fragment)
            }
        }
        
        return fragments
    }
    
    func canLoseWater() -> Bool {
        return sequenceString.containsCharactersFrom(substring: "STED")
    }
    
    func canLoseAmmonia() -> Bool {
        return sequenceString.containsCharactersFrom(substring: "RQNK")
    }
    
    //    public func isoElectricPoint() -> Double {
    //        let hydropathy = Hydropathy(symbolSet: CountedSet(sequenceString.map { String($0) }))
    //
    //        return hydropathy.isoElectricPoint()
    //    }
    
}

extension PolyPeptide: Mass, Chargeable {
    public var masses: MassContainer {
        return calculateMasses()
    }
    
    public func calculateMasses() -> MassContainer {
        return mass(of: residues) + terminalMasses()
    }
}
