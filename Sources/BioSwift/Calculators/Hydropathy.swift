//
//  Hydropathy.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/12/18.
//  Copyright © 2018 Koen van der Drift. All rights reserved.
//

import Foundation

public struct Hydro: Codable {
    public let name: String
    public let values: [String: String]
}

public class Hydropathy {
    public var residues = [Residue]()

    public init(residues: [Residue]) {
        self.residues = residues
    }

    public func isoElectricPoint() -> Double {
        if residues.count == 0 {
            return 0.0
        }
        // http://isoelectric.org/www_old/files/practise-isoelectric-point.html
        // https://stackoverflow.com/questions/30545518/how-to-count-occurrences-of-an-element-in-a-swift-array
        guard
            let pKaValues = hydropathyLibrary.first(where: { $0.name == "pKa" })?.values,
            let cTerminalpKa = Double(pKaValues["CTerminal"]!),
            let nTerminalpKa = Double(pKaValues["NTerminal"]!),
            let asparticAcidpKa = Double(pKaValues["D"]!),
            let glutamicAcidpKa = Double(pKaValues["E"]!),
            let cystinepKa = Double(pKaValues["C"]!),
            let tyrosinepKa = Double(pKaValues["Y"]!),
            let histidinepKa = Double(pKaValues["H"]!),
            let lysinepKa = Double(pKaValues["K"]!),
            let argininepKa = Double(pKaValues["R"]!)
        else { return 0.0 }

        let numberOfAsparticAcid = Double(residues.count { $0.oneLetterCode == "D" })
        let numberOfGlutamicAcid = Double(residues.count { $0.oneLetterCode == "E" })
        let numberOfCysteine = Double(residues.count { $0.oneLetterCode == "C" })
        let numberOfTyrosine = Double(residues.count { $0.oneLetterCode == "Y" })
        let numberOfHistidine = Double(residues.count { $0.oneLetterCode == "H" })
        let numberOfLysine = Double(residues.count { $0.oneLetterCode == "K" })
        let numberOfArginine = Double(residues.count { $0.oneLetterCode == "R" })

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
            let asparticAcidCharge = -1 * (numberOfAsparticAcid / (1 + pow(10, asparticAcidpKa - pH)))
            let glutamicAcidCharge = -1 * (numberOfGlutamicAcid / (1 + pow(10, glutamicAcidpKa - pH)))
            let cysteineCharge = -1 * (numberOfCysteine / (1 + pow(10, cystinepKa - pH)))
            let tyrosineCharge = -1 * (numberOfTyrosine / (1 + pow(10, tyrosinepKa - pH)))

            let nTerminalCharge = 1 / (1 + pow(10, pH - nTerminalpKa))
            let histidineCharge = numberOfHistidine / (1 + pow(10, pH - histidinepKa))
            let lysineCharge = numberOfLysine / (1 + pow(10, pH - lysinepKa))
            let arginineCharge = numberOfArginine / (1 + pow(10, pH - argininepKa))

            let neutralCharge = cTerminalCharge + asparticAcidCharge + glutamicAcidCharge + cysteineCharge + tyrosineCharge +
                nTerminalCharge + histidineCharge + lysineCharge + arginineCharge

            if neutralCharge < 0 { // we are out of range, thus the new pH value must be smaller
                let temp = pH
                pH = pH - ((pH - minpH) / 2)
                maxpH = temp
            } else { // we used too small of a pH value, so we have to increase it
                let temp = pH
                pH = pH + ((maxpH - pH) / 2)
                minpH = temp
            }
        }

        return pH
    }
}
