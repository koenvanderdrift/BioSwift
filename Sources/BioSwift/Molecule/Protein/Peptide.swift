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
        
        let fragment = PeptideFragment(residues: residues, type: .precursorIon, adducts: adducts)
        result.append(fragment)

        if fragment.canLoseWater() {
            let fragment = PeptideFragment(residues: residues, type: .precursorIon, adducts: adducts, modifications: [LocalizedModification(lossOfWater, at: 0)])
            result.append(fragment)
        }

        if fragment.canLoseAmmonia() {
            let fragment = PeptideFragment(residues: residues, type: .precursorIon, adducts: adducts, modifications: [LocalizedModification(lossOfAmmonia, at: 0)])
            result.append(fragment)
        }

        return result
    }

    func immoniumIons() -> [PeptideFragment] {
        guard let symbols = symbolSet as? Set<AminoAcid> else { return [] }

        let fragments = symbols.map { symbol -> PeptideFragment in
            let fragment = PeptideFragment(residues: [symbol], type: .immoniumIon, adducts: self.adducts)

            return fragment
        }

        return fragments
    }

    func nTerminalIons() -> [PeptideFragment] { // b fragments - TODO: add a ions
        var fragments = [PeptideFragment]()

        guard adducts.count > 0 else { return fragments }

        let startIndex = residues.startIndex

        for z in 1 ... min(2, adducts.count) {
            for i in 2 ... residues.count - 1 {
                let index = residues.index(startIndex, offsetBy: i)

                let bIon = PeptideFragment(residues: Array(residues[..<index]), type: .bIon, adducts: Array(repeatElement(protonAdduct, count: z)))

                if z == 1 {
                    fragments.append(bIon)
                } else {
                    if bIon.pseudomolecularIon().monoisotopicMass > pseudomolecularIon().monoisotopicMass {
                        fragments.append(bIon)
                    }
                }
                
                if bIon.canLoseWater() {
                    let fragment = PeptideFragment(residues: bIon.residues, type: .bIon, adducts: bIon.adducts, modifications: [LocalizedModification(lossOfWater, at: 0)])
                    fragments.append(fragment)
                }

                if bIon.canLoseAmmonia() {
                    let fragment = PeptideFragment(residues: bIon.residues, type: .bIon, adducts: bIon.adducts, modifications: [LocalizedModification(lossOfAmmonia, at: 0)])
                    fragments.append(fragment)
                }
                
                let aIon = PeptideFragment(residues: bIon.residues, type: .aIon, adducts: bIon.adducts, modifications: [LocalizedModification(lossOfCarbonyl, at: 0)])

                if z == 1 {
                    fragments.append(aIon)
                } else {
                    if aIon.pseudomolecularIon().monoisotopicMass > pseudomolecularIon().monoisotopicMass {
                        fragments.append(aIon)
                    }
                }
            }
        }

        return fragments
    }

    func cTerminalIons() -> [PeptideFragment] { // y fragments - TODO: add xions
        var fragments = [PeptideFragment]()

        guard adducts.count > 0 else { return fragments }

        let endIndex = residues.endIndex

        for z in 1 ... min(2, adducts.count) {
            for i in 1 ... residues.count - 1 {
                let index = residues.index(endIndex, offsetBy: -i)

                let yIon = PeptideFragment(residues: Array(residues[index..<endIndex]), type: .yIon, adducts: Array(repeatElement(protonAdduct, count: z)))

                fragments.append(yIon)

                if i > 1 && yIon.canLoseWater() {
                    let fragment = PeptideFragment(residues: yIon.residues, type: .yIon, adducts: yIon.adducts, modifications: [LocalizedModification(lossOfWater, at: 0)])
                    fragments.append(fragment)
                }

                if yIon.canLoseAmmonia() {
                    let fragment = PeptideFragment(residues: yIon.residues, type: .yIon, adducts: yIon.adducts, modifications: [LocalizedModification(lossOfAmmonia, at: 0)])
                    fragments.append(fragment)
                }
                
                let xIon = PeptideFragment(residues: yIon.residues, type: .xIon, adducts: yIon.adducts, modifications: [LocalizedModification(additionOfCarbonyl, at: 0)])

                fragments.append(xIon)
            }
        }

        return fragments.reversed()
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
        var result = mass(of: residues) + terminalMasses() + modificationMasses()
        
        if fragmentType == .precursorIon {
            result += water.masses
        }
        
        return result
    }

    func terminalMasses() -> MassContainer {
        var result = zeroMass
        
        if fragmentType == .yIon {
            result += (hydrogen.masses + hydroxyl.masses)
        }

        return result
    }
    
    func canLoseWater() -> Bool {
        sequenceString.containsCharactersFrom(substring: "STED")
    }

    func canLoseAmmonia() -> Bool {
        sequenceString.containsCharactersFrom(substring: "RQNK")
    }
}
