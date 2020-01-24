//
//  BioSequence.swift
//  BioSwift
//
//  Created by Koen van der Drift on 5/22/17.
//  Copyright © 2017 Koen van der Drift. All rights reserved.
//

import Foundation

public class BioSequence {
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
    
    public required init(sequence: String) {
        residueSequence = (symbols(from: sequence) as? [Residue])!
    }
    
    public init(residues: [Residue]) {
        residueSequence = residues
    }
}

extension BioSequence: Equatable {
    public static func == (lhs: BioSequence, rhs: BioSequence) -> Bool {
        return lhs.sequenceString == rhs.sequenceString
    }
}

extension BioSequence {
    public func update(_ sequence: String, in editedRange: NSRange, changeInLength: Int) {
        
        switch changeInLength {
        case Int.min..<0:
            let range = editedRange.location..<editedRange.location - changeInLength
            residueSequence.removeSubrange(range)
        case 0:
            let range = editedRange.location..<editedRange.location + editedRange.length
            let s = String(sequence[range])
            
            if let newResidues = symbols(from: s) as? [Residue] {
                residueSequence.replaceSubrange(range, with: newResidues)
            }
        case 0..<Int.max:
            let range = editedRange.location..<editedRange.location + changeInLength
            let s = String(sequence[range])
            
            if let newResidues = symbols(from: s) as? [Residue] {
                residueSequence.insert(contentsOf: newResidues, at: editedRange.location)
            }
        default:
            fatalError()
        }
        
        //        debugPrint(residueSequence?.map{ $0.oneLetterCode })
    }
    
    public func symbolSet() -> SymbolSet? {
        return SymbolSet(array: symbolSequence)
    }
    
    public func symbols(from string: String) -> [Symbol]? {
        let result = string.map { s in
            return symbolLibrary.first(where: { $0.identifier == String(s) })
        }
        
        return result as? [Symbol]
    }
    
    public func symbol(at index: Int) -> Symbol? {
        var result: Symbol? = nil
        
        if !sequenceString.isEmpty {
            result = symbolLibrary.first(where: { $0.identifier == String(sequenceString[index]) })
        }
        
        return result
    }
    
    public func residueSequence(with range: NSRange) -> [Residue] {
        if range.length == 0 { return [] }
        
        let slice = residueSequence[range.location..<range.location + range.length]
        
        return Array(slice)
    }
    
    public func symbolLocations(with identifiers: [String]) -> [Int] {
        var locations: [Int] = []
        
        for identifier in identifiers {
            locations += sequenceString.locations(of: identifier)
        }
        
        return locations
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
            residueSequence.modifyElement(atIndex: site) {
                let mod = Modification(group: modification.group, sites: [site])
                $0.modifications.append(mod)
            }
        }
    }
    
    public func remove(_ modification: Modification) {
        for site in modification.sites {
            residueSequence.modifyElement(atIndex: site) { residue in
                residue.modifications = residue.modifications.filter { $0.sites.first != site }
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

extension Array {
    mutating func modifyForEach(_ body: (_ index: Index, _ element: inout Element) -> ()) {
        for index in indices {
            modifyElement(atIndex: index) { body(index, &$0) }
        }
    }
    
    mutating func modifyElement(atIndex index: Index, _ modifyElement: (_ element: inout Element) -> ()) {
        var element = self[index]
        modifyElement(&element)
        self[index] = element
    }
}