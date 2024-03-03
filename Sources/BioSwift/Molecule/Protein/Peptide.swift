import Foundation

public let lossOfWater = Modification(name: "Loss of Water", reactions: [.remove(water)], sites: ["S", "T", "E", "D"])
public let lossOfAmmonia = Modification(name: "Loss of Ammonia", reactions: [.remove(ammonia)], sites: ["R", "Q", "N", "K"])

public struct Peptide: Chain {
    public var rangeInParent: ChainRange = zeroChainRange
    public var name: String = ""
    public var termini: (first: Modification, last: Modification)? = (nTermModification, cTermModification)
    public var modifications: [LocalizedModification] = []
    public var residues: [Residue] = []
    public var adducts: [Adduct] = []
    
    public func createResidues(from string: String) -> [Residue] {
        string.compactMap { char in
            aminoAcidLibrary.first(where: { $0.identifier == String(char) })
        }
    }
    
    public var aminoAcids: [AminoAcid] {
        residues as? [AminoAcid] ?? []
    }
}

extension Peptide {
    public init(sequence: String) {
        self.residues = createResidues(from: sequence)
    }

    public init(residues: [Residue]) {
        self.residues = residues as? [AminoAcid] ?? []
    }
    
    func hydropathyValues(for hydropathyType: String) -> [Double] {
        let values = Hydropathy(residues: residues).hydrophathyValues(for: hydropathyType)

        return residues.compactMap { values[$0.oneLetterCode] }
    }
}

