import Foundation

public class Peptide: BioSequence {
    public override init(sequence: String, type: SequenceType = .protein, charge: Int) {
        
        super.init(sequence: sequence, type: type, charge: charge)
    }
}

extension Peptide {
    public func fragment() -> [Fragment] {
        return (nTerminalIons() + cTerminalIons())
            .sorted(by: { $0.massOverCharge().monoisotopicMass < $1.massOverCharge().monoisotopicMass })
    }

    func nTerminalIons() -> [Fragment] { // b ions
        var nTerminalFragmentIons: [Fragment] = []

        for z in 1 ... min(2, self.charge) {
            for i in 2 ... sequence.count - 1 {
                let index = sequence.index(sequence.startIndex, offsetBy: i) // let newStr = String(str[..<index])

                let fragment = Fragment(sequence: String(sequence[..<index]), type: .protein, charge: z, fragmentType: .nTerminal)
                fragment.charge = z
                
                if z == 1 {
                    nTerminalFragmentIons.append(fragment)
                } else {
                    if fragment.massOverCharge().monoisotopicMass > massOverCharge().monoisotopicMass {
                        nTerminalFragmentIons.append(fragment)
                    }
                }
            }
        }

        return nTerminalFragmentIons
            .sorted(by: { $0.masses.monoisotopicMass < $1.masses.monoisotopicMass })
    }

    func cTerminalIons() -> [Fragment] {
        // y ions
        var cTerminalFragmentIons: [Fragment] = []

        for z in 1 ... min(2, self.charge) {
            for i in 1 ... sequence.count - 1 {
                let index = sequence.index(sequence.endIndex, offsetBy: -i)
                let fragment = Fragment(sequence: String(sequence[..<index]), charge: z, fragmentType: .cTerminal)

                cTerminalFragmentIons.append(fragment)
            }
        }

        return cTerminalFragmentIons
            .sorted(by: { $0.masses.monoisotopicMass < $1.masses.monoisotopicMass })
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

extension Collection where Iterator.Element == Peptide {
    func charge(minCharge: Int, maxCharge: Int) -> [Peptide] {
        var peptides: [Peptide] = []

        for z in minCharge ... maxCharge {
            let chargedPeptides = map { (p) -> Peptide in
                return Peptide(sequence: p.sequence, type: .protein, charge: z)
            }

            peptides.append(contentsOf: chargedPeptides)
        }

        return peptides
    }
}

