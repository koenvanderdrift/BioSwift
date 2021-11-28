//
//  BioMolecule.swift
//  
//
//  Created by Koen van der Drift on 5/9/21.
//

import Foundation

public struct BioMolecule<T: Chain> {
    public var name: String = ""
    public var chains: [T] = []
}

extension BioMolecule {
    public init(residues: [T.ResidueType]) {
        self.init(chain: T(residues: residues))
    }
    
    public init(sequence: String) {
        self.init(chain: T(sequence: sequence))
    }
    
    public init(chain: T) {
        self.init(chains: [chain])
    }

    public init(chains: [T]) {
        self.chains = chains
    }
}

// Convenience accessors
extension BioMolecule {
    public var formula: Formula {
        return chains.reduce(zeroFormula) { $0 + $1.formula }
    }
    
    public var residues: [Residue] {
        return chains.reduce([]) { $0 + $1.residues }
    }
    
    public var charge: Int {
        return chains.reduce(0) { $0 + $1.charge }
    }
    
    public func mass(chainIndex index: Int = -1) -> MassContainer {
        var chain: T
        
        if index == -1 { // calculate for all chains when index = -1
            chain = concatenateChains()
        }
        else {
            chain = chains[index]
        }
        
        chain.setAdducts(type: protonAdduct, count: charge)
        
        return chain.pseudomolecularIon()
    }
    
    public func selectionMass(chainIndex index: Int = 0, _ range: ChainRange) -> MassContainer {
        guard var sub = chains[index].subChain(with: range) else { return zeroMass }

        sub.setAdducts(type: protonAdduct, count: charge)

        return sub.pseudomolecularIon()
    }
    
    public func isoelectricPoint(chainIndex index: Int = -1) -> Double {
        var chain: T
        
        if index == -1 { // calculate for all chains when index = -1
            chain = concatenateChains()
        }
        else {
            chain = chains[index]
        }

        return Hydropathy(residues: chain.residues).isoElectricPoint()
    }

    public func selectionIsoelectricPoint(chainIndex index: Int = 0, _ range: ChainRange) -> Double {
        guard let sub = chains[index].subChain(with: range) else { return 0.0 }

        return Hydropathy(residues: sub.residues).isoElectricPoint()
    }
    
    public func sequenceString(chainIndex index: Int = 0) -> String {
        return chains[index].sequenceString
    }
    
    func selectionString(chainIndex index: Int = 0, range: ChainRange) -> String {
        guard let sub = chains[index].subChain(with: range) else { return "" }

        return sub.sequenceString
    }
    
    public func sequenceLength(chainIndex index: Int = 0) -> Int {
        return chains[index].numberOfResidues()
    }
    
    public func selectionLength(chainIndex index: Int = 0, range: ChainRange) -> Int {
        guard let sub = chains[index].subChain(with: range) else { return 0 }
        
        return sub.numberOfResidues()
    }
    
    public func concatenateChains() -> T {
        let residues = self.chains.reduce([]) { $0 + $1.residues }

        return T.init(residues: residues)
    }
}
