import Foundation

private let lossOfWater = Modification(name: "Loss of Water", reactions: [.remove(water)], sites: ["S", "T", "E", "D"])
private let lossOfAmmonia = Modification(name: "Loss of Ammonia", reactions: [.remove(ammonia)], sites: ["R", "Q", "N", "K"])

public struct Peptide: RangedChain {
    public var residues: [AminoAcid] = []
    
    public var name: String = ""
    public var symbolLibrary: [Symbol] = uniAminoAcids
    
    public var termini: (first: Residue, last: Residue)? = (nTerm, cTerm)
    public var modifications: ModificationSet = ModificationSet()
    public var adducts: [Adduct] = []
    
    public var rangeInParent: ChainRange = zeroChainRange
}

extension Peptide {
    public init(sequence: String) {
        self.residues = createResidues(from: sequence)
    }
    
    public init(residues: [AminoAcid]) {
        self.residues = residues
    }

    public func fragment() -> [Fragment] {
        return precursorIons() + immoniumIons() + nTerminalIons() + cTerminalIons()
    }
    
    func precursorIons() -> [Fragment] {
        let fragment = Fragment(residues: residues, type: .precursor, adducts: self.adducts)
        
        if canLoseAmmonia() {
            //            fragment.modify(with: [Modification(modification: lossOfWater, location: -1)])
        }
        
        if canLoseWater() {
            //            fragment.modify(with: [Modification(modification: lossOfAmmonia, location: -1)])
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
        
        let startIndex = residues.startIndex
        
        for z in 1 ... min(2, adducts.count) {
            for i in 2 ... residues.count - 1 {
                let index = residues.index(startIndex, offsetBy: i)
                
                let fragment = Fragment(residues: Array(residues[..<index]), type: .nTerminal, adducts: Array(repeatElement(protonAdduct, count: z)))
                
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
        
        let endIndex = residues.endIndex
        
        for z in 1 ... min(2, adducts.count) {
            for i in 1 ... residues.count - 1 {
                let index = residues.index(endIndex, offsetBy: -i)
                
                let fragment = Fragment(residues: Array(residues[..<index]), type: .cTerminal, adducts: Array(repeatElement(protonAdduct, count: z)))
                
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

extension Peptide: Mass {
    public func calculateMasses() -> MassContainer {
        return mass(of: residues) + terminalMasses()
    }
}

extension Peptide: Chargeable {}
