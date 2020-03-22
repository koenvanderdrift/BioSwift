import Foundation

public var elementLibrary: Elements = loadJSONFromBundle(fileName: "elements")

public let electron = ChemicalElement(name: "electron", symbol: "e", masses: MassContainer(monoisotopicMass: Dalton(0.00054858026), averageMass: Dalton(0.00054858026), nominalMass: 0))

public struct Isotope: Codable {
    public let mass: String
    public let ordinalNumber: String
    public let abundance: String
}

public typealias Dalton = Double

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
    
    public init(name: String, symbol: String, masses: MassContainer) {
        self.name = name
        self.symbol = symbol
        self.isotopes = []
        
        _masses = masses
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
        var currentAbundance = Dalton(0.0)
        
        var monoisotopicMass = Dalton(0.0)
        var averageMass = Dalton(0.0)
        var nominalMass = 0
        //The nominal mass for an element is the mass number of its most abundant naturally occurring stable isotope
        for i in isotopes {
            let abundance = Dalton(i.abundance)! * Dalton(0.01)
            let mass = Dalton(i.mass)!
            
            if abundance > currentAbundance {
                nominalMass = Int(mass)
                monoisotopicMass = mass
                currentAbundance = abundance
            }
            
            averageMass += abundance * mass
        }
        
        return MassContainer(monoisotopicMass: monoisotopicMass, averageMass: averageMass, nominalMass: nominalMass)
    }
}
