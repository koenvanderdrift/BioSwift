//
//  Peptide.swift
//
//
//  Created by Koen van der Drift on 7/19/21.
//

import Foundation

public typealias Peptide = PolyPeptide

extension Peptide {
    public func fragment() -> [PeptideFragment] {
        precursorIons() + immoniumIons() + nTerminalIons() + cTerminalIons()
    }

    func precursorIons() -> [PeptideFragment] {
        var result: [PeptideFragment] = []

        let precursorIon = PeptideFragment(residues: residues, type: .precursorIon, adducts: adducts)
        result.append(precursorIon)

        if precursorIon.canLoseWater() {
            let precursorIonLossOfWater = PeptideFragment(residues: residues, type: .precursorIon, adducts: adducts, modifications: [LocalizedModification(lossOfWater, at: 0)])
            result.append(precursorIonLossOfWater)
        }

        if precursorIon.canLoseAmmonia() {
            let precursorIonLossOfAmmonia = PeptideFragment(residues: residues, type: .precursorIon, adducts: adducts, modifications: [LocalizedModification(lossOfAmmonia, at: 0)])
            result.append(precursorIonLossOfAmmonia)
        }

        return result
    }

    func immoniumIons() -> [PeptideFragment] {
        guard let symbols = symbolSet as? Set<AminoAcid> else { return [] }

        let result = symbols.map { symbol -> PeptideFragment in
            PeptideFragment(residues: [symbol], type: .immoniumIon, adducts: self.adducts)
        }

        return result
    }

    func nTerminalIons() -> [PeptideFragment] {
        var result = [PeptideFragment]()

        guard adducts.count > 0 else { return result }

        let startIndex = residues.startIndex

        for z in 1 ... min(2, adducts.count) {
            // add c1
            let cIon = PeptideFragment(residues: [residues[0]], type: .cIon, adducts: Array(repeatElement(protonAdduct, count: z)))
            
            if cIon.residues[0].oneLetterCode != "P" {
                if z == 1 {
                    result.append(cIon)
                } else {
                    if cIon.pseudomolecularIon().monoisotopicMass > pseudomolecularIon().monoisotopicMass {
                        result.append(cIon)
                    }
                }
            }

            for i in 2 ... residues.count - 1 {
                let index = residues.index(startIndex, offsetBy: i)

                let bIon = PeptideFragment(residues: Array(residues[..<index]), type: .bIon, adducts: Array(repeatElement(protonAdduct, count: z)), modifications: modifications)

                if z == 1 {
                    result.append(bIon)
                } else {
                    if bIon.pseudomolecularIon().monoisotopicMass > pseudomolecularIon().monoisotopicMass {
                        result.append(bIon)
                    }
                }

                if bIon.canLoseWater() {
                    let bIonLossOfWater = PeptideFragment(residues: bIon.residues, type: .bIon, adducts: bIon.adducts, modifications: [LocalizedModification(lossOfWater, at: 0)])
                    result.append(bIonLossOfWater)
                }

                if bIon.canLoseAmmonia() {
                    let bIonLossOfAmmonia = PeptideFragment(residues: bIon.residues, type: .bIon, adducts: bIon.adducts, modifications: [LocalizedModification(lossOfAmmonia, at: 0)])
                    result.append(bIonLossOfAmmonia)
                }

                let aIon = PeptideFragment(residues: bIon.residues, type: .aIon, adducts: bIon.adducts)

                if z == 1 {
                    result.append(aIon)
                } else {
                    if aIon.pseudomolecularIon().monoisotopicMass > pseudomolecularIon().monoisotopicMass {
                        result.append(aIon)
                    }
                }

                let cIon = PeptideFragment(residues: bIon.residues, type: .cIon, adducts: bIon.adducts)

                if cIon.residues.last?.oneLetterCode != "P" {
                    if z == 1 {
                        result.append(cIon)
                    } else {
                        if cIon.pseudomolecularIon().monoisotopicMass > pseudomolecularIon().monoisotopicMass {
                            result.append(cIon)
                        }
                    }
                }
            }
        }

        return result
    }

    func cTerminalIons() -> [PeptideFragment] {
        var result = [PeptideFragment]()

        guard adducts.count > 0 else { return result }

        let endIndex = residues.endIndex

        for z in 1 ... min(2, adducts.count) {
            for i in 1 ... residues.count - 1 {
                let index = residues.index(endIndex, offsetBy: -i)

                let yIon = PeptideFragment(residues: Array(residues[index ..< endIndex]), type: .yIon, adducts: Array(repeatElement(protonAdduct, count: z)))

                result.append(yIon)

                if i > 1 && yIon.canLoseWater() {
                    let yIonLossOfWater = PeptideFragment(residues: yIon.residues, type: .yIon, adducts: yIon.adducts, modifications: [LocalizedModification(lossOfWater, at: 0)])
                    result.append(yIonLossOfWater)
                }

                if yIon.canLoseAmmonia() {
                    let yIonLossOfAmmonia = PeptideFragment(residues: yIon.residues, type: .yIon, adducts: yIon.adducts, modifications: [LocalizedModification(lossOfAmmonia, at: 0)])
                    result.append(yIonLossOfAmmonia)
                }

                let xIon = PeptideFragment(residues: yIon.residues, type: .xIon, adducts: yIon.adducts)

                result.append(xIon)

                let zIon = PeptideFragment(residues: yIon.residues, type: .zIon, adducts: yIon.adducts)

                if zIon.residues.first?.oneLetterCode != "P" {
                    result.append(zIon)
                }
            }
        }

        return result.reversed()
    }

    //    public func isoElectricPoint() -> Double {
    //        let hydropathy = Hydropathy(symbolSet: CountedSet(sequenceString.map { String($0) }))
    //
    //        return hydropathy.isoElectricPoint()
    //    }
}

public struct PeptideFragment: RangedChain & Fragment {
    public var name: String = ""
    public var symbolLibrary: [Symbol] = aminoAcidLibrary

    public var residues: [AminoAcid] = []

    public var termini: (first: AminoAcid, last: AminoAcid)? = (nTerm, cTerm)
    public var adducts: [Adduct] = []
    public var modifications: [LocalizedModification] = []

    public var rangeInParent: ChainRange = zeroChainRange

    public var fragmentType: FragmentType = .undefined
}

public extension PeptideFragment {
    init(sequence: String) {
        self.residues = createResidues(from: sequence)
    }

    init(residues: [AminoAcid]) {
        self.residues = residues
    }

    init(residues: [AminoAcid], type: FragmentType, adducts: [Adduct], modifications: [LocalizedModification] = []) {
        self.residues = residues
        self.fragmentType = type
        self.adducts = adducts
        self.modifications = modifications
    }
}

public extension PeptideFragment {
    var masses: MassContainer {
        calculateMasses()
    }

    func calculateMasses() -> MassContainer {
        var result = mass(of: residues) + modificationMasses() + terminalMasses()

        if fragmentType == .precursorIon {
            result += water.masses
        }

        if fragmentType == .aIon || fragmentType == .cIon {
            if fragmentType == .aIon {
                result -= carbonyl.masses
            } else if fragmentType == .cIon {
                result += ammonia.masses // TODO:
            }
        } else if fragmentType == .yIon || fragmentType == .xIon || fragmentType == .zIon {
            result += water.masses

            if fragmentType == .xIon {
                result += (carbonyl.masses - 2 * hydrogen.masses)
            } else if fragmentType == .zIon {
                result -= oxygen.masses
            }
        }

        return result
    }

    func terminalMasses() -> MassContainer {
        return zeroMass
    }

    func canLoseWater() -> Bool {
        sequenceString.containsCharactersFrom(substring: "STED")
    }

    func canLoseAmmonia() -> Bool {
        sequenceString.containsCharactersFrom(substring: "RQNK")
    }
}
