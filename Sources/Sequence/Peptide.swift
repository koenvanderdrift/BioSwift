import Foundation

public class Peptide: Protein {
    private let lossOfWater = Modification(name: "Loss of Water", reactions: [.remove(water)], sites: ["S", "T", "E", "D"])
    private let lossOfAmmonia = Modification(name: "Loss of Ammonia", reactions: [.remove(ammonia)], sites: ["R", "Q", "N", "K"])

    public func fragment() -> [Fragment] {
        return precursorIons() + immoniumIons() + nTerminalIons() + cTerminalIons()
    }

    func precursorIons() -> [Fragment] {
        let fragment = Fragment(residues: residueSequence, type: .precursor)
        
        if self.canLoseAmmonia() {
            fragment.setModification(with: (lossOfWater.name, -1))
        }

        if self.canLoseWater() {
            fragment.setModification(with: (lossOfAmmonia.name, -1))
        }

        return [fragment]
    }
    
    func immoniumIons() -> [Fragment] {
        guard let symbols = self.symbolSet() as? Set<AminoAcid> else { return [] }
        
        let fragments = symbols.map { symbol -> Fragment in
            let fragment = Fragment(residues: [symbol], type: .immonium)
            fragment.adducts = self.adducts
            
            return fragment
        }
        
        return fragments
    }

    func nTerminalIons() -> [Fragment] { // b fragments
        var fragments = [Fragment]()

        guard self.adducts.count > 0 else { return fragments }

        for z in 1 ... min(2, self.adducts.count) {
            for i in 2 ... residueSequence.count - 1 {
                let index = residueSequence.index(residueSequence.startIndex, offsetBy: i)
                
                let residues = residueSequence[..<index]
                let fragment = Fragment(residues: Array(residues), type: .nTerminal)
                
                fragment.adducts.append(contentsOf: repeatElement(protonAdduct, count: z))

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

        guard self.adducts.count > 0 else { return fragments }
        
        for z in 1 ... min(2, self.adducts.count) {
            for i in 1 ... residueSequence.count - 1 {
                let index = residueSequence.index(residueSequence.endIndex, offsetBy: -i)

                let residues = residueSequence[..<index]
                let fragment = Fragment(residues: Array(residues), type: .cTerminal)

                fragment.adducts.append(contentsOf: repeatElement(protonAdduct, count: z))

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


