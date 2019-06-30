//
//  Scanner.swift
//  BioSwift
//
//  Created by Koen van der Drift on 1/31/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

extension Scanner {
    func scanInt() -> Int? {
        var x: Int = 0
        guard scanInt(&x) else { return 0 }
        return x
    }

    func scanCharactersFromSet(set: CharacterSet) -> NSString? {
        var value: NSString? = ""
        guard scanCharacters(from: set, into: &value) else { return nil }
        
        return value
    }
}
