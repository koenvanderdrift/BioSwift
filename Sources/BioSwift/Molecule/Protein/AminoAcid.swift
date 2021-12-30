import Foundation

public let nTermString = "N-term"
public let cTermString = "C-term"

public struct AminoAcidProperties: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let polar        = AminoAcidProperties(rawValue: 1 << 0)
    public static let nonpolar     = AminoAcidProperties(rawValue: 1 << 1)
    public static let hydrophobic  = AminoAcidProperties(rawValue: 1 << 2)
    public static let small        = AminoAcidProperties(rawValue: 1 << 3)
    public static let tiny         = AminoAcidProperties(rawValue: 1 << 4)
    public static let aromatic     = AminoAcidProperties(rawValue: 1 << 5)
    public static let aliphatic    = AminoAcidProperties(rawValue: 1 << 6)
    public static let negative     = AminoAcidProperties(rawValue: 1 << 7)
    public static let positive     = AminoAcidProperties(rawValue: 1 << 8)
    public static let uncharged    = AminoAcidProperties(rawValue: 1 << 9)
    public static let chargedPos   = AminoAcidProperties(rawValue: 1 << 10)
    public static let chargedNeg   = AminoAcidProperties(rawValue: 1 << 11)
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
        self.adducts = []
        
        setProperties()
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.represents = try container.decode([String].self, forKey: .represents)
        self.representedBy = try container.decode([String].self, forKey: .representedBy)
        self.oneLetterCode = try container.decode(String.self, forKey: .oneLetterCode)
        self.threeLetterCode = try container.decode(String.self, forKey: .threeLetterCode)
        self.formula = Formula(try container.decode(String.self, forKey: .formula))
        self.name = try container.decode(String.self, forKey: .name)
        self.adducts = []

        setProperties()
    }

    public init(name: String, oneLetterCode: String, threeLetterCode: String = "", elements: [String: Int]) {
        var formulaString = ""

        for (element, count) in elements {
            formulaString.append(element)
            if count > 1 {
                formulaString.append(String(abs(count)))
            }
        }

        let formula = Formula(formulaString)

        self.init(name: name, oneLetterCode: oneLetterCode, threeLetterCode: threeLetterCode, formula: formula)

        self.setProperties()
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
