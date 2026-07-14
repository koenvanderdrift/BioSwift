//
//  Range.swift
//  BioSwift
//
//  Created by Koen van der Drift on 23.05.2026.
//

import Foundation

// MARK: - Range Types

public let zeroRange: Range<Int> = 0 ..< 0

// UIRange is 1-based to be used in views, etc

public struct UIRange: Equatable {
    public let value: ClosedRange<Int>

    public init(_ value: ClosedRange<Int>) {
        precondition(
            value.lowerBound >= 1,
            "UIRange must be one-based.")

        self.value = value
    }

    public init?(validating value: ClosedRange<Int>) {
        guard value.lowerBound >= 1 else {
            return nil
        }

        self.value = value
    }

    public var zeroBasedRange: Range<Int> {
        (value.lowerBound - 1) ..< value.upperBound
    }

    public var isValidRange: Bool {
        value.lowerBound >= 0 && value.upperBound >= value.lowerBound
    }

    public var locationString: String {
        value.lowerBound == value.upperBound
            ? "\(value.lowerBound)"
            : "\(value.lowerBound) - \(value.upperBound)"
    }
}

extension UIRange: CustomStringConvertible {
    public var description: String {
        locationString
    }

    func toNSRange(
        clampedToTextLength textLength: Int) -> NSRange?
    {
        guard textLength > 0 else {
            return nil
        }

        /*
         UIRange is 1-based and inclusive.
         Ignore ranges that do not intersect the current text.
         */
        guard
            value.upperBound >= 1,
            value.lowerBound <= textLength
        else {
            return nil
        }

        let clampedLowerBound = Swift.max(
            1,
            value.lowerBound)

        let clampedUpperBound = Swift.min(
            textLength,
            value.upperBound)

        guard clampedUpperBound >= clampedLowerBound else {
            return nil
        }

        return NSRange(
            location: clampedLowerBound - 1,
            length: clampedUpperBound - clampedLowerBound + 1)
    }
}

public extension Range<Int> {
    var isZeroRange: Bool {
        self == zeroRange
    }

    var isValidRange: Bool {
        lowerBound >= 0 && upperBound >= lowerBound
    }

    var length: Int {
        guard isValidRange else {
            return 0
        }

        return upperBound - lowerBound + 1
    }

    func offset(by amount: Int) -> Range<Int> {
        (lowerBound + amount) ..< (upperBound + amount)
    }

    func clamped(toSequenceLength sequenceLength: Int) -> Range<Int> {
        guard isValidRange,
              sequenceLength > 0,
              lowerBound >= 0,
              upperBound <= sequenceLength
        else {
            return zeroRange
        }

        let lower = Swift.max(0, lowerBound)
        let upper = Swift.min(sequenceLength, upperBound)

        guard upper >= lower else {
            return zeroRange
        }

        return lower ..< upper
    }
}

public extension Range where Bound == Int {
    var uiRange: UIRange? {
        guard !isEmpty else {
            return nil
        }

        return UIRange(
            (lowerBound + 1) ... upperBound)
    }

    var endPoints: (from: Int, to: Int)? {
        guard !isEmpty else {
            return nil
        }

        return (
            from: lowerBound,
            to: upperBound - 1)
    }
}

// MARK: - ClosedRange<Int> conversions

public func range(from closedRange: ClosedRange<Int>) -> Range<Int> {
    closedRange.lowerBound ..< (closedRange.upperBound + 1)
}

// MARK: - Range<Int> conversions

public func closedRange(from range: Range<Int>) -> ClosedRange<Int>? {
    guard !range.isEmpty else {
        return nil
    }

    return range.lowerBound ... (range.upperBound - 1)
}
