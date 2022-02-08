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
        return queue.sync { _value }
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
        return try filter(test).count
    }
}

// My generic implementation
extension RandomAccessCollection {
    /// Returns `self.map(transform)`, computed in parallel.
    ///
    /// - Requires: `transform` is safe to call from multiple threads.
    func concurrentMap2<B>(minBatchSize: Int = 4096, _ transform: (Element) -> B) -> [B] {
        precondition(minBatchSize >= 1)
        let n = self.count
        let batchCount = (n + minBatchSize - 1) / minBatchSize
        if batchCount < 2 { return self.map(transform) }
        
        return Array(unsafeUninitializedCapacity: n) {
            uninitializedMemory, resultCount in
            resultCount = n
            let baseAddress = uninitializedMemory.baseAddress!
            
            DispatchQueue.concurrentPerform(iterations: batchCount) { b in
                let startOffset = b * n / batchCount
                let endOffset = (b + 1) * n / batchCount
                var sourceIndex = index(self.startIndex, offsetBy: startOffset)
                for p in baseAddress+startOffset..<baseAddress+endOffset {
                    p.initialize(to: transform(self[sourceIndex]))
                    formIndex(after: &sourceIndex)
                }
            }
        }
    }
}

// This oughta be an optimization, but doesn't seem to be!
extension Array {
    /// Returns `self.map(transform)`, computed in parallel.
    ///
    /// - Requires: `transform` is safe to call from multiple threads.
    func concurrentMap3<B>(_ transform: (Element) -> B) -> [B] {
        withUnsafeBufferPointer { $0.concurrentMap2(transform) }
    }
}

// Implementation with no unsafe constructs.
extension RandomAccessCollection {
    /// Returns `self.map(transform)`, computed in parallel.
    ///
    /// - Requires: `transform` is safe to call from multiple threads.
    func concurrentMap4<B>(_ transform: (Element) -> B) -> [B] {
        let batchSize = 4096 // Tune this
        let n = self.count
        let batchCount = (n + batchSize - 1) / batchSize
        if batchCount < 2 { return self.map(transform) }

        var batches = ThreadSafe(
            ContiguousArray<[B]?>(repeating: nil, count: batchCount))

        func batchStart(_ b: Int) -> Index {
            index(startIndex, offsetBy: b * n / batchCount)
        }
        
        DispatchQueue.concurrentPerform(iterations: batchCount) { b in
            let batch = self[batchStart(b)..<batchStart(b + 1)].map(transform)
            batches.atomically { $0[b] = batch }
        }
        
        return batches.value.flatMap { $0! }
    }
}
