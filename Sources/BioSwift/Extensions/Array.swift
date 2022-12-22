//
//  Extensions.swift
//  BioSwift
//
//  Created by Koen van der Drift on 12/22/16.
//  Copyright © 2016 Koen van der Drift. All rights reserved.
//

import Foundation

final class ThreadSafe<A> {
    // via: https://talk.objc.io/episodes/S01E90-concurrent-map
    private var _value: A
    private let queue = DispatchQueue(label: "ThreadSafe")
    init(_ value: A) {
        _value = value
    }

    var value: A {
        queue.sync { _value }
    }

    func atomically(_ transform: (inout A) -> Void) {
        queue.sync {
            transform(&self._value)
        }
    }
}

extension Array {
    // via: https://talk.objc.io/episodes/S01E90-concurrent-map
    public func concurrentMap<B>(_ transform: @escaping (Element) -> B) -> [B] {
        let result = ThreadSafe([B?](repeating: nil, count: count))

        DispatchQueue.concurrentPerform(iterations: count) { idx in
            let element = self[idx]
            let transformed = transform(element)
            result.atomically {
                $0[idx] = transformed
            }
        }

        return result.value.map { $0! }
    }

    // via: https://gist.github.com/robertmryan/1ca0deab3e3e53d54dccf421a5c64144
    /// Return combinations of the elements of the array (ignoring the order of items in those combinations).
    ///
    /// - Parameters:
    ///   - size: The size of the combinations to be returned.
    ///   - allowDuplicates: Boolean indicating whether an item in the array can be repeated in the combinations (e.g. is the sampled item returned to the original set or not).
    ///
    /// - Returns: A collection of resulting combinations.

    public func combinations(size: Int, allowDuplicates: Bool = false) -> [[Element]] {
        let n = count

        if n == 0 || (size > n && !allowDuplicates) { return [] }

        var combinations: [[Element]] = []

        var i = startIndex
        var indices = [startIndex]

        while true {
            // build out array of indices (if not complete)

            while indices.count < size {
                i = indices.last! + (allowDuplicates ? 0 : 1)
                if i < n {
                    indices.append(i)
                }
            }

            // add combination associated with this particular array of indices

            combinations.append(indices.map { self[$0] })

            // prepare next one (incrementing the last component and/or deleting as needed

            repeat {
                if indices.isEmpty { return combinations }
                i = indices.last! + 1
                indices.removeLast()
            } while i > n - (allowDuplicates ? 1 : (size - indices.count))
            indices.append(i)
        }
    }

    mutating func modifyForEach(_ body: (_ index: Index, _ element: inout Element) -> Void) {
        for index in indices {
            modifyElement(atIndex: index) { body(index, &$0) }
        }
    }

    mutating func modifyElement(atIndex index: Index, _ modifyElement: (_ element: inout Element) -> Void) {
        var element = self[index]
        modifyElement(&element)
        self[index] = element
    }
}

extension Array where Element: StringProtocol {
    func uniqueElements() -> [Element] {
        let elementSet = Set(self)
        let elementArray = Array(elementSet)

        return elementArray
    }
}

extension Collection {
    func count(where test: (Element) throws -> Bool) rethrows -> Int {
        try filter(test).count
    }
}

extension Collection where SubSequence == Self {
    // via: https://www.objc.io/blog/2019/02/05/a-scanner-alternative/

    @discardableResult mutating func scan(_ condition: (Element) -> Bool) -> Element? {
        guard let f = first, condition(f) else {
            return nil
        }

        return removeFirst()
    }

    @discardableResult mutating func scan(count: Int) -> Self? {
        let result = prefix(count)
        guard result.count == count else {
            return nil
        }

        removeFirst(count)

        return result
    }

    @discardableResult mutating func scan(until condition: (Element) -> Bool) -> Self? {
        guard let index = firstIndex(where: condition) else {
            return nil
        }

        let result = self[..<index]
        defer { self = self[index...] }

        return result
    }
}
