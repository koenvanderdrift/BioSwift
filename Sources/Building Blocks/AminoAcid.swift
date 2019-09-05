import Foundation

public var aminoAcidLibrary: [AminoAcid] = loadJSONFromBundle(fileName: "aminoacids")

public class AminoAcid: Molecule, Codable {
    public let oneLetterCode: String
    public let threeLetterCode: String
    public let represents: [String]
    public let representedBy: [String]

    private enum CodingKeys: String, CodingKey {
        case name
        case oneLetterCode
        case threeLetterCode
        case formula
        case represents
        case representedBy
    }

    public init(name: String, oneLetterCode: String, threeLetterCode: String = "", formula: Formula, represents: [String] = [], representedBy: [String] = []) {
        self.oneLetterCode = oneLetterCode
        self.threeLetterCode = threeLetterCode
        self.represents = represents
        self.representedBy = representedBy
        
        super.init(name: name, formula: formula)
    }

    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        oneLetterCode = try values.decode(String.self, forKey: .oneLetterCode)
        threeLetterCode = try values.decode(String.self, forKey: .threeLetterCode)
        represents = try values.decode([String].self, forKey: .represents)
        representedBy = try values.decode([String].self, forKey: .representedBy)
        
        super.init(name: try values.decode(String.self, forKey: .name),
                   formula: try values.decode(Formula.self, forKey: .formula))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(formula, forKey: .formula)
        try container.encode(oneLetterCode, forKey: .oneLetterCode)
        try container.encode(threeLetterCode, forKey: .threeLetterCode)
        try container.encode(represents, forKey: .represents)
        try container.encode(representedBy, forKey: .representedBy)
    }
}

extension AminoAcid: Symbol {
    public var identifier: String {
        return oneLetterCode
    }
}
