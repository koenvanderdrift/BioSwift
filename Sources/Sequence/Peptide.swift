import Foundation

private let lossOfWater = Modification(name: "Loss of Water", reactions: [.remove(water)], sites: ["S", "T", "E", "D"])
private let lossOfAmmonia = Modification(name: "Loss of Ammonia", reactions: [.remove(ammonia)], sites: ["R", "Q", "N", "K"])

public struct Peptide: BioSequence, Chargeable {
    public var symbolLibrary: [Symbol] = uniAminoAcids
    public var residueSequence: [Residue] = []
    public var sequenceString: String = ""
    public var termini: (first: Residue, last: Residue)? = (nTerm, cTerm)
    
    public var modifications: ModificationSet = ModificationSet()
    public var adducts: [Adduct] = []
    
    public var rangeInParent: Range<Int> = 0..<0
}

extension Peptide {
    public init(sequence: String) {
        self.sequenceString = sequence
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

    public func fragment() -> [Fragment] {
        return precursorIons() + immoniumIons() + nTerminalIons() + cTerminalIons()
    }
    
    func precursorIons() -> [Fragment] {
        let fragment = Fragment(residues: residueSequence, type: .precursor, adducts: self.adducts)
        
        if canLoseAmmonia() {
            //            fragment.modify(with: [LocalizedModification(modification: lossOfWater, location: -1)])
        }
        
        if canLoseWater() {
            //            fragment.modify(with: [LocalizedModification(modification: lossOfAmmonia, location: -1)])
        }
        
        return [fragment]
    }
    
    func immoniumIons() -> [Fragment] {
        guard let symbols = symbolSet as? Set<AminoAcid> else { return [] }
        
        let fragments = symbols.map { symbol -> Fragment in
            let fragment = Fragment(residues: [symbol], type: .immonium, adducts: self.adducts)
            
            return fragment
        }
        
        return fragments
    }
    
    func nTerminalIons() -> [Fragment] { // b fragments
        var fragments = [Fragment]()
        
        guard adducts.count > 0 else { return fragments }
        
        for z in 1 ... min(2, adducts.count) {
            for i in 2 ... residueSequence.count - 1 {
                let index = residueSequence.index(residueSequence.startIndex, offsetBy: i)
                
                let residues = residueSequence[..<index]
                let fragment = Fragment(residues: Array(residues), type: .nTerminal, adducts: Array(repeatElement(protonAdduct, count: z)))
                
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
    
    func cTerminalIons() -> [Fragment] { // y fragments
        var fragments = [Fragment]()
        
        guard adducts.count > 0 else { return fragments }
        
        for z in 1 ... min(2, adducts.count) {
            for i in 1 ... residueSequence.count - 1 {
                let index = residueSequence.index(residueSequence.endIndex, offsetBy: -i)
                
                let residues = residueSequence[..<index]
                let fragment = Fragment(residues: Array(residues), type: .cTerminal, adducts: Array(repeatElement(protonAdduct, count: z)))
                
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
