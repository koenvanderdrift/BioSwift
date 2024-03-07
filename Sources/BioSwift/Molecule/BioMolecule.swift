//
//  BioMolecule.swift
//
//
//  Created by Koen van der Drift on 5/9/21.
//

import Foundation

public struct BioMolecule<Residue> {
    public var adducts: [Adduct] = []
    public var chains: [Chain]
    
    public init(chain: Chain) {
        self.init(chains: [chain])
    }

    public init(chains: [Chain]) {
        self.chains = chains
    }
}

extension BioMolecule: ChargedMass {
    public var masses: MassContainer {
        calculateMasses()
    }
    
    public var charge: Int {
        chains.reduce(0) { $0 + $1.charge }
    }
    
    public func calculateMasses() -> MassContainer {
        return chains.reduce(zeroMass) { $0 + $1.masses }
    }
}

public extension BioMolecule {
    var formula: Formula {
        chains.reduce(zeroFormula) { $0 + $1.formula }
    }
    
    func sequenceLength(for chainIndex: Int = 0) -> Int {
        chains[chainIndex].numberOfResidues
    }
    
    func residues(for chainIndex: Int = 0) -> [Residue] {
        if let residues = chains[chainIndex].residues as? [Residue] {
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
    
    func isoelectricPoint(for chainIndex: Int = 0) -> Double {
        return Hydropathy(residues: chains[chainIndex].residues).isoElectricPoint()
    }
}

////
////  BioMolecule2.swift
////
////
////  Created by Koen van der Drift on 2/18/24.
////
//
//import Foundation
//import Swift
//
//let alanine = AminoAcid2(name: "Alanine", formula: Formula("C3H5NO"), oneLetterCode: "A", threeLetterCode: "Ala")
//let serine = AminoAcid2(name: "Serine", formula: Formula("C3H5NO2"), oneLetterCode: "S", threeLetterCode: "Ser")
//
//public protocol Residue2: Symbol, Structure {
//    var oneLetterCode: String { get }
//    var threeLetterCode: String { get }
//    var modification: Modification? { get set }
//}
//

//    func concatenateChains() -> Chain {
//        let residues = chains.reduce([]) { $0 + $1.residues }
//
//        return Chain(residues: residues)
//    }

//public extension Residue2 {
//    var identifier: String {
//        oneLetterCode
//    }
//
//    var masses: MassContainer {
//        calculateMasses()
//    }
//}
//
//public struct AminoAcid2: Residue2 {
//    public var name: String
//    public var formula: Formula
//    public var oneLetterCode: String
//    public var threeLetterCode: String
//    public var modification: Modification?
//    public var adducts: [Adduct] = []
//}
//
//extension AminoAcid2 {
//    public func calculateMasses() -> MassContainer {
//        mass(of: formula.elements)
//    }
//}
//
//public protocol Chain2: ChargedMass {
//    associatedtype Residue2
//    var residues: [Residue2] { get set }
//}
//
//extension Chain2 {
//    public var masses: MassContainer {
//        calculateMasses()
//    }
//
//    public func calculateMasses() -> MassContainer {
//        if let r = residues as? [any Mass] {
//            return mass(of: r) + water.masses
//        }
//
//        return zeroMass
//    }
//
//    public var sequenceString: String {
//        if let r = residues as? [Symbol] {
//            return r.map(\.identifier).joined()
//        }
//
//        return ""
//    }
//
//    var sequenceLength: Int {
//        sequenceString.count
//    }
//}
//
//struct Peptide2: Chain2 {
//    var residues: [AminoAcid2] = []
//    var adducts: [Adduct] = []
//}
//
//struct BioMolecule2<Residue2> {
//extension BioMolecule2: Mass, ChargedMass {
//    public var masses: MassContainer {
//        calculateMasses()
//    }
//
//    public func calculateMasses() -> MassContainer {
//        return chains.reduce(zeroMass) { $0 + $1.masses }
//    }
//}
//
//typealias Protein2 = BioMolecule2<AminoAcid2>
//
//extension Protein2 {
//    func aminoAcids(for chainIndex: Int = 0) -> [AminoAcid2] {
//        self.residues(for: chainIndex) as [AminoAcid2]
//    }
//}
//
//
//public struct BioMolecule2<T: Residue> {
//    public var name: String = ""
//    public var info: String = ""
//    public var masses: MassContainer = zeroMass
//    public var adducts: [Adduct] = []
//
//    public var chains: [Chain<T>] = []
//}
//
//public extension BioMolecule {
//    init(residues: [T]) {
//        self.init(chain: Chain<T>(residues: residues))
//    }
//
//    init(sequence: String) {
//        self.init(chain: Chain<T>(sequence: sequence))
//    }
//
//    init(chain: Chain<T>) {
//        self.init(chains: [chain])
//    }
//
//    init(chains: [Chain<T>]) {
//        self.chains = chains
//    }
//    
//    func sequenceLength(chainIndex index: Int = 0) -> Int {
//        chains[index].numberOfResidues()
//    }
//    
//    var formula: Formula {
//        chains.reduce(zeroFormula) { $0 + $1.formula }
//    }
//
//    var residues: [Residue] {
//        chains.reduce([]) { $0 + $1.residues }
//    }
//
//    var charge: Int {
//        chains.reduce(0) { $0 + $1.charge }
//    }
//    
//    func mass(chainIndex index: Int = -1) -> MassContainer {
//        var chain: Chain<T>
//
//        if index == -1 { // calculate for all chains when index = -1
//            chain = concatenateChains()
//        } else {
//            chain = chains[index]
//        }
//
//        chain.setAdducts(type: protonAdduct, count: charge)
//
//        return chain.pseudomolecularIon()
//    }
//
//    func selectionMass(chainIndex index: Int = 0, _ range: ChainRange) -> MassContainer {
//        guard var sub = chains[index].subChain(with: range) else { return zeroMass }
//
//        sub.setAdducts(type: protonAdduct, count: charge)
//
//        return sub.pseudomolecularIon()
//    }
//
//    func isoelectricPoint(chainIndex index: Int = -1) -> Double {
//        var chain: Chain<T>
//
//        if index == -1 { // calculate for all chains when index = -1
//            chain = concatenateChains()
//        } else {
//            chain = chains[index]
//        }
//
//        return Hydropathy(residues: chain.residues).isoElectricPoint()
//    }
//    
//    func concatenateChains() -> Chain<T> {
//        let residues = chains.reduce([]) { $0 + $1.residues }
//
//        return Chain<T>(residues: residues)
//    }
//}
//
//
//// Convenience accessors
//public extension BioMolecule {
//    var formula: Formula {
//        chains.reduce(zeroFormula) { $0 + $1.formula }
//    }
//
//    var residues: [Residue] {
//        chains.reduce([]) { $0 + $1.residues }
//    }
//
//    var charge: Int {
//        chains.reduce(0) { $0 + $1.charge }
//    }
//
//    func mass(chainIndex index: Int = -1) -> MassContainer {
//        var chain: T
//
//        if index == -1 { // calculate for all chains when index = -1
//            chain = concatenateChains()
//        } else {
//            chain = chains[index]
//        }
//
//        chain.setAdducts(type: protonAdduct, count: charge)
//
//        return chain.pseudomolecularIon()
//    }
//
//    func selectionMass(chainIndex index: Int = 0, _ range: ChainRange) -> MassContainer {
//        guard var sub = chains[index].subChain(with: range) else { return zeroMass }
//
//        sub.setAdducts(type: protonAdduct, count: charge)
//
//        return sub.pseudomolecularIon()
//    }
//
//    func isoelectricPoint(chainIndex index: Int = -1) -> Double {
//        var chain: T
//
//        if index == -1 { // calculate for all chains when index = -1
//            chain = concatenateChains()
//        } else {
//            chain = chains[index]
//        }
//
//        return Hydropathy(residues: chain.residues).isoElectricPoint()
//    }
//
//    func selectionIsoelectricPoint(chainIndex index: Int = 0, _ range: ChainRange) -> Double {
//        guard let sub = chains[index].subChain(with: range) else { return 0.0 }
//
//        return Hydropathy(residues: sub.residues).isoElectricPoint()
//    }
//
//    func sequenceString(chainIndex index: Int = 0) -> String {
//        chains[index].sequenceString
//    }
//
//    func selectionString(chainIndex index: Int = 0, range: ChainRange) -> String {
//        guard let sub = chains[index].subChain(with: range) else { return "" }
//
//        return sub.sequenceString
//    }
//
//    func sequenceLength(chainIndex index: Int = 0) -> Int {
//        chains[index].numberOfResidues()
//    }
//
//    func selectionLength(chainIndex index: Int = 0, range: ChainRange) -> Int {
//        guard let sub = chains[index].subChain(with: range) else { return 0 }
//
//        return sub.numberOfResidues()
//    }
//
//    func concatenateChains() -> T {
//        let residues = chains.reduce([]) { $0 + $1.residues }
//
//        return T(residues: residues)
//    }
//}
