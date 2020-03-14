import Foundation

public var aminoAcidLibrary: [AminoAcid] = loadJSONFromBundle(fileName: "aminoacids")

// TODO: generate from modifications.json

public let oxidation = Modification(name: "Oxidation", reactions: [.add(oxygen)], sites: ["M", "W", "Y"])
public let deamidation = Modification(name: "Deamidation", reactions: [.add(water), .remove(ammonia)], sites: ["N", "Q"])
public let reduction = Modification(name: "Reduction", reactions: [.remove(hydrogen)], sites: ["C"])
public let methylation = Modification(name: "Methylation", reactions: [.add(methyl)], sites: ["K"])
public let acetylation = Modification(name: "Acetylation", reactions: [.add(acetyl)], sites: ["K", "NTerminal"])
public let amidation = Modification(name: "Amidation", reactions: [.add(amide), .remove(hydroxyl)], sites: ["CTerminal"])

public let pyroglutamateE = Modification(name: "Pyroglutamate (E)", reactions: [.remove(water)], sites: ["E"])
public let pyroglutamateQ = Modification(name: "Pyroglutamate (Q)", reactions: [.remove(ammonia)], sites: ["Q"])

public let cysteinylation = Modification(name: "Cysteinylation", reactions: [.remove(cysteinyl)], sites: ["C"])

public var aminoAcidModifications = [oxidation, deamidation, reduction, methylation, acetylation, amidation, pyroglutamateE, pyroglutamateQ, cysteinylation]

public struct AminoAcid: Residue, Codable {
    public let formula: Formula
    public let name: String
    public let oneLetterCode: String
    public let threeLetterCode: String
    public let represents: [String]
    public let representedBy: [String]

    public var modification: Modification? = nil

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
        formula = Formula(try container.decode(String.self, forKey: .formula))
        name = try container.decode(String.self, forKey: .name)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(formula.string, forKey: .formula)
        try container.encode(oneLetterCode, forKey: .oneLetterCode)
        try container.encode(threeLetterCode, forKey: .threeLetterCode)
        try container.encode(represents, forKey: .represents)
        try container.encode(representedBy, forKey: .representedBy)
    }
    
    var description: String {
        return threeLetterCode
    }
    
    public func allowedModifications() -> [Modification] {
        return uniModifications.filter { $0.sites.contains(identifier) == true }
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
