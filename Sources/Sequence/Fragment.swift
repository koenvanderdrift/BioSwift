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

public struct Fragment: BioSequence {
    public let fragmentType: FragmentType

    public var sequenceType: SequenceType = .protein
    public let symbolLibrary: [Symbol] = aminoAcidLibrary
    public var sequenceString: String = ""
    public var modifications: [Modification] = []
    public var adducts: [Adduct] = []

    public init(sequenceString: String) {
        self.fragmentType = .undefined
        self.sequenceString = sequenceString
    }
    
    public init(sequenceString: String, fragmentType: FragmentType) {
        self.fragmentType = fragmentType
        self.sequenceString = sequenceString
    }
}

extension Fragment: Chargeable {
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
    
    private func modificationMasses() -> MassContainer {
        return modifications.reduce(zeroMass, {$0 + $1.group.masses})
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
