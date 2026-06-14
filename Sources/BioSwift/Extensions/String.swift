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
    // MARK: - Regular expressions

    /// Returns all matches for a regular expression pattern.
    ///
    /// Throws when the supplied pattern is invalid.
    func matches(for pattern: String) throws -> [NSTextCheckingResult] {
        let expression = try NSRegularExpression(pattern: pattern)

        return expression.matches(
            in: self,
            range: NSRange(startIndex ..< endIndex, in: self)
        )
    }

    /// Returns all matches for an already compiled regular expression.
    ///
    /// Prefer this overload when the same expression is used repeatedly.
    func matches(
        for expression: NSRegularExpression,
        options: NSRegularExpression.MatchingOptions = []
    ) -> [NSTextCheckingResult] {
        expression.matches(
            in: self,
            options: options,
            range: NSRange(startIndex ..< endIndex, in: self)
        )
    }

    /// Returns the substring between the first occurrence of `startMarker`
    /// and the subsequent occurrence of `endMarker`.
    func substring(
        between startMarker: String,
        and endMarker: String,
        startingAt searchStart: Index? = nil
    ) -> Substring? {
        guard !startMarker.isEmpty, !endMarker.isEmpty else {
            return nil
        }

        let startIndex = searchStart ?? self.startIndex

        guard let openingRange = range(
            of: startMarker,
            range: startIndex ..< endIndex
        ) else {
            return nil
        }

        guard let closingRange = range(
            of: endMarker,
            range: openingRange.upperBound ..< endIndex
        ) else {
            return nil
        }

        return self[openingRange.upperBound ..< closingRange.lowerBound]
    }

    /// Returns all non-overlapping substrings located between matching markers.
    func substrings(
        between startMarker: String,
        and endMarker: String
    ) -> [Substring] {
        guard !startMarker.isEmpty, !endMarker.isEmpty else {
            return []
        }

        var results: [Substring] = []
        var searchStart = startIndex

        while let openingRange = range(
            of: startMarker,
            range: searchStart ..< endIndex
        ),
            let closingRange = range(
                of: endMarker,
                range: openingRange.upperBound ..< endIndex
            )
        {
            results.append(self[openingRange.upperBound ..< closingRange.lowerBound])
            searchStart = closingRange.upperBound
        }

        return results
    }

    // MARK: - Substring ranges

    /// Returns all ranges of `substring` in the string.
    ///
    /// - Parameters:
    ///   - substring: Text to locate. An empty substring returns an empty array.
    ///   - options: String comparison options.
    ///   - locale: Locale used for comparison, when applicable.
    ///   - allowingOverlaps: When true, matches may overlap.
    func ranges(
        of substring: String,
        options: CompareOptions = [],
        locale: Locale? = nil,
        allowingOverlaps: Bool = false
    ) -> [Range<Index>] {
        guard !substring.isEmpty else {
            return []
        }

        precondition(
            !options.contains(.backwards),
            "ranges(of:) searches forward and does not support .backwards."
        )

        var results: [Range<Index>] = []
        var searchRange = startIndex ..< endIndex

        while let foundRange = range(
            of: substring,
            options: options,
            range: searchRange,
            locale: locale
        ) {
            results.append(foundRange)

            let nextStart: Index

            if allowingOverlaps {
                nextStart = index(after: foundRange.lowerBound)
            } else {
                nextStart = foundRange.upperBound
            }

            guard nextStart < endIndex else {
                break
            }

            searchRange = nextStart ..< endIndex
        }

        return results
    }

    /// Returns matching substring ranges using one-based residue coordinates.
    ///
    /// Intended for canonical protein sequence strings, where each Character
    /// corresponds to exactly one residue.
    func sequenceRanges(
        of substring: String,
        options: CompareOptions = [],
        locale: Locale? = nil,
        allowingOverlaps: Bool = false
    ) -> [ChainRange] {
        ranges(
            of: substring,
            options: options,
            locale: locale,
            allowingOverlaps: allowingOverlaps
        )
        .map { range in
            let lowerBound = distance(from: startIndex, to: range.lowerBound) + 1
            let upperBound = distance(from: startIndex, to: range.upperBound)

            return lowerBound ... upperBound
        }
    }

    // MARK: - Character membership

    /// Returns true when the string contains at least one character
    /// belonging to the supplied character set.
    func containsAnyCharacter(in characterSet: CharacterSet) -> Bool {
        rangeOfCharacter(from: characterSet) != nil
    }

    /// Returns true when the string contains at least one character
    /// appearing in `characters`.
    func containsAnyCharacter(in characters: String) -> Bool {
        containsAnyCharacter(in: CharacterSet(charactersIn: characters))
    }

    func containsCharacterOutside(_ allowedCharacters: CharacterSet) -> Bool {
        rangeOfCharacter(from: allowedCharacters.inverted) != nil
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

public extension StringProtocol {
    /*
     // Text-file parsing only: zero-based character offsets
     extension StringProtocol {
         subscript(_ offset: Int) -> Element { ... }
         subscript(_ range: Range<Int>) -> SubSequence { ... }
         subscript(_ range: ClosedRange<Int>) -> SubSequence { ... }
         subscript(_ range: PartialRangeThrough<Int>) -> SubSequence { ... }
         subscript(_ range: PartialRangeUpTo<Int>) -> SubSequence { ... }
         subscript(_ range: PartialRangeFrom<Int>) -> SubSequence { ... }
     }
     */

    /// Returns the character at a zero-based character offset.
    subscript(_ offset: Int) -> Element {
        self[index(at: offset, allowingEndIndex: false)]
    }

    /// Returns a substring using zero-based, upper-bound-exclusive
    /// character offsets.
    subscript(_ range: Range<Int>) -> SubSequence {
        let lower = index(at: range.lowerBound)
        let upper = index(at: range.upperBound)

        return self[lower ..< upper]
    }

    /// Returns a substring using zero-based, upper-bound-inclusive
    /// character offsets.
    subscript(_ range: ClosedRange<Int>) -> SubSequence {
        precondition(
            range.upperBound < Int.max,
            "Upper bound is too large."
        )

        return self[range.lowerBound ..< (range.upperBound + 1)]
    }

    /// Returns a substring through a zero-based character offset, inclusively.
    subscript(_ range: PartialRangeThrough<Int>) -> SubSequence {
        precondition(
            range.upperBound < Int.max,
            "Upper bound is too large."
        )

        return self[0 ..< (range.upperBound + 1)]
    }

    /// Returns a substring up to, but excluding, a zero-based character offset.
    subscript(_ range: PartialRangeUpTo<Int>) -> SubSequence {
        self[0 ..< range.upperBound]
    }

    /// Returns a substring beginning at a zero-based character offset.
    subscript(_ range: PartialRangeFrom<Int>) -> SubSequence {
        let lower = index(at: range.lowerBound)

        return self[lower ..< endIndex]
    }

    private func index(
        at offset: Int,
        allowingEndIndex: Bool = true
    ) -> Index {
        precondition(
            offset >= 0,
            "String offset cannot be negative."
        )

        guard let result = index(
            startIndex,
            offsetBy: offset,
            limitedBy: endIndex
        ),
            allowingEndIndex || result != endIndex
        else {
            preconditionFailure(
                "String offset \(offset) is outside the valid bounds."
            )
        }

        return result
    }
}

extension Substring {
    @discardableResult
    mutating func scanUntil(_ character: Character) -> Substring? {
        guard let index = firstIndex(of: character) else {
            return nil
        }

        let result = self[..<index]
        self = self[index...]

        return result
    }

    @discardableResult
    mutating func scanThrough(_ character: Character) -> Character? {
        guard first == character else {
            return nil
        }

        return removeFirst()
    }

    @discardableResult
    mutating func skip(_ count: Int) -> Substring? {
        guard self.count >= count else {
            return nil
        }

        let skipped = prefix(count)
        removeFirst(count)

        return skipped
    }

    @discardableResult
    mutating func skipThrough(_ delimiter: Character) -> Bool {
        guard let index = firstIndex(of: delimiter) else {
            return false
        }

        self = self[self.index(after: index)...]

        return true
    }
}
