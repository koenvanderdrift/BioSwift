//
//  Symbol.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/15/18.
//  Copyright © 2018 Koen van der Drift. All rights reserved.
//

import Foundation

public protocol Symbol {
    var identifier: String { get }
}

public protocol MassSymbol: Symbol, Mass {}
