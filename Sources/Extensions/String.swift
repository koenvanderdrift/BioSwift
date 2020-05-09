//
//  Extensions.swift
//  BioSwift
//
//  Created by Koen van der Drift on 12/22/16.
//  Copyright © 2016 Koen van der Drift. All rights reserved.
//

import Foundation

public let zeroStringRange: Range<String.Index> = String().startIndex ..< String().endIndex

extension String {
    // via: https://gist.github.com/robertmryan/1ca0deab3e3e53d54dccf421a5c64144
    func uniqueSubStrings(size: Int, allowDuplicates: Bool = false) -> [String] {
        return map { $0 }
            .combinations(size: size, allowDuplicates: allowDuplicates)
            .map { String($0.sorted()) }
            .uniqueElements()
    }

    func sequencialSubStrings(size: Int) -> [String] {
        var subStrings = [String]()

        for i in 0 ..< count {
            if size + i < count {
                let lowerBound = index(startIndex, offsetBy: i)
                let upperBound = index(startIndex, offsetBy: size + i)

                subStrings.append(String(self[lowerBound ..< upperBound]))
            }
        }

        return subStrings
    }

    public func matches(for regex: String) -> [NSTextCheckingResult] {
        // https://www.raywenderlich.com/86205/nsregularexpression-swift-tutorial

        let string = self as NSString

        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let results = regex.matches(in: self, range: NSRange(location: 0, length: string.length))

            return results

        } catch let error as NSError {
            debugPrint("invalid regex: \(error.localizedDescription)")
            return []
        }
    }

    public func ranges(of substring: String, options: CompareOptions = [], locale: Locale? = nil) -> [Range<Index>] {
        var ranges: [Range<Index>] = []
        while let range = self.range(of: substring, options: options, range: (ranges.last?.upperBound ?? startIndex) ..< endIndex, locale: locale) {
            ranges.append(range)
        }
        return ranges
    }

    public func nsRanges(of substring: String, options: CompareOptions = [], locale: Locale? = nil) -> [NSRange] {
        var nsRanges: [NSRange] = []
        
        for range in ranges(of: substring, options: options, locale: locale) {
            nsRanges.append(NSRange(range, in: self))
        }
        
        return nsRanges
    }

    func containsCharactersFrom(substring: String) -> Bool {
        let set = CharacterSet(charactersIn: substring)

        return (rangeOfCharacter(from: set) != nil)
    }

    func substring(from: Int, to: Int) -> Substring? {
        guard from <= to else { return nil }
        let nsrange = NSRange(location: from, length: to - from)

        return substring(with: nsrange)
    }

    public func substring(with sequenceRange: SequenceRange) -> Substring? {
        guard let nsrange = range(from: sequenceRange),
        let r = range(from: nsrange)
            else { return nil }

        return self[r]
    }

    public func substring(with nsrange: NSRange) -> Substring? {
        guard let range = range(from: nsrange) else { return nil }

        return self[range]
    }

    public func range(from sequenceRange: SequenceRange) -> NSRange? {
        return NSMakeRange(sequenceRange.lowerBound, sequenceRange.upperBound - sequenceRange.lowerBound + 1)
    }

    public func range(from nsrange: NSRange) -> Range<Index>? {
        return Range(nsrange, in: self)
    }

//    func indices(of string: String, options: CompareOptions = .literal) -> [Index] {
//        var result = [Index]()
//        var start = self.startIndex
//
//        while let range = range(of: string, options: options, range: start ..< endIndex) {
//            result.append(range.lowerBound)
//
//            start = range.upperBound
//        }
//
//        return result
//    }

//    func locations(of string: String) -> [Int] {
//        var result = [Int]()
//        var start = self.startIndex
//
//        while start < self.endIndex, let range = self.range(of: string, range: start..<self.endIndex), !range.isEmpty {
//            let location = distance(from: self.startIndex, to: range.lowerBound)
//            result.append(location)
//
//            start = range.upperBound
//        }
//
//        return result
//    }
}

extension StringProtocol {
    subscript(offset: Int) -> Element {
        return self[index(startIndex, offsetBy: offset)]
    }

    subscript(_ range: Range<Int>) -> SubSequence {
        return prefix(range.lowerBound + range.count)
            .suffix(range.count)
    }

    subscript(range: ClosedRange<Int>) -> SubSequence {
        return prefix(range.lowerBound + range.count)
            .suffix(range.count)
    }

    subscript(range: PartialRangeThrough<Int>) -> SubSequence {
        return prefix(range.upperBound.advanced(by: 1))
    }

    subscript(range: PartialRangeUpTo<Int>) -> SubSequence {
        return prefix(range.upperBound)
    }

    subscript(range: PartialRangeFrom<Int>) -> SubSequence {
        return suffix(Swift.max(0, count - range.lowerBound))
    }
}

/*
 let string = "Hello, world!"

 let secondIndex = string.index(after: string.startIndex)
 let thirdIndex = string.index(string.startIndex, offsetBy: 2)
 let lastIndex = string.index(before: string.endIndex)

 print(string[secondIndex]) // e
 print(string[thirdIndex]) // l
 print(string[lastIndex]) // !

 let range = secondIndex..<lastIndex
 let substring = string[range]
 print(substring) // ello, world

 */

//    func substring(with nsrange: NSRange) -> Substring? {
//        guard nsrange.location != NSNotFound else { return nil }
//
//        return substring(from: nsrange.location, to: nsrange.location + nsrange.length - 1)
//    }
//    func indices(of string: String) -> [Int] {
//        return indices.reduce([]) { $1.encodedOffset > ($0.last ?? -1) && self[$1...].hasPrefix(string) ? $0 + [$1.encodedOffset] : $0 }
//    }
//
//    func stringAtIndex(_ index: Int) -> Substring? {
//        return subString(from: index, to: index)
//    }
//
//    public subscript(_ range: NSRange) -> Substring {
//        let start = index(startIndex, offsetBy: range.lowerBound)
//        let end = index(startIndex, offsetBy: range.upperBound)
//        let subString = self[start ..< end]
//        // debugPrint(subString)
//        return subString
//    }

/// Returns a range equivalent to the given `NSRange`,
/// or `nil` if the range can't be converted.
//    func range(from nsrange: NSRange) -> Range<Index>? {
//        guard let range = Range.init(nsrange) else { return nil }
//        let utf16Start = UTF16Index(range.lowerBound)
//        let utf16End = UTF16Index(range.upperBound)
//
//        guard let start = Index(utf16Start, within: self),
//            let end = Index(utf16End, within: self)
//            else { return nil }
//
//        return start..<end
//    }

// extension NSRange {
//    init(_ range: Range<String.Index>, in string: String) {
//        self.init()
//        let startIndex = range.lowerBound.samePosition(in: string.utf16)
//        let endIndex = range.upperBound.samePosition(in: string.utf16)
//        self.location = string.distance(from: string.startIndex,
//                                        to: range.lowerBound)
//        self.length = startIndex.distance(to: endIndex)
//    }
// }

//    func indices(of occurrence: String) -> [Int] {
//        var indices = [Int]()
//        var position = startIndex
//        while let range = range(of: occurrence, range: position..<endIndex) {
//            let i = distance(from: startIndex,
//                             to: range.lowerBound)
//            indices.append(i)
//            let offset = occurrence.distance(from: occurrence.startIndex,
//                                             to: occurrence.endIndex) - 1
//            guard let after = index(range.lowerBound,
//                                    offsetBy: offset,
//                                    limitedBy: endIndex) else {
//                                        break
//            }
//            position = index(after: after)
//        }
//        return indices
//    }

//   func ranges(of searchString: String) -> [Range<String.Index>] {
//        let _indices = indices(of: searchString)
//        let count = searchString.count
//        return _indices.map({ index(startIndex, offsetBy: $0)..<index(startIndex, offsetBy: $0+count) })
//    }
