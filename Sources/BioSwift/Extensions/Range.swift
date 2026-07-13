//
//  Range.swift
//  BioSwift
//
//  Created by Koen van der Drift on 23.05.2026.
//

import Foundation

// MARK: - Range Types

public let zeroRange: Range<Int> = 0 ..< 0
public let zeroNSRange = NSRange(location: NSNotFound, length: 0)

// UIRange is 1-based to be used in views, etc

public struct UIRange: Equatable {
    public let value: ClosedRange<Int>

    public init(_ value: ClosedRange<Int>) {
        precondition(
            value.lowerBound >= 1,
            "UIRange must be one-based."
        )

        self.value = value
    }

    public init?(validating value: ClosedRange<Int>) {
        guard value.lowerBound >= 1 else {
            return nil
        }

        self.value = value
    }
    
    public init?(nsRange: NSRange) {
        guard
            nsRange.location != NSNotFound,
            nsRange.location >= 0,
            nsRange.length > 0
        else {
            return nil
        }

        let lowerBound = nsRange.location + 1
        let upperBound = nsRange.location + nsRange.length

        self.init(lowerBound ... upperBound)
    }

    public var zeroBasedRange: Range<Int> {
        (value.lowerBound - 1) ..< value.upperBound
    }
    
    public var isValidRange: Bool {
        value.lowerBound >= 0 && value.upperBound >= value.lowerBound
    }
}

extension UIRange: CustomStringConvertible {
     public var description: String {
        "\(value.lowerBound) - \(value.upperBound)"
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
              upperBound < sequenceLength
        else {
            return zeroRange
        }

        let lower = Swift.max(0, lowerBound)
        let upper = Swift.min(sequenceLength - 1, upperBound)

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
            (lowerBound + 1) ... upperBound
        )
    }
}


// MARK: - ClosedRange<Int> conversions

public func range(from closedRange: ClosedRange<Int>) -> Range<Int> {
    closedRange.lowerBound ..< (closedRange.upperBound + 1)
}

public func nsRange(from closedRange: ClosedRange<Int>) -> NSRange {
    NSRange(
        location: closedRange.lowerBound,
        length: closedRange.upperBound - closedRange.lowerBound + 1)
}

// MARK: - Range<Int> conversions

public func closedRange(from range: Range<Int>) -> ClosedRange<Int>? {
    guard !range.isEmpty else {
        return nil
    }

    return range.lowerBound ... (range.upperBound - 1)
}

public func nsRange(from range: Range<Int>) -> NSRange {
    NSRange(
        location: range.lowerBound,
        length: range.count)
}

// MARK: - NSRange conversions

public func range(from nsRange: NSRange) -> Range<Int> {
    nsRange.location ..< (nsRange.location + nsRange.length)
}

public func closedRange(from nsRange: NSRange) -> ClosedRange<Int>? {
    guard nsRange.length > 0 else {
        return nil
    }

    return nsRange.location ... (nsRange.location + nsRange.length - 1)
}
