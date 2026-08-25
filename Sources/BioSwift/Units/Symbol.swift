//
//  Symbol.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/15/18.
//  Copyright © 2018 - 2026 Koen van der Drift. All rights reserved.
//

import Foundation

// Symbol holds a ``String`` as the identifier
public protocol Symbol {
    var identifier: String {
        get
    }
}

public typealias SymbolSet = NSCountedSet

