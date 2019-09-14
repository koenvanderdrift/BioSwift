import Foundation

public class Peptide: BioSequence {
    public override init(sequence: String, type: SequenceType = .protein, charge: Int = 0) {
        super.init(sequence: sequence, type: type, charge: charge)
    }
}

extension Peptide {
    public func fragment() -> [Fragment] {
        return precursorIons() + immoniumIons() + nTerminalIons() + cTerminalIons()
    }

    func precursorIons() -> [Fragment] {
        var fragments = [Fragment]()
        
        let fragment = Fragment(sequence: self.sequence, type: .protein, charge: self.charge, fragmentType: .precursor)
        
        fragments.append(fragment)
        
        if self.canLoseAmmonia() {
            let fragment = Fragment(sequence: self.sequence, type: .protein, charge: self.charge, fragmentType: .precursor)
            fragment.modifications = [Modification(group: FunctionalGroup(name: "lossOfAmmonia", masses: zeroMass - ammonia.masses), location: 0)]
            fragments.append(fragment)
        }

        if self.canLoseWater() {
            let fragment = Fragment(sequence: self.sequence, type: .protein, charge: self.charge, fragmentType: .precursor)
            fragment.modifications = [Modification(group: FunctionalGroup(name: "lossOfWater", masses: zeroMass - water.masses), location: 0)]
            fragments.append(fragment)
        }

        return fragments
    }
    
    func immoniumIons() -> [Fragment] {
        guard let symbols = self.symbolSet() as? Set<AminoAcid> else { return [] }
        
        return symbols.map { Fragment(sequence: $0.oneLetterCode, type: .protein, charge: $0.charge, fragmentType: .immonium) }
    }

    func nTerminalIons() -> [Fragment] { // b fragments
        var fragments = [Fragment]()

        guard self.charge > 0 else { return fragments }
        
        for z in 1 ... min(2, self.charge) {
            for i in 2 ... sequence.count - 1 {
                let index = sequence.index(sequence.startIndex, offsetBy: i) // let newStr = String(str[..<index])

                let fragment = Fragment(sequence: String(sequence[..<index]), type: self.type, charge: z, fragmentType: .nTerminal)
                fragment.charge = z
                
                if z == 1 {
                    fragments.append(fragment)
                } else {
                    if fragment.massOverCharge().monoisotopicMass > massOverCharge().monoisotopicMass {
                        fragments.append(fragment)
                    }
                }
            }
        }

        return fragments
    }

    func cTerminalIons() -> [Fragment] { // y fragments
        var fragments = [Fragment]()

        guard self.charge > 0 else { return fragments }
        
        for z in 1 ... min(2, self.charge) {
            for i in 1 ... sequence.count - 1 {
                let index = sequence.index(sequence.endIndex, offsetBy: -i)
                let fragment = Fragment(sequence: String(sequence[..<index]), type: self.type, charge: z, fragmentType: .cTerminal)

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


