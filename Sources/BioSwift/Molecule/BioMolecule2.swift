//
//  BioMolecule2.swift
//
//
//  Created by Koen van der Drift on 2/18/24.
//

import Foundation
import Swift

let alanine = AminoAcid2(name: "Alanine", formula: Formula("C3H5NO"), oneLetterCode: "A", threeLetterCode: "Ala")
let serine = AminoAcid2(name: "Serine", formula: Formula("C3H5NO2"), oneLetterCode: "S", threeLetterCode: "Ser")

public protocol Residue2: Symbol, Structure {
    var oneLetterCode: String { get }
    var threeLetterCode: String { get }
    var modification: Modification? { get set }
}

public extension Residue2 {
    var identifier: String {
        oneLetterCode
    }

    var masses: MassContainer {
        calculateMasses()
    }
}

public struct AminoAcid2: Residue2 {
    public var name: String
    public var formula: Formula
    public var oneLetterCode: String
    public var threeLetterCode: String
    public var modification: Modification?
    public var adducts: [Adduct] = []
}

extension AminoAcid2 {
    public func calculateMasses() -> MassContainer {
        mass(of: formula.elements)
    }
}

public protocol Chain2: ChargedMass {
    associatedtype Residue2
    var residues: [Residue2] { get set }
}

extension Chain2 {
    public var masses: MassContainer {
        calculateMasses()
    }

    public func calculateMasses() -> MassContainer {
        if let r = residues as? [any Mass] {
            return mass(of: r) + water.masses
        }

        return zeroMass
    }

    public var sequenceString: String {
        if let r = residues as? [Symbol] {
            return r.map(\.identifier).joined()
        }
        
        return ""
    }

    var sequenceLength: Int {
        sequenceString.count
    }
}

struct Peptide2: Chain2 {
    var residues: [AminoAcid2] = []
    var adducts: [Adduct] = []
}

struct BioMolecule2<Residue2> {
    var adducts: [Adduct] = []
    var chains: [any Chain2] = []
    
    func residues(for chainIndex: Int = 0) -> [Residue2] {
        if let residues = chains[chainIndex].residues as? [Residue2] {
            return residues
        }
        
        return []
    }

    func sequence(for chainIndex: Int = 0) -> String {
        chains[chainIndex].sequenceString
    }

    mutating func setAdducts(type: Adduct, count: Int, for chainIndex: Int = 0) {
        chains[chainIndex].setAdducts(type: type, count: count)
        adducts = [Adduct](repeating: type, count: count)
    }
}

extension BioMolecule2: Mass, ChargedMass {
    public var masses: MassContainer {
        calculateMasses()
    }

    public func calculateMasses() -> MassContainer {
        return chains.reduce(zeroMass) { $0 + $1.masses }
    }
}

typealias Protein2 = BioMolecule2<AminoAcid2>

extension Protein2 {
    func aminoAcids(for chainIndex: Int = 0) -> [AminoAcid2] {
        self.residues(for: chainIndex) as [AminoAcid2]
    }
}


