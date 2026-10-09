//
//  ProteinModifications.swift
//  BioSwift
//

import Foundation

/// Common protein and peptide neutral-loss modifications.
public let lossOfWater = Modification(
    name: "Loss of Water",
    reactions: [.remove(.functionalGroup(water))],
    specificities: [
        ModificationSpecificity(site: "S"),
        ModificationSpecificity(site: "T"),
        ModificationSpecificity(site: "E"),
        ModificationSpecificity(site: "D"),
    ]
)

public let lossOfAmmonia = Modification(
    name: "Loss of Ammonia",
    reactions: [.remove(.functionalGroup(ammonia))],
    specificities: [
        ModificationSpecificity(site: "R"),
        ModificationSpecificity(site: "Q"),
        ModificationSpecificity(site: "N"),
        ModificationSpecificity(site: "K"),
    ]
)

/// The elemental change produced when a disulfide bond forms between two thiols.
public let disulfideBond = Modification(
    name: "Disulfide bond",
    reactions: [
        .remove(.functionalGroup(hydrogen)),
        .remove(.functionalGroup(hydrogen)),
    ]
)
