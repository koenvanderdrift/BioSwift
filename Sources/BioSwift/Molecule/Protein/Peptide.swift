import Foundation

public let lossOfWater = Modification(name: "Loss of Water", reactions: [.remove(water)], sites: ["S", "T", "E", "D"])
public let lossOfAmmonia = Modification(name: "Loss of Ammonia", reactions: [.remove(ammonia)], sites: ["R", "Q", "N", "K"])

public typealias Peptide = Chain<AminoAcid>

public extension Peptide {
//    func canLoseWater() -> Bool {
//        return sequenceString.containsCharactersFrom(substring: "STED")
//    }
//    
//    func canLoseAmmonia() -> Bool {
//        return sequenceString.containsCharactersFrom(substring: "RQNK")
//    }

    func hydropathyValues(for hydropathyType: String) -> [Double] {
        let values = Hydropathy(residues: residues).hydrophathyValues(for: hydropathyType)

        return residues.compactMap { values[$0.oneLetterCode] }
    }
}
