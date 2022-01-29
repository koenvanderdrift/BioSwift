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
        return precursorIons() + immoniumIons() + nTerminalIons() + cTerminalIons()
    }
    
    func precursorIons() -> [PeptideFragment] {
        var fragment = PeptideFragment(residues: residues, type: .precursor, adducts: self.adducts)
        
        if canLoseAmmonia() {
            fragment.addModification(LocalizedModification(lossOfAmmonia, at: -1))
        }
        
        if canLoseWater() {
            fragment.addModification(LocalizedModification(lossOfWater, at: -1))
        }
        
        return [fragment]
    }
    
    func immoniumIons() -> [PeptideFragment] {
        guard let symbols = symbolSet as? Set<AminoAcid> else { return [] }
        
        let fragments = symbols.map { symbol -> PeptideFragment in
            let fragment = PeptideFragment(residues: [symbol], type: .immonium, adducts: self.adducts)
            
            return fragment
        }
        
        return fragments
    }
    
    func nTerminalIons() -> [PeptideFragment] { // b fragments
        var fragments = [PeptideFragment]()
        
        guard adducts.count > 0 else { return fragments }
        
        let startIndex = residues.startIndex
        
        for z in 1 ... min(2, adducts.count) {
            for i in 2 ... residues.count - 1 {
                let index = residues.index(startIndex, offsetBy: i)
                
                let fragment = PeptideFragment(residues: Array(residues[..<index]), type: .nTerminal, adducts: Array(repeatElement(protonAdduct, count: z)))
                
                if z == 1 {
                    fragments.append(fragment)
                } else {
                    if fragment.pseudomolecularIon().monoisotopicMass > pseudomolecularIon().monoisotopicMass {
                        fragments.append(fragment)
                    }
                }
            }
        }
        
        return fragments
    }
    
    func cTerminalIons() -> [PeptideFragment] { // y fragments
        var fragments = [PeptideFragment]()
        
        guard adducts.count > 0 else { return fragments }
        
        let endIndex = residues.endIndex
        
        for z in 1 ... min(2, adducts.count) {
            for i in 1 ... residues.count - 1 {
                let index = residues.index(endIndex, offsetBy: -i)
                
                let fragment = PeptideFragment(residues: Array(residues[..<index]), type: .cTerminal, adducts: Array(repeatElement(protonAdduct, count: z)))
                
                fragments.append(fragment)
            }
        }
        
        return fragments
    }
    
    func canLoseWater() -> Bool {
        return sequenceString.containsCharactersFrom(substring: "STED")
    }
    
    func canLoseAmmonia() -> Bool {
        return sequenceString.containsCharactersFrom(substring: "RQNK")
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

extension PeptideFragment {
    public init(sequence: String) {
        self.residues = createResidues(from: sequence)
    }
    
    public init(residues: [AminoAcid]) {
        self.residues = residues
    }

    public init(residues: [AminoAcid], type: FragmentType, adducts: [Adduct]) {
        self.residues = residues
        self.fragmentType = type
        self.adducts = adducts
    }
}

extension PeptideFragment {
    public var masses: MassContainer {
        return calculateMasses()
    }

    public func calculateMasses() -> MassContainer {
        return mass(of: residues) + terminalMasses()
    }

    public func terminalMasses() -> MassContainer {
        var result = zeroMass
        if fragmentType == .nTerminal {
            result -= (hydrogen.masses + hydroxyl.masses)
        }

        return result
    }
}

