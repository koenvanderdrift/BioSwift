//
//  Array.swift
//  BioSwift
//
//  Created by Koen van der Drift on 12/22/16.
//  Copyright © 2016 - 2026 Koen van der Drift. All rights reserved.
//

import Foundation

extension Array {
    public func consecutiveGroups(ofSize size: Int) -> [[Element]] {
        guard size > 0, size <= count else {
            return []
        }

        return (0...(count - size)).map { startIndex in
            Array(self[startIndex..<(startIndex + size)])
        }
    }
}

extension Array where Element: Sendable {
    public func concurrentMap<B: Sendable>(_ transform: @Sendable @escaping (Element) throws -> B)
        async throws -> [B]
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

            return results.map {
                $0!
            }
        }
    }
}
