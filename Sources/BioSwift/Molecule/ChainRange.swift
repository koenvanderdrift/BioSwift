//
//  ChainRange.swift
//  BioSwift
//
//  Created by Koen van der Drift on 5/10/20.
//

import Foundation

public typealias ChainRange = ClosedRange<Int>

public let zeroChainRange: ChainRange = -1...0
public let zeroNSRange = NSMakeRange(NSNotFound, 0)

extension NSRange {
    public init(from range: ChainRange) {
        self = NSMakeRange(range.lowerBound, range.upperBound - range.lowerBound + 1)
    }
    
    public func chainRange() -> ChainRange {
        guard self.location != NSNotFound && self.length > 0 else { return zeroChainRange }

        return self.lowerBound...self.upperBound - 1
    }
}


