import Foundation

public let nTerm = AminoAcid(name: nTermString, oneLetterCode: "", formula: Formula("H"))
public let cTerm = AminoAcid(name: cTermString, oneLetterCode: "", formula: Formula("OH"))

public let lossOfWater = Modification(name: "Loss of Water", reactions: [.remove(water)], sites: ["S", "T", "E", "D"])
public let lossOfAmmonia = Modification(name: "Loss of Ammonia", reactions: [.remove(ammonia)], sites: ["R", "Q", "N", "K"])

public struct Peptide2: RangedChain2 {
    public var chain: any Chain
    public var rangeInParent: ChainRange
}

public struct Peptide: RangedChain {
    public var name: String = ""
    public var symbolLibrary: [Symbol] = aminoAcidLibrary

    public var residues: [AminoAcid] = []

    public var termini: (first: AminoAcid, last: AminoAcid)? = (nTerm, cTerm)
    public var adducts: [Adduct] = []
    public var modifications: [LocalizedModification] = []

    public var rangeInParent: ChainRange = zeroChainRange
}

public extension Peptide {
    init(sequence: String) {
        residues = createResidues(from: sequence)
    }

    init(residues: [AminoAcid]) {
        self.residues = residues
    }

    var nTerminalModification: Modification? {
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

    var cTerminalModification: Modification? {
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

public extension Peptide {
    var masses: MassContainer {
        calculateMasses()
    }

    func calculateMasses() -> MassContainer {
        mass(of: residues) + terminalMasses() + modificationMasses()
    }

    func hydropathyValues(for hydropathyType: String) -> [Double] {
        let values = Hydropathy(residues: residues).hydrophathyValues(for: hydropathyType)

        return residues.compactMap { values[$0.oneLetterCode] }
    }

//    func isoElectricPoint() -> Double {
//        let hydropathy = Hydropathy(symbolSet: CountedSet(sequenceString.map { String($0) }))
//
//        return hydropathy.isoElectricPoint()
//    }
}
