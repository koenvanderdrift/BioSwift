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

public class SymbolSet: NSCountedSet {
    public func countFor(_ identifier: String) -> Int {
        let symbol = compactMap { $0 as? Symbol }.first(where: { $0.identifier == identifier })

        return count(for: symbol as Any)
    }
}
