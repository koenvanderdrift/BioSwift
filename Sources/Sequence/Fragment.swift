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
}

public class Fragment: BioSequence {
    public let fragmentType: FragmentType

    public init(sequence: String, type: SequenceType, charge: Int = 0, fragmentType: FragmentType) {
        self.fragmentType = fragmentType

        super.init(sequence: sequence, type: type, charge: charge)
    }
    
    public override func calculateMasses() -> MassContainer {
        var masses = super.calculateMasses()
        
        if fragmentType == .nTerminal {
            masses -= (nterm.masses + cterm.masses)
        }
        
        return masses
    }
}

