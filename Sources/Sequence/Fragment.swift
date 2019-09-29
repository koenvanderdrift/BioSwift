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
    public var sequenceType: SequenceType = .protein
    public let symbolLibrary: Symbols = aminoAcidLibrary
    public let fragmentType: FragmentType

    public var sequence: String = ""
    public var modifications: [Modification] = []

    public init(sequence: String) {
        self.fragmentType = .undefined
        self.sequence = sequence
    }
    
    public init(sequence: String, fragmentType: FragmentType) {
        self.fragmentType = fragmentType
        self.sequence = sequence
    }
    
    private var _charge: Int = 0
}

extension Fragment: MassChargeable {
    public var charge: Int {
        get {
            return _charge
        }
        set {
            _charge = newValue
        }
    }

    public var masses: MassContainer {
        return calculateMasses()
    }
    
    public func calculateMasses() -> MassContainer {
        if let sequenceMass = symbolSequence()?.compactMap({ $0 as? Mass })
            .reduce(zeroMass, {$0 + $1.masses}) {
            return sequenceMass + modificationMasses() + terminalMasses()
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
}
