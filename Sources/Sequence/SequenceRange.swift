//
//  SequenceRange.swift
//  BioSwift
//
//  Created by Koen van der Drift on 5/10/20.
//

import Foundation

public typealias SequenceRange = ClosedRange<Int>
public let zeroSequenceRange: SequenceRange = 0...0

extension NSRange {
    public func sequenceRange() -> SequenceRange {
        
        var range = zeroSequenceRange
        debugPrint(self)
        if self.location != NSNotFound && self.length > 0 {
            range = self.lowerBound...self.upperBound - 1
        }
        debugPrint(range)
        
        return range
    }
}


