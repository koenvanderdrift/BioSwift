//
//  Range.swift
//  BioSwift
//
//  Created by Koen van der Drift on 23.05.2026.
//

import Foundation

// MARK: - Range Types

public typealias ChainRange = ClosedRange<Int>

/**
 ChainRange values are 1-based and inclusive.

 Examples:
     1...10    = characters 1 through 10
     81...115  = characters 81 through 115

 The zero range represents "no valid range".
 */
public let zeroChainRange: ChainRange = 0 ... 0

/**
 NSRange is zero-based.

 This value represents "no valid NSRange".
 Do not pass it to TextKit without first checking its length.
 */
public let zeroNSRange = NSRange(location: NSNotFound, length: 0)

public extension ChainRange {
    var isZeroRange: Bool {
        self == zeroChainRange
    }

    var isValidChainRange: Bool {
        lowerBound > 0 && upperBound >= lowerBound
    }

    var length: Int {
        guard isValidChainRange else {
            return 0
        }

        return upperBound - lowerBound + 1
    }

    func clamped(toSequenceLength sequenceLength: Int) -> ChainRange {
        guard isValidChainRange,
              sequenceLength > 0,
              upperBound >= 1,
              lowerBound <= sequenceLength
        else {
            return zeroChainRange
        }

        let lower = Swift.max(1, lowerBound)
        let upper = Swift.min(sequenceLength, upperBound)

        guard upper >= lower else {
            return zeroChainRange
        }

        return lower ... upper
    }

    /**
     Converts a 1-based inclusive ChainRange into a zero-based NSRange.

     The range is clamped only when it intersects the current text.
     A range entirely outside the text returns zeroNSRange.

     Examples for a text length of 100:

         1...10      -> NSRange(location: 0, length: 10)
         95...110    -> NSRange(location: 94, length: 6)
         120...130   -> zeroNSRange
         0...0       -> zeroNSRange
     */
    func toNSRange(
        clampedToTextLength textLength: Int
    ) -> NSRange {
        guard isValidChainRange,
              textLength > 0,
              upperBound >= 1,
              lowerBound <= textLength
        else {
            return zeroNSRange
        }

        let clampedLower = Swift.max(1, lowerBound)
        let clampedUpper = Swift.min(textLength, upperBound)

        guard clampedUpper >= clampedLower else {
            return zeroNSRange
        }

        return NSRange(
            location: clampedLower - 1,
            length: clampedUpper - clampedLower + 1
        )
    }

    /**
     Converts a valid ChainRange into an NSRange without clamping.

     Use this only when you do not need to validate against the current
     document length.
     */
    var nsRange: NSRange {
        guard isValidChainRange else {
            return zeroNSRange
        }

        return NSRange(
            location: lowerBound - 1,
            length: length
        )
    }

    var zeroBasedArrayRange: Range<Int>? {
        guard isValidChainRange else {
            return nil
        }

        return (lowerBound - 1) ..< upperBound
    }
}

public extension NSRange {
    /**
     Converts a zero-based NSRange into a 1-based inclusive ChainRange.

     Examples:
         NSRange(location: 0, length: 10)  -> 1...10
         NSRange(location: 80, length: 35) -> 81...115
     */
    func toChainRange() -> ChainRange {
        guard location != NSNotFound,
              length > 0
        else {
            return zeroChainRange
        }

        let lower = location + 1
        let upper = location + length

        return lower ... upper
    }

    /**
     Creates a zero-based NSRange from a 1-based inclusive ChainRange.
     */
    init(oneBased range: ChainRange) {
        guard range.isValidChainRange else {
            self = zeroNSRange
            return
        }

        self = NSRange(
            location: range.lowerBound - 1,
            length: range.length
        )
    }
}
