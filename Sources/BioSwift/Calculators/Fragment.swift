//
//  Fragment.swift
//  BioSwift
//
//  Created by Koen van der Drift on 4/12/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public enum FragmentType { // this is only for peptides...
    case precursor
    case immonium
    case nTerminal
    case cTerminal
    case undefined
}

public protocol Fragment {
    var fragmentType: FragmentType { get set }
}
