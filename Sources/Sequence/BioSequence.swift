//
//  BioSequence.swift
//  BioSwift
//
//  Created by Koen van der Drift on 5/22/17.
//  Copyright © 2017 Koen van der Drift. All rights reserved.
//

import Foundation

public class BioSequence: Molecule {
    public var name: String = ""

    public var formula: Formula {
        return Formula(residueSequence.reduce("", { $0 + $1.formula.string }))
    }
    
    var symbolLibrary: [Symbol] = []
    
    var residueSequence = [Residue]()
    
    var symbolSequence: [Symbol] {
        return residueSequence
    }
    
    var sequenceString: String {
        return residueSequence.map { $0.identifier }.joined()
    }
    
    public var modifications: [Modification] {
        return residueSequence.flatMap { $0.modifications }
    }
    
    public required init(residues: [Residue], library: [Symbol] = []) {
        symbolLibrary = library
        residueSequence = residues
    }

    public init(sequence: String, library: [Symbol] = []) {
        symbolLibrary = library
        residueSequence = residueSequence(from: sequence)
    }    
}

extension BioSequence: Equatable {
 // https://khawerkhaliq.com/blog/swift-protocols-equatable-part-one/
    public static func == (lhs: BioSequence, rhs: BioSequence) -> Bool {
        return lhs.sequenceString == rhs.sequenceString && lhs.modifications == rhs.modifications
    }
}

extension BioSequence {
    public func update(with sequence: String, in editedRange: NSRange, changeInLength: Int) {
        switch changeInLength {
        case Int.min..<0:
            let range = editedRange.location..<editedRange.location - changeInLength
            residueSequence.removeSubrange(range)
            
        case 0..<Int.max:
            let range = editedRange.location..<editedRange.location + changeInLength
            let s = String(sequence[range])
            
            let newResidues = residueSequence(from: s)
            residueSequence.insert(contentsOf: newResidues, at: editedRange.location)
            
        default:
            fatalError()
        }
    }
    
    public func symbolSet() -> SymbolSet? {
        return SymbolSet(array: symbolSequence)
    }
    
    public func residueSequence(from string: String) -> [Residue] {
        let result = string.compactMap { char in
            return symbolLibrary.first(where: { $0.identifier == String(char) })
        }
        
        return (result as? [Residue])!
    }
    
    public func symbol(at index: Int) -> Symbol? {
        return symbolSequence[index]
    }
    
    public func residueSequence(with range: NSRange) -> [Residue]? {
        guard range.location < residueSequence.count, range.length > 0 else { return nil }
        
        return Array(residueSequence[range.location..<range.location + range.length])
    }
    
    public func symbolLocations(with identifiers: [String]) -> [Int] {
        let result = identifiers.map { i in
            return residueSequence.indices.filter { (residueSequence[$0].identifier) == i }
        }

        return result.flatMap { $0 }
    }
    
    public func functionalGroups(at index: Int) -> [FunctionalGroup]? {
        if let residue = symbol(at: index) as? Residue {
            return residue.modifications.map { $0.group }
        }

        return nil
    }
    
    public func possibleFunctionalGroups(at index: Int) -> [FunctionalGroup]? {
        if let symbol = symbol(at: index) {
            var possibleFunctionalGroups = functionalGroupLibrary.filter { $0.sites.contains(symbol.identifier) == true }
         
         // add N and C term groups
            if index == 0 {
                let nTermGroups = functionalGroupLibrary.filter { $0.sites.contains("NTerminal") == true }
                possibleFunctionalGroups.append(contentsOf: nTermGroups)
            }
            
            if index == sequenceString.count - 1 {
                let cTermGroups = functionalGroupLibrary.filter { $0.sites.contains("CTerminal") == true }
                possibleFunctionalGroups.append(contentsOf: cTermGroups)
            }
            
            return possibleFunctionalGroups
        }
        
        return nil
    }
    
    public func add(_ modification: Modification) {
        for site in modification.sites {
            residueSequence.modifyElement(atIndex: site) { residue in
               residue.addModification(with: modification.group, at: site)
            }
        }
    }
    
    public func remove(_ modification: Modification) {
        for site in modification.sites {
            residueSequence.modifyElement(atIndex: site) { residue in
                residue.removeModification(with: modification.group)
            }
        }
    }
    
    public func addModification(with name: String, at location: Int = -1) {
        if let group = functionalGroupLibrary.first(where: { $0.name == name }) {
            add(Modification(group: group, sites: [location]))
        }
    }
    
    public func removeModification(with name: String, at location: Int = -1) {
        if let group = functionalGroupLibrary.first(where: { $0.name == name }) {
            remove(Modification(group: group, sites: [location]))
        }
    }
}
