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

public typealias SymbolSet = NSCountedSet

extension SymbolSet {
    public func countFor(_ identifier: String) -> Int {
        guard let symbol = compactMap({ $0 as? Symbol })
                .first(where: { $0.identifier == identifier })
        else { return 0 }
        
        return count(for: symbol)
    }
}
