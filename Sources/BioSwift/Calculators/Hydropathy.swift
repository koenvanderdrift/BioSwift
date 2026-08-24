//
//  Hydropathy.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/12/18.
//  Copyright © 2018 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

public struct Hydro: Codable, Sendable {
    public let name: String
    public let values: [String: String]
    
    public init(name: String, values: [String : String]) {
        self.name = name
        self.values = values
    }
}

public class Hydropathy {
    public var residues: [AminoAcid] = []
    public var hydropathyReferences: HydropathyReferences

    public init(residues: [AminoAcid], hydropathyReferences: HydropathyReferences = HydropathyReferenceDefaults.bundled) {
        self.residues = residues
        self.hydropathyReferences = hydropathyReferences
    }

    public func isoElectricPoint() -> Double {
        Self.isoElectricPoint(for: residues, hydropathyReferences: hydropathyReferences)
    } 

    public static func isoElectricPoint<Residues: Sequence>(
        for residues: Residues,
        hydropathyReferences: HydropathyReferences = HydropathyReferenceDefaults.bundled
    ) -> Double where Residues.Element == AminoAcid {
        // http://isoelectric.org/www_old/files/practise-isoelectric-point.html
        let pKaValues = hydropathyValues(for: "pKa", hydropathyReferences: hydropathyReferences)

        guard let cTerminalpKa = pKaValues["CTerminal"], let nTerminalpKa = pKaValues["NTerminal"],
            let asparticAcidpKa = pKaValues["D"], let glutamicAcidpKa = pKaValues["E"],
            let cystinepKa = pKaValues["C"], let tyrosinepKa = pKaValues["Y"],
            let histidinepKa = pKaValues["H"], let lysinepKa = pKaValues["K"],
            let argininepKa = pKaValues["R"]
        else {
            return 0.0
        }

        var residueCount = 0
        var numberOfAsparticAcid = 0.0
        var numberOfGlutamicAcid = 0.0
        var numberOfCysteine = 0.0
        var numberOfTyrosine = 0.0
        var numberOfHistidine = 0.0
        var numberOfLysine = 0.0
        var numberOfArginine = 0.0

        for residue in residues {
            residueCount += 1

            switch residue.oneLetterCode {
            case "D":
                numberOfAsparticAcid += 1
            case "E":
                numberOfGlutamicAcid += 1
            case "C":
                numberOfCysteine += 1
            case "Y":
                numberOfTyrosine += 1
            case "H":
                numberOfHistidine += 1
            case "K":
                numberOfLysine += 1
            case "R":
                numberOfArginine += 1
            default:
                continue
            }
        }

        guard residueCount > 0 else {
            return 0.0
        }

        // starting point pI = 6.5 - theoretically it should be 7, but average protein pI is 6.5 so we increase the probability of finding the solution
        var pH = 6.5
        var minpH = 0.0
        var maxpH = 14.0
        let delta = 0.01

        while pH - minpH > delta, maxpH - pH > delta {
            if pH >= 14.0 {
                break
            }

            let cTerminalCharge = -1 * (1 / (1 + pow(10, cTerminalpKa - pH)))
            let asparticAcidCharge =
                -1 * (numberOfAsparticAcid / (1 + pow(10, asparticAcidpKa - pH)))
            let glutamicAcidCharge =
                -1 * (numberOfGlutamicAcid / (1 + pow(10, glutamicAcidpKa - pH)))
            let cysteineCharge = -1 * (numberOfCysteine / (1 + pow(10, cystinepKa - pH)))
            let tyrosineCharge = -1 * (numberOfTyrosine / (1 + pow(10, tyrosinepKa - pH)))

            let nTerminalCharge = 1 / (1 + pow(10, pH - nTerminalpKa))
            let histidineCharge = numberOfHistidine / (1 + pow(10, pH - histidinepKa))
            let lysineCharge = numberOfLysine / (1 + pow(10, pH - lysinepKa))
            let arginineCharge = numberOfArginine / (1 + pow(10, pH - argininepKa))

            let neutralCharge =
                cTerminalCharge + asparticAcidCharge + glutamicAcidCharge + cysteineCharge
                + tyrosineCharge + nTerminalCharge + histidineCharge + lysineCharge + arginineCharge

            if neutralCharge < 0 {  // we are out of range, thus the new pH value must be smaller
                let temp = pH
                pH = pH - ((pH - minpH) / 2)
                maxpH = temp
            } else {  // we used too small of a pH value, so we have to increase it
                let temp = pH
                pH = pH + ((maxpH - pH) / 2)
                minpH = temp
            }
        }

        return pH
    }

    public func hydropathyValues(for name: String) -> [String: Double] {
        Self.hydropathyValues(for: name, hydropathyReferences: hydropathyReferences)
    }

    private static func hydropathyValues(for name: String, hydropathyReferences: HydropathyReferences) -> [String: Double] {
        hydropathyReferences.numericHydropathyValues(named: name)
    }
}
