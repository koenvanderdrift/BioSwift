import Foundation

public var elementLibrary: Elements = loadJSONFromBundle(fileName: "elements")

public struct Isotope: Codable {
    public let mass: String
    public let ordinalNumber: String
    public let abundance: String
}

public struct ChemicalElement: Codable, Symbol {
    private(set) var _masses: MassContainer = zeroMass

    public let name: String
    public let symbol: String
    public let isotopes: [Isotope]

    private enum CodingKeys: String, CodingKey {
        case name
        case symbol
        case isotopes
    }

    public init(name: String, symbol: String, isotopes: [Isotope]) {
        self.name = name
        self.symbol = symbol
        self.isotopes = isotopes
        
        _masses = calculateMasses()
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)
        symbol = try container.decode(String.self, forKey: .symbol)
        isotopes = try container.decode([Isotope].self, forKey: .isotopes)

        _masses = calculateMasses()
    }
    
    public var identifier: String {
        return symbol
    }
    
    var description: String {
        return symbol
    }
}

extension ChemicalElement: Mass {
    public var masses: MassContainer {
        return _masses
    }

    public func calculateMasses() -> MassContainer {
        var currentAbundance = Decimal(0.0)
        
        var monoisotopicMass = Decimal(0.0)
        var averageMass = Decimal(0.0)
        var nominalMass = Decimal(0.0)
        
        for i in isotopes {
            let abundance = Decimal(string: i.abundance)! * Decimal(0.01)
            let mass = Decimal(string: i.mass)!
            
            if abundance > currentAbundance {
                nominalMass = mass
                monoisotopicMass = mass
                currentAbundance = abundance
            }
            
            averageMass += abundance * mass
        }
        
        return MassContainer(monoisotopicMass: monoisotopicMass, averageMass: averageMass, nominalMass: NSDecimalNumber(decimal: nominalMass).intValue)
    }
}
