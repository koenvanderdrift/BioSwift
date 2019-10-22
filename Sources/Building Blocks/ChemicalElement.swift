import Foundation

public var elementLibrary: [ChemicalElement] = loadJSONFromBundle(fileName: "elements")

public struct Isotope: Codable {
    public let mass: String
    public let ordinalNumber: String
    public let abundance: String
}

extension Isotope {
    var massDouble: Double {
        return Double(mass) ?? 0.0
    }
    var abundanceDouble: Double {
        return Double(abundance) ?? 0.0
    }
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
}

extension ChemicalElement: Mass {
    public var masses: MassContainer {
        return _masses
    }

    public func calculateMasses() -> MassContainer {
        var currentMass = 0.0
        var currentAbundance = 0.0
        
        var monoisotopicMass = 0.0
        var averageMass = 0.0
        var nominalMass = 0.0
        
        for i in isotopes {
            let abundance = i.abundanceDouble * 0.01
            let mass = i.massDouble
            
            if abundance > currentAbundance {
                nominalMass = mass.rounded().nextDown
                monoisotopicMass = mass
                currentAbundance = abundance
            }
            
            currentMass += abundance * mass
        }
        
        averageMass = currentMass
        
        return MassContainer(monoisotopicMass: monoisotopicMass, averageMass: averageMass, nominalMass: nominalMass)
    }
}
