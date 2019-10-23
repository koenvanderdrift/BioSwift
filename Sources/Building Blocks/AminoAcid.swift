import Foundation

public var aminoAcidLibrary: [AminoAcid] = loadJSONFromBundle(fileName: "aminoacids")

public struct AminoAcid: Molecule, Residue, Codable {
    public let formula: Formula
    public var groups: [FunctionalGroup] = []
    public let name: String
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
//        print(Unmanaged.passUnretained(self).toOpaque())
        return calculateMasses()
    }
    
    public func calculateMasses() -> MassContainer {
        return formula.masses + modificationMasses()
    }
    
    private func modificationMasses() -> MassContainer {
        return mass(of: groups)
    }
}
