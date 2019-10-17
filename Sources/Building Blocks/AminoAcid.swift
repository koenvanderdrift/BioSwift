import Foundation

public var aminoAcidLibrary: [AminoAcid] = loadJSONFromBundle(fileName: "aminoacids")

public struct AminoAcid: Molecule, Residue, Codable {
    public var groups: [FunctionalGroup] = []
    
    public var name: String
    public var formula: Formula
    public var oneLetterCode: String
    public var threeLetterCode: String
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
        self.name = name
        self.oneLetterCode = oneLetterCode
        self.threeLetterCode = threeLetterCode
        self.formula = formula
        self.represents = represents
        self.representedBy = representedBy
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        represents = try values.decode([String].self, forKey: .represents)
        representedBy = try values.decode([String].self, forKey: .representedBy)
        oneLetterCode = try values.decode(String.self, forKey: .oneLetterCode)
        threeLetterCode = try values.decode(String.self, forKey: .threeLetterCode)
        //        self.formula = try values.decode(Formula.self, forKey: .formula)
       formula = Formula(stringValue: "C12N2H33O2")
        name = try values.decode(String.self, forKey: .name)
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
    
    public func calculateMasses() -> MassContainer {
        var f = formula
        return f.masses + modificationMasses()
    }
    
    private func modificationMasses() -> MassContainer {
        return groups.reduce(zeroMass, {$0 + $1.masses})
    }
}
