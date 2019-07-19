//
//  Hydropathy.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/12/18.
//  Copyright © 2018 Koen van der Drift. All rights reserved.
//

import Foundation

public var hydropathyLibrary: [Hydro] = loadJSONFromBundle(fileName: "hydropathy")

public struct Hydro: Codable {
    public let name: String
    public let values: [String: String]
}

public class Hydropathy {
    public var symbolSet = SymbolSet()
    
    public init(symbolSet: SymbolSet) {
        self.symbolSet = symbolSet
    }
    
    public func isoElectricPoint() -> Double {
        
// http://isoelectric.org/www_old/files/practise-isoelectric-point.html
// https://stackoverflow.com/questions/30545518/how-to-count-occurrences-of-an-element-in-a-swift-array

        let pKaDict = valuesDictionary(for: "pKa")
        
        guard
            let cTerminalpKa = pKaDict["CTerminal"],
            let nTerminalpKa = pKaDict["NTerminal"],
            let asparticAcidpKa = pKaDict["D"],
            let glutamicAcidpKa = pKaDict["E"],
            let cystinepKa = pKaDict["C"],
            let tyrosinepKa = pKaDict["Y"],
            let histidinepKa = pKaDict["H"],
            let lysinepKa = pKaDict["K"],
            let argininepKa = pKaDict["R"]
        else { return (0.0) }

        let numberOfAsparticAcid = symbolSet.countFor("D")
        let numberOfGlutamicAcid = symbolSet.countFor("E")
        let numberOfCysteine = symbolSet.countFor("C")
        let numberOfTyrosine = symbolSet.countFor("Y")
        let numberOfHistidine = symbolSet.countFor("H")
        let numberOfLysine = symbolSet.countFor("K")
        let numberOfArginine = symbolSet.countFor("R")

        // starting point pI = 6.5 - theoretically it should be 7, but average protein pI is 6.5 so we increase the probability of finding the solution
        var pH = 6.5
        var minpH = 0.0
        var maxpH = 14.0
        let delta = 0.01
        var temp = 0.0

        var cTerminalCharge = 0.0
        var asparticAcidCharge = 0.0
        var glutamicAcidCharge = 0.0
        var cysteineCharge = 0.0
        var tyrosineCharge = 0.0

        var nTerminalCharge = 0.0
        var histidineCharge = 0.0
        var lysineCharge = 0.0
        var arginineCharge = 0.0

        var neutralCharge = 0.0

        while pH - minpH > delta, maxpH - pH > delta {
            cTerminalCharge = -(1 / (1 + pow(10, cTerminalpKa - pH)))
            asparticAcidCharge = -(Double(numberOfAsparticAcid) / (1 + pow(10, asparticAcidpKa - pH)))
            glutamicAcidCharge = -(Double(numberOfGlutamicAcid) / (1 + pow(10, glutamicAcidpKa - pH)))
            cysteineCharge = -(Double(numberOfCysteine) / (1 + pow(10, cystinepKa - pH)))
            tyrosineCharge = -(Double(numberOfTyrosine) / (1 + pow(10, tyrosinepKa - pH)))

            nTerminalCharge = 1 / (1 + pow(10, pH - nTerminalpKa))
            histidineCharge = Double(numberOfHistidine) / (1 + pow(10, pH - histidinepKa))
            lysineCharge = Double(numberOfLysine) / (1 + pow(10, pH - lysinepKa))
            arginineCharge = Double(numberOfArginine) / (1 + pow(10, pH - argininepKa))

            neutralCharge = cTerminalCharge + asparticAcidCharge + glutamicAcidCharge + cysteineCharge + tyrosineCharge +
                nTerminalCharge + histidineCharge + lysineCharge + arginineCharge

            if pH >= 14.0 {
                break
            }
            if neutralCharge < 0 { // we are out of range, thus the new pH value must be smaller
                temp = pH
                pH = pH - ((pH - minpH) / 2)
                maxpH = temp
            } else { // we used too small of a pH value, so we have to increase it
                temp = pH
                pH = pH + ((maxpH - pH) / 2)
                minpH = temp
            }
        }

        return pH
    }

    private func valuesDictionary(for name: String) -> [String: Double] {
        var valuesDictionary = [String: Double]()

        let flatMappedValues = (hydropathyLibrary.filter { $0.name == name }.map { $0.values }).flatMap { $0 }

        flatMappedValues.forEach {
            valuesDictionary[$0.0] = Double($0.1)
        }

        return valuesDictionary
    }
}
