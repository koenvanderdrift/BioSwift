//
//  SequenceRange.swift
//  BioSwift
//
//  Created by Koen van der Drift on 5/10/20.
//

import Foundation

public typealias SequenceRange = ClosedRange<Int>
public let zeroSequenceRange: SequenceRange = -1...0

extension NSRange {
    public func sequenceRange() -> SequenceRange {
        guard self.location != NSNotFound && self.length > 0 else { return zeroSequenceRange }

        return self.lowerBound...self.upperBound - 1
    }
}


