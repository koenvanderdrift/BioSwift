import Foundation

public var aminoAcidLibrary: [AminoAcid] = loadJSONFromBundle(fileName: "aminoacids")

public struct AminoAcid: Residue, Codable {
    public let formula: Formula
    public let name: String
    public let oneLetterCode: String
    public let threeLetterCode: String
    public let represents: [String]
    public let representedBy: [String]

    public var modifications: [Modification] = []

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
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        represents = try container.decode([String].self, forKey: .represents)
        representedBy = try container.decode([String].self, forKey: .representedBy)
        oneLetterCode = try container.decode(String.self, forKey: .oneLetterCode)
        threeLetterCode = try container.decode(String.self, forKey: .threeLetterCode)
        formula = Formula(stringValue: try container.decode(String.self, forKey: .formula))
        name = try container.decode(String.self, forKey: .name)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(formula.stringValue, forKey: .formula)
        try container.encode(oneLetterCode, forKey: .oneLetterCode)
        try container.encode(threeLetterCode, forKey: .threeLetterCode)
        try container.encode(represents, forKey: .represents)
        try container.encode(representedBy, forKey: .representedBy)
    }
    
    var description: String {
        return threeLetterCode
    }
}

extension AminoAcid: Hashable {
    public static func == (lhs: AminoAcid, rhs: AminoAcid) -> Bool {
        return lhs.threeLetterCode == rhs.threeLetterCode
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(threeLetterCode)
    }
}

extension AminoAcid: Mass {
    public var masses: MassContainer {
        return calculateMasses()
    }
}
