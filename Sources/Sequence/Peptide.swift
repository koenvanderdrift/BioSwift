import Foundation

public class Peptide: Protein {
    public func fragment() -> [Fragment] {
        return precursorIons() + immoniumIons() + nTerminalIons() + cTerminalIons()
    }

    func precursorIons() -> [Fragment] {
        let fragment = Fragment(residues: residueSequence, type: .precursor)
        
//        if self.canLoseAmmonia() {
//            fragment.modifications = [Modification(group: FunctionalGroup(name: "lossOfAmmonia", formula: Formula(stringValue: "-NH3")))]
//        }
//
//        if self.canLoseWater() {
//            fragment.modifications = [Modification(group: FunctionalGroup(name: "lossOfWater", formula: Formula(stringValue: "-H2O")))]
//        }

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


