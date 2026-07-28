//
//  Enzyme.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/15/18.
//  Copyright © 2018 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

public let unspecifiedEnzyme = Enzyme(
    name: "Unspecified", cleaveAt: [], dontCleaveBefore: [], cleaveDirection: [],
    fullName: "", alternativeName: "")

public enum CleaveDirection: String, CaseIterable, Codable, Identifiable, Sendable {
    case after
    case before

    public var id: Self { self }
}

public struct Enzyme: Codable, Sendable {
    public let name: String
    public let cleaveAt: [String]
    public let dontCleaveBefore: [String]
    public let cleaveDirection: [CleaveDirection]
    public let fullName: String
    public let alternativeName: String

    public init(
        name: String, cleaveAt: [String], dontCleaveBefore: [String],
        cleaveDirection: [CleaveDirection], fullName: String, alternativeName: String
    ) {
        self.name = name
        self.cleaveAt = cleaveAt
        self.dontCleaveBefore = dontCleaveBefore
        self.cleaveDirection = cleaveDirection
        self.fullName = fullName
        self.alternativeName = alternativeName
    }
}

extension Enzyme {
    func cutRanges(in input: String) throws -> [Range<Int>] {
        guard !input.isEmpty else {
            return []
        }

        let tokens = cleaveAt.filter { !$0.isEmpty }

        guard !tokens.isEmpty else {
            return [0..<input.count]
        }

        // Prefer longer tokens when one token is a prefix of another.
        let alternation =
            tokens
            .sorted { $0.count > $1.count }
            .map(NSRegularExpression.escapedPattern(for:))
            .joined(separator: "|")

        let expression = try NSRegularExpression(
            pattern: "(?:\(alternation))"
        )

        let searchRange = NSRange(
            input.startIndex..<input.endIndex,
            in: input
        )

        var cutPositions: Set<Int> = [
            0,
            input.count,
        ]

        for match in expression.matches(
            in: input,
            range: searchRange
        ) {
            guard let matchRange = Range(match.range, in: input) else {
                continue
            }

            let matchStart = input.distance(
                from: input.startIndex,
                to: matchRange.lowerBound
            )

            let matchEnd = input.distance(
                from: input.startIndex,
                to: matchRange.upperBound
            )

            let followingText = input[matchRange.upperBound...]

            let afterCutIsBlocked =
                dontCleaveBefore
                .filter { !$0.isEmpty }
                .contains { followingText.hasPrefix($0) }

            if cleaveDirection.contains(.before) {
                cutPositions.insert(matchStart)
            }

            if cleaveDirection.contains(.after),
                !afterCutIsBlocked
            {
                cutPositions.insert(matchEnd)
            }
        }

        let positions = cutPositions.sorted()

        return zip(positions, positions.dropFirst())
            .compactMap { lowerBound, upperBound in
                guard lowerBound < upperBound else {
                    return nil
                }

                return lowerBound..<upperBound
            }
    }
}

extension Enzyme: Equatable, Hashable {
    public static func == (lhs: Enzyme, rhs: Enzyme) -> Bool { lhs.name == rhs.name }

    public func hash(into hasher: inout Hasher) { hasher.combine(name) }
}

/*
 Pepsin preferentially cleaves at Phe, Tyr, Trp and Leu in position P1 or P1'(Keil, 1992).
 Negative effects on cleavage are excerted by Arg, Lys and His in position P3 and Arg in position P1.
 Pro has favourable effects when being located in position P4 and position P3,
 but unfavourable ones when found in positions P2 to P3'.
 Cleavage is more specific at pH 1.3.
 Then pepsin preferentially cleaves at Phe and Leu in position P1 with negligible cleavage for all other amino acids in this position. This specificity is lost at pH >= 2.

 */
