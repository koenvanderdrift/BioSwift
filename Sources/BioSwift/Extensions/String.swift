//
//  String.swift
//  BioSwift
//
//  Created by Koen van der Drift on 12/22/16.
//  Copyright © 2016 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

public let zeroStringRange: Range<String.Index> = String().startIndex ..< String().endIndex

public extension String {
    func matches(for regex: String) -> [NSTextCheckingResult] {
        // https://www.raywenderlich.com/86205/nsregularexpression-swift-tutorial

        let string = self as NSString

        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            return regex.matches(in: self, range: NSMakeRange(0, string.length))

        } catch let error as NSError {
            debugPrint("invalid regex: \(error.localizedDescription)")
            return []
        }
    }

    func ranges(of substring: String, options: CompareOptions = [], locale: Locale? = nil) -> [Range<Index>] {
        var ranges: [Range<Index>] = []
        while let range = range(of: substring, options: options, range: (ranges.last?.upperBound ?? startIndex) ..< endIndex, locale: locale) {
            ranges.append(range)
        }
        return ranges
    }

    func nsRanges(of substring: String, options: CompareOptions = [], locale: Locale? = nil) -> [NSRange] {
        var nsRanges: [NSRange] = []

        for range in ranges(of: substring, options: options, locale: locale) {
            nsRanges.append(NSRange(range, in: self))
        }

        return nsRanges
    }

    func sequenceRanges(of substring: String, options: CompareOptions = [], locale: Locale? = nil) -> [ChainRange] {
        var sequenceRanges: [ChainRange] = []

        for range in nsRanges(of: substring, options: options, locale: locale) {
            sequenceRanges.append(range.toChainRange())
        }

        return sequenceRanges
    }

    internal func containsCharactersFrom(substring: String) -> Bool {
        let set = CharacterSet(charactersIn: substring)

        return rangeOfCharacter(from: set) != nil
    }
}

extension StringProtocol {
    subscript(offset: Int) -> Element {
        self[index(startIndex, offsetBy: offset)]
    }

    subscript(_ range: Range<Int>) -> SubSequence {
        prefix(range.lowerBound + range.count)
            .suffix(range.count)
    }

    subscript(range: ChainRange) -> SubSequence {
        prefix(range.lowerBound + range.count)
            .suffix(range.count)
    }

    subscript(range: PartialRangeThrough<Int>) -> SubSequence {
        prefix(range.upperBound.advanced(by: 1))
    }

    subscript(range: PartialRangeUpTo<Int>) -> SubSequence {
        prefix(range.upperBound)
    }

    subscript(range: PartialRangeFrom<Int>) -> SubSequence {
        suffix(Swift.max(0, count - range.lowerBound))
    }
}

public extension String {
    func substring(
        in chainRange: ChainRange
    ) -> String {
        let validRange = chainRange.clamped(
            toSequenceLength: count
        )

        guard validRange.isValidChainRange else {
            return ""
        }

        let start = index(
            startIndex,
            offsetBy: validRange.lowerBound - 1
        )

        let end = index(
            start,
            offsetBy: validRange.length
        )

        return String(self[start ..< end])
    }

    func removing(
        chainRange: ChainRange
    ) -> String {
        let validRange = chainRange.clamped(
            toSequenceLength: count
        )

        guard validRange.isValidChainRange else {
            return self
        }

        var result = self

        let start = result.index(
            result.startIndex,
            offsetBy: validRange.lowerBound - 1
        )

        let end = result.index(
            start,
            offsetBy: validRange.length
        )

        result.removeSubrange(start ..< end)

        return result
    }
}
