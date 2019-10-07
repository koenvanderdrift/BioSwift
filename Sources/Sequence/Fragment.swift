//
//  Fragment.swift
//  BioSwift
//
//  Created by Koen van der Drift on 4/12/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public enum FragmentType {
    case precursor
    case immonium
    case nTerminal
    case cTerminal
    case undefined
}

public class Fragment: BioSequence {
    public let fragmentType: FragmentType
    public var adducts: [Adduct] = []
    
    public init(type: FragmentType, sequence: String) {
        self.fragmentType = type

        super.init(sequence: sequence)

        self.symbolLibrary = aminoAcidLibrary
        self.sequenceType = .protein
    }
    
    public required init(sequence: String) {
        fatalError("init(sequence:) has not been implemented")
    }
}

extension Fragment: Chargeable, Modifiable {
    public var masses: MassContainer {
        return calculateMasses()
    }
    
    public func calculateMasses() -> MassContainer {
        if let sequenceMass = symbolSequence()?.compactMap({ $0 as? Mass })
            .reduce(zeroMass, {$0 + $1.masses}) {
            return sequenceMass + modificationMasses() + terminalMasses() + adductMasses()
        }
        
        return zeroMass
    }
    
    private func terminalMasses() -> MassContainer {
        var result = zeroMass
        if fragmentType == .nTerminal {
            result -= (nterm.masses + cterm.masses)
        }
        
        return result
    }
    
    private func adductMasses() -> MassContainer {
        return adducts.reduce(zeroMass, {$0 + $1.group.masses})
    }
}
