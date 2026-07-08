//
//  Array.swift
//  BioSwift
//
//  Created by Koen van der Drift on 12/22/16.
//  Copyright © 2016 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

public extension Array {
    func consecutiveGroups(ofSize size: Int) -> [[Element]] {
        guard size > 0, size <= count else {
            return []
        }

        return (0 ... (count - size)).map { startIndex in
            Array(self[startIndex ..< (startIndex + size)])
        }
    }
}

public extension Array where Element: Sendable {
    func concurrentMap<B: Sendable>(
        _ transform: @Sendable @escaping (Element) throws -> B) async throws -> [B]
    {
        try await withThrowingTaskGroup(of: (Int, B).self) { group in
            for (index, element) in self.enumerated() {
                group.addTask {
                    try (index, transform(element))
                }
            }

            var results = [B?](repeating: nil, count: count)

            for try await (index, value) in group {
                results[index] = value
            }

            return results.map { $0! }
        }
    }
}

extension Array where Element: Chain {
    func combinedConsecutiveChains(ofSize size: Int) -> [Element] {
        consecutiveGroups(ofSize: size).map { chainGroup in
            let combinedAminoAcids = chainGroup.flatMap { $0.residues }

            let combinedRange: ChainRange =
                chainGroup.first!.chainRange.lowerBound ...
                chainGroup.last!.chainRange.upperBound

            var newChain = Element(residues: combinedAminoAcids)
            newChain.chainRange = combinedRange
            newChain.parentLength = chainGroup.first!.parentLength

            return newChain
        }
    }
}

extension Array where Element: StringProtocol {
    func uniqueElements() -> [Element] {
        let elementSet = Set(self)
        return Array(elementSet)
    }
}

/*
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
 */
