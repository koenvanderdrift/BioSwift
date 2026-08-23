//
//  Enzyme.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/15/18.
//  Copyright © 2018 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

public let unspecifiedEnzyme = Enzyme(
    name: "Unspecified", fullName: "", alternativeName: "", cleaveAt: [],
    cleaveDirections: [], cleaveRestrictions: [])

public enum CleaveDirection: String, CaseIterable, Codable, Identifiable, Sendable {
    case after
    case before

    public var id: Self {
        self
    }
}

public struct CleaveRestriction: Codable, Sendable {
    public let characters: String
    public let position: Int

    public init(characters: String, position: Int) {
        precondition(!characters.isEmpty)
        precondition(position != 0)

        self.characters = characters
        self.position = position
    }

    private enum CodingKeys: String, CodingKey {
        case characters
        case position
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        let characters = try container.decode(
            String.self,
            forKey: .characters
        )

        // N-terminal direction (left of the cut): P1, P2, P3, P4
        // C-terminal direction (right of the cut): P1', P2', P3', P41

        let position = try container.decode(
            Int.self,
            forKey: .position
        )

        guard !characters.isEmpty else {
            throw DecodingError.dataCorruptedError(
                forKey: .characters,
                in: container,
                debugDescription: "characters must not be empty"
            )
        }

        guard position != 0 else {
            throw DecodingError.dataCorruptedError(
                forKey: .position,
                in: container,
                debugDescription: "position 0 is the cut boundary"
            )
        }

        self.characters = characters
        self.position = position
    }
}

public struct Enzyme: Codable, Sendable {
    public let name: String
    public let fullName: String
    public let alternativeName: String
    public let cleaveAt: [String]  // The actual split happens right between P1 and P1'
    public let cleaveDirections: [CleaveDirection]
    public let cleaveRestrictions: [CleaveRestriction]

    public init(
        name: String, fullName: String, alternativeName: String, cleaveAt: [String],
        cleaveDirections: [CleaveDirection], cleaveRestrictions: [CleaveRestriction]
    ) {
        self.name = name
        self.fullName = fullName
        self.alternativeName = alternativeName
        self.cleaveAt = cleaveAt
        self.cleaveDirections = cleaveDirections
        self.cleaveRestrictions = cleaveRestrictions
    }
}

extension Enzyme: Equatable, Hashable {
    public static func == (lhs: Enzyme, rhs: Enzyme) -> Bool {
        lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

/*
 Pepsin preferentially cleaves at Phe, Tyr, Trp and Leu in position P1 or P1'(Keil, 1992).
 Negative effects on cleavage are excerted by Arg, Lys and His in position P3 and Arg in position P1.
 Pro has favourable effects when being located in position P4 and position P3,
 but unfavourable ones when found in positions P2 to P3'.

 Cleavage is more specific at pH 1.3.
 Then pepsin preferentially cleaves at Phe and Leu in position P1 with negligible cleavage for all other amino acids in this position. This specificity is lost at pH >= 2.

 {
     "name": "Pepsin (pH = 1.3)",
     "fullName": "",
     "alternativeName": "",
     "cleaveAt": [
         "F",
         "L"
     ],
     "cleaveDirections": [
         "before"
     ],
     "cleaveRestrictions": [],
 },
 {
     "name": "Pepsin (pH > 2)",
     "fullName": "",
     "alternativeName": "",
     "cleaveAt": [
         "F",
         "L",
         "Y",
         "W"
     ],
     "cleaveDirections": [
         "after",
         "before"
     ],
     "cleaveRestrictions": [
         {
             "characters": "R",
             "position": -1
         },
         {
             "characters": "RKH",
             "position": -3
         },
         {
             "characters": "P",
             "position": -2
         },
         {
             "characters": "P",
             "position": -1
         },
         {
             "characters": "P",
             "position": 1
         },
         {
             "characters": "P",
             "position": 2
         },
         {
             "characters": "P",
             "position": 3
         }
     ]
 } */

extension Enzyme {
    func regex() -> String {
        let cleaveCharacters = escapedCharacterClass(
            cleaveAt.joined()
        )

        guard !cleaveCharacters.isEmpty else {
            return ""
        }

        let cleaveClass = "[\(cleaveCharacters)]"

        let cutSite: String

        switch (
            cleaveDirections.contains(.before),
            cleaveDirections.contains(.after)
        ) {
        case (true, true):
            cutSite = "(?:(?=\(cleaveClass))|(?<=\(cleaveClass)))"

        case (true, false):
            cutSite = "(?=\(cleaveClass))"

        case (false, true):
            cutSite = "(?<=\(cleaveClass))"

        case (false, false):
            return ""
        }

        let restrictions =
            cleaveRestrictions
            .filter {
                $0.position != 0
            }
            .map(restrictionRegex)
            .joined()

        return cutSite + restrictions
    }

    private func restrictionRegex(
        _ restriction: CleaveRestriction
    ) -> String {
        let characters = escapedCharacterClass(
            restriction.characters
        )

        guard !characters.isEmpty else {
            return ""
        }

        let characterClass = "[\(characters)]"
        let distance = abs(restriction.position) - 1

        let wildcard =
            distance == 0
            ? ""
            : ".{\(distance)}"

        if restriction.position > 0 {
            // Character is after the cut boundary.
            return "(?!\(wildcard)\(characterClass))"
        } else {
            // Character is before the cut boundary.
            return "(?<!\(characterClass)\(wildcard))"
        }
    }

    private func escapedCharacterClass(
        _ value: String
    ) -> String {
        var seen: Set<Character> = []

        return value.compactMap { character in
            guard seen.insert(character).inserted else {
                return nil
            }

            switch character {
            case "\\", "]", "[", "^", "-":
                return "\\\(character)"
            default:
                return String(character)
            }
        }
        .joined()
    }

    private func characterClass(_ values: [String]) -> String {
        values
            .joined()
            .map { character in
                switch character {
                case "\\", "]", "^", "-":
                    return "\\\(character)"
                default:
                    return String(character)
                }
            }
            .joined()
    }
}

