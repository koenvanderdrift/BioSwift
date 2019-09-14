//
//  BioSequence.swift
//  BioSwift
//
//  Created by Koen van der Drift on 5/22/17.
//  Copyright © 2017 Koen van der Drift. All rights reserved.
//

import Foundation

public enum SequenceType {
    case protein
    case dna
    case rna
    case undefined
}

public class BioSequence: NSObject, Mass {
    public var sequence: String
    public let type: SequenceType
    public var modifications: [Modification]

    public init(sequence: String, type: SequenceType, charge: Int = 0) {
        self.sequence = sequence
        self.type = type
        self.charge = charge
        self.modifications = []
    }

    lazy var symbolLibrary: [Symbol]? = {
        switch type {
        case .protein:
            return aminoAcidLibrary
            
        case .dna, .rna, .undefined:
            return nil
        }
    }()
    
    public func symbolSequence() -> [Symbol]? {
        var result: [Symbol] = []

        // use map?
        for s in sequence {
            if let symbol = symbolLibrary?.first(where: { $0.identifier == String(s) }) {
                result.append(symbol)
            }
        }

        return result
    }
    
    public func symbolSet() -> SymbolSet? {
        guard let symbols = symbolSequence() else { return nil }

        return SymbolSet(array: symbols)
    }
    
    public func symbol(at index: Int) -> Symbol? {
        var result: Symbol? = nil

        if !sequence.isEmpty {
            result = symbolLibrary?.first(where: { $0.identifier == String(sequence[index])
            })
        }

        return result
    }
    
    public func symbolLocations(with identifiers: [String]) -> [Int] {
        guard let enumeratedSymbols = symbolSequence()?.enumerated() else { return [] }
        
        var locations: [Int] = []
        
        for identifier in identifiers {
            let indices = enumeratedSymbols.filter {
                $0.element.identifier == identifier
            }
            
            locations += indices.map{ $0.offset }
        }
        
        return locations
    }


    public var charge: Int = 0 {
        didSet {
//            debugPrint(" didSet charge")
//            var mods = modifications.filter { $0 != proton }
//            for _ in 0..<charge {
//                mods.append(proton)
//            }
//          modifications = mods
        }
    }
    
    public var masses: MassContainer {
        get {
            return calculateMasses()
        }
    }
    
    public func calculateMasses() -> MassContainer {
        var sequenceMass = zeroMass
        
        //
        if let symbols = symbolSet() {
            for case let massSymbol as Mass in symbols {
                let count = symbols.count(for: massSymbol)
                sequenceMass += count * massSymbol.masses
            }
            
            return sequenceMass + modificationMasses() + adductMasses() + nterm.masses + cterm.masses
        }
        
        return sequenceMass
    }
    


}

extension BioSequence {
    private func modificationMasses() -> MassContainer {
        return modifications.reduce(zeroMass, {$0 + $1.group.masses})
    }
    
    private func adductMasses() -> MassContainer {
        // for now assume protonation only
        // adduct is a modification ?
        return charge * proton.masses
    }
}

extension BioSequence {
    public func possibleFunctionalGroups(at index: Int) -> [FunctionalGroup]? {
        if let symbol = symbol(at: index) {
            var possibleFunctionalGroups = functionalGroupLibrary.filter { $0.sites.contains(symbol.identifier) == true }
            // add N and C term groups
            if index == 0 {
                let nTermGroups = functionalGroupLibrary.filter { $0.sites.contains("NTerminal") == true }
                possibleFunctionalGroups.append(contentsOf: nTermGroups)
            }
            
            if index == sequence.count - 1 {
                let cTermGroups = functionalGroupLibrary.filter { $0.sites.contains("CTerminal") == true }
                possibleFunctionalGroups.append(contentsOf: cTermGroups)
            }
            
            return possibleFunctionalGroups
        }
        
        return nil
    }
    
//    public func addModification(with name: String, at location: Int = -1) {
//        if let group = functionalGroupsArray.first(where: { $0.name == name }) {
//            let mod = Modification(group: group, location: location, site: symbol(at: location)?.identifier ?? "")
//            modifications.append(mod)
//        }
//    }
//
//    public func removeModification(_ modification: Modification) {
//        modifications = modifications.filter { $0 != modification }
//    }
}


public class SymbolSet: NSCountedSet {    
    public func countFor(_ identifier: String) -> Int {
        let symbol = self.compactMap { $0 as? Symbol }.first(where: { $0.identifier == identifier })
        
        return self.count(for: symbol as Any)
    }
}

extension Collection where Iterator.Element == BioSequence {
    public func charge(minCharge: Int, maxCharge: Int) -> [BioSequence] {
        var result: [BioSequence] = []
        
        for z in minCharge ... maxCharge {
            let chargedSequences = map { (s) -> BioSequence in
                return BioSequence(sequence: s.sequence, type: s.type, charge: z)
            }
            
            result.append(contentsOf: chargedSequences)
        }
        
        return result
    }
}

