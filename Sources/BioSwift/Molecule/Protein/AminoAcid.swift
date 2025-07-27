//
//  AminoAcid.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/18/21.
//  Copyright © 2021 - 2024 Koen van der Drift. All rights reserved.
//

import Foundation

public struct AminoAcidProperties: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let polar = AminoAcidProperties(rawValue: 1 << 0)
    public static let nonpolar = AminoAcidProperties(rawValue: 1 << 1)
    public static let hydrophobic = AminoAcidProperties(rawValue: 1 << 2)
    public static let small = AminoAcidProperties(rawValue: 1 << 3)
    public static let tiny = AminoAcidProperties(rawValue: 1 << 4)
    public static let aromatic = AminoAcidProperties(rawValue: 1 << 5)
    public static let aliphatic = AminoAcidProperties(rawValue: 1 << 6)
    public static let negative = AminoAcidProperties(rawValue: 1 << 7)
    public static let positive = AminoAcidProperties(rawValue: 1 << 8)
    public static let uncharged = AminoAcidProperties(rawValue: 1 << 9)
    public static let chargedPos = AminoAcidProperties(rawValue: 1 << 10)
    public static let chargedNeg = AminoAcidProperties(rawValue: 1 << 11)
}

public struct AminoAcid: Residue, Codable {
    public let formula: Formula
    public let name: String
    public let oneLetterCode: String
    public let threeLetterCode: String
    public let represents: [String]
    public let representedBy: [String]

    public var properties: [AminoAcidProperties] = []
    public var modification: Modification?

    public var adducts: [Adduct]

    private enum CodingKeys: String, CodingKey {
        case name
        case oneLetterCode
        case threeLetterCode
        case formula
        case represents
        case representedBy
    }

    public init(name: String, oneLetterCode: String, threeLetterCode: String = "", formula: Formula, represents: [String] = [], representedBy: [String] = []) {
        self.name = name
        self.oneLetterCode = oneLetterCode
        self.threeLetterCode = threeLetterCode
        self.formula = formula
        self.represents = represents
        self.representedBy = representedBy
        adducts = []

        setProperties()
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        represents = try container.decode([String].self, forKey: .represents)
        representedBy = try container.decode([String].self, forKey: .representedBy)
        oneLetterCode = try container.decode(String.self, forKey: .oneLetterCode)
        threeLetterCode = try container.decode(String.self, forKey: .threeLetterCode)
        formula = Formula(try container.decode(String.self, forKey: .formula))
        name = try container.decode(String.self, forKey: .name)
        adducts = []

        setProperties()
    }

    public init(name: String, oneLetterCode: String, threeLetterCode: String = "", elements: [String: Int]) {
        self.init(name: name, oneLetterCode: oneLetterCode, threeLetterCode: threeLetterCode, formula: Formula(elements))

        setProperties()
    }

    private mutating func setProperties() {
        switch oneLetterCode {
        case "A", "G", "L", "V", "M", "I":
            properties += [.small, .aliphatic, .hydrophobic]
        case "S", "T", "C", "P", "N", "Q":
            properties += [.polar, .uncharged]
        case "K", "R", "H":
            properties += [.polar, .chargedPos]
        case "E", "D":
            properties += [.polar, .chargedNeg]
        case "F", "Y", "W":
            properties += [.nonpolar, .aromatic]
        default:
            break
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(formula.formulaString, forKey: .formula)
        try container.encode(oneLetterCode, forKey: .oneLetterCode)
        try container.encode(threeLetterCode, forKey: .threeLetterCode)
        try container.encode(represents, forKey: .represents)
        try container.encode(representedBy, forKey: .representedBy)
    }

    public func allowedModifications() -> [Modification] {
        modificationLibrary.filter { mod in
            mod.specificities.contains { spec in
                spec.site == identifier
            }
        }
    }
}
