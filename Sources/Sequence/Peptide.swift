import Foundation

public typealias Peptide = Protein

extension Peptide: Equatable {
    public static func == (lhs: Peptide, rhs: Peptide) -> Bool {
        return lhs.sequence == rhs.sequence
    }
}

extension Peptide {
    public func fragment() -> [Fragment] {
        return precursorIons() + immoniumIons() + nTerminalIons() + cTerminalIons()
    }

    func precursorIons() -> [Fragment] {
        var fragments = [Fragment]()
        
        let fragment = Fragment(sequence: sequence, fragmentType: .precursor)
        
        fragments.append(fragment)
        
        if self.canLoseAmmonia() {
            var fragment = Fragment(sequence: sequence, fragmentType: .precursor)
            fragment.modifications = [Modification(group: FunctionalGroup(name: "lossOfAmmonia", formula: "-NH3"), location: 0)]
            fragments.append(fragment)
        }

        if self.canLoseWater() {
            var fragment = Fragment(sequence: self.sequence, fragmentType: .precursor)
            fragment.modifications = [Modification(group: FunctionalGroup(name: "lossOfWater", formula: "-H2O"), location: 0)]
            fragments.append(fragment)
        }

        return fragments
    }
    
    func immoniumIons() -> [Fragment] {
        guard let symbols = self.symbolSet() as? Set<AminoAcid> else { return [] }
        
        return symbols.map { symbol in
            var fragment = Fragment(sequence: symbol.oneLetterCode, fragmentType: .immonium)
            fragment.adducts = self.adducts
            
            return fragment
        }
    }

    func nTerminalIons() -> [Fragment] { // b fragments
        var fragments = [Fragment]()

        guard self.adducts.count > 0 else { return fragments }

        for z in 1 ... min(2, self.adducts.count) {
            for i in 2 ... sequence.count - 1 {
                let index = sequence.index(sequence.startIndex, offsetBy: i) // let newStr = String(str[..<index])

                var fragment = Fragment(sequence: String(sequence[..<index]), fragmentType: .nTerminal)
                
                for _ in 1..<z {
                    fragment.adducts.append(protonAdduct)
                }

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
            for i in 1 ... sequence.count - 1 {
                let index = sequence.index(sequence.endIndex, offsetBy: -i)
                var fragment = Fragment(sequence: String(sequence[..<index]), fragmentType: .cTerminal)

                for _ in 1..<z {
                    fragment.adducts.append(protonAdduct)
                }

                fragments.append(fragment)
            }
        }

        return fragments
    }

    func canLoseWater() -> Bool {
        return sequence.containsCharactersFrom(substring: "STED")
    }

    func canLoseAmmonia() -> Bool {
        return sequence.containsCharactersFrom(substring: "RQNK")
    }

//    public func isoElectricPoint() -> Double {
//        let hydropathy = Hydropathy(symbolSet: CountedSet(sequenceString.map { String($0) }))
//
//        return hydropathy.isoElectricPoint()
//    }
}


