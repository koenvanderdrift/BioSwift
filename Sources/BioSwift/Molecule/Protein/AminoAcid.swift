//
//  AminoAcid.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/18/21.
//  Copyright © 2021 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

public enum AminoAcidProperty: String, CaseIterable, Codable, Sendable, Identifiable {
    case polar
    case nonpolar
    case hydrophobic
    case small
    case tiny
    case aromatic
    case aliphatic
    case negative
    case positive
    case uncharged
    case chargedPositive
    case chargedNegative

    public var id: Self { self }

    public var displayName: String {
        rawValue.capitalized
    }
}

/// AminoAcid conforms to the ``Residue`` protocol

public struct AminoAcid: Residue, Codable, Sendable {
    public let formula: Formula
    public let name: String
    public let oneLetterCode: String
    public let threeLetterCode: String
    public let represents: [String]
    public let representedBy: [String]

    public var properties: Set<AminoAcidProperty>
    public var modification: Modification?

    public var adducts: [Adduct]

    public var chemicalString: String {
        formula.chemicalString
    }

    public init(name: String, oneLetterCode: String, threeLetterCode: String = "", formula: Formula, represents: [String] = [], representedBy: [String] = []) {
        self.name = name
        self.oneLetterCode = oneLetterCode
        self.threeLetterCode = threeLetterCode
        self.formula = formula
        self.represents = represents
        self.representedBy = representedBy
        self.adducts = []
        self.properties = []

        setProperties()
    }

    public init(name: String, oneLetterCode: String, threeLetterCode: String = "", elements: [String: Int]) {
        self.init(name: name, oneLetterCode: oneLetterCode, threeLetterCode: threeLetterCode, formula: Formula(from: elements))

        setProperties()
    }

    private mutating func setProperties() {
        switch oneLetterCode {
        case "A", "G", "L", "V", "M", "I":
            properties = [.small, .aliphatic, .hydrophobic]
        case "S", "T", "C", "P", "N", "Q":
            properties = [.polar, .uncharged]
        case "K", "R", "H":
            properties = [.polar, .chargedPositive]
        case "E", "D":
            properties = [.polar, .chargedNegative]
        case "F", "Y", "W":
            properties = [.nonpolar, .aromatic]
        default:
            break
        }
    }

    public func allowedModifications() -> [Modification] {
        modificationLibrary.filter { mod in
            mod.specificities.contains { spec in
                spec.site == identifier
            }
        }
    }
}
