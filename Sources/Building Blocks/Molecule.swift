//
//  Molecule.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/22/20.
//

import Foundation

public struct Molecule: Structure, Codable {
    public let name: String
    public let formula: Formula
    
    private(set) var _masses: MassContainer = zeroMass
    
    private enum CodingKeys: String, CodingKey {
        case name
        case formula
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        formula = Formula(try container.decode(String.self, forKey: .formula))
        
        _masses = calculateMasses()
    }
    
    public init(name: String, formula: Formula) {
        self.name = name
        self.formula = formula
        
        _masses = calculateMasses()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(formula.string, forKey: .formula)
    }
    
    public var masses: MassContainer {
        return _masses
    }
    
    var description: String {
        return name
    }
}

extension Molecule: Hashable {
    public static func == (lhs: FunctionalGroup, rhs: FunctionalGroup) -> Bool {
        return lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(formula.string)
    }
}

extension Molecule: Mass {
    public func calculateMasses() -> MassContainer {
        return mass(of: formula.elements)
    }
}
