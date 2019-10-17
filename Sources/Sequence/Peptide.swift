import Foundation

public class Peptide: Protein {
    public func fragment() -> [Fragment] {
        return precursorIons() + immoniumIons() + nTerminalIons() + cTerminalIons()
    }

    func precursorIons() -> [Fragment] {
        var fragments = [Fragment]()
        
        let fragment = Fragment(type: .precursor, sequence: sequenceString)
        
        fragments.append(fragment)
        
        if self.canLoseAmmonia() {
            let fragment = Fragment(type: .precursor, sequence: sequenceString)
            fragment.modifications = [Modification(group: FunctionalGroup(name: "lossOfAmmonia", formula: Formula(stringValue: "-NH3")), location: 0)]
            fragments.append(fragment)
        }

        if self.canLoseWater() {
            let fragment = Fragment(type: .precursor, sequence: self.sequenceString)
            fragment.modifications = [Modification(group: FunctionalGroup(name: "lossOfWater", formula: Formula(stringValue: "-H2O")), location: 0)]
            fragments.append(fragment)
        }

        return fragments
    }
    
    func immoniumIons() -> [Fragment] {
        guard let symbols = self.symbolSet() as? Set<AminoAcid> else { return [] }
        
        return symbols.map { symbol in
            let fragment = Fragment(type: .immonium, sequence: symbol.oneLetterCode)
            fragment.adducts = self.adducts
            
            return fragment
        }
    }

    func nTerminalIons() -> [Fragment] { // b fragments
        var fragments = [Fragment]()

        guard self.adducts.count > 0 else { return fragments }

        for z in 1 ... min(2, self.adducts.count) {
            for i in 2 ... sequenceString.count - 1 {
                let index = sequenceString.index(sequenceString.startIndex, offsetBy: i) // let newStr = String(str[..<index])

                let fragment = Fragment(type: .nTerminal, sequence: String(sequenceString[..<index]))
                
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
            for i in 1 ... sequenceString.count - 1 {
                let index = sequenceString.index(sequenceString.endIndex, offsetBy: -i)
                let fragment = Fragment(type: .cTerminal, sequence: String(sequenceString[..<index]))

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


