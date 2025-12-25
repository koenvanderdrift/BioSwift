//
//  Enzyme.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/15/18.
//  Copyright © 2018 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

// enum CleaveDirection {
//    case C
//    case N
// }

public class Enzyme: Codable {
    public let name: String
    public let cleaveAt: [String]
    public let dontCleaveBefore: [String]
    public let cleaveDirection: String
    public let fullName: String
    public let alternativeName: String
}

public extension Enzyme {
    func regex() -> String {
        var regex = ""

        if cleaveDirection == "C" {
            regex = String(format: "(?<=[%@])", cleaveAt)

            if !dontCleaveBefore.isEmpty {
                regex = regex + String(format: "(?=[^%@])", dontCleaveBefore)
            }
        } else if cleaveDirection == "N" {
            regex = String(format: "(?=[%@])", cleaveAt)
        }

        return regex
    }
}
