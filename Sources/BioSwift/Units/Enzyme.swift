//
//  Enzyme.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/15/18.
//  Copyright © 2018 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

public let unspecifiedEnzyme = Enzyme(name: "Unspecified", cleaveAt: [], dontCleaveBefore: [], cleaveDirection: .unspecified, fullName: "", alternativeName: "")

public enum CleaveDirection: String, CaseIterable, Codable {
    case C
    case N
    case unspecified
}

public class Enzyme: Codable {
    public let name: String
    public let cleaveAt: [String]
    public let dontCleaveBefore: [String]
    public let cleaveDirection: CleaveDirection
    public let fullName: String
    public let alternativeName: String

    public init(name: String, cleaveAt: [String], dontCleaveBefore: [String], cleaveDirection: CleaveDirection, fullName: String, alternativeName: String) {
        self.name = name
        self.cleaveAt = cleaveAt
        self.dontCleaveBefore = dontCleaveBefore
        self.cleaveDirection = cleaveDirection
        self.fullName = fullName
        self.alternativeName = alternativeName
    }
}

public extension Enzyme {
    func regex() -> String {
        var regex = ""

        if cleaveDirection == .C {
            regex = String(format: "(?<=[%@])", cleaveAt)

            if !dontCleaveBefore.isEmpty {
                regex = regex + String(format: "(?=[^%@])", dontCleaveBefore)
            }
        } else if cleaveDirection == .N {
            regex = String(format: "(?=[%@])", cleaveAt)
        }

        return regex
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
