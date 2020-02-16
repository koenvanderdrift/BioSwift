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
    
    public var modifications: Set<LocalizedModification> = [] {
        didSet {
            oldValue.forEach {
                removeModification(at: $0.location )
            }
            
            modifications.forEach {
                addModification($0)
            }
        }
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
        return lhs.sequenceString == rhs.sequenceString && lhs.name == rhs.name
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
    
    public func residue(at index: Int) -> Residue? {
        return residueSequence[index]
    }

    public func residueSequence(with range: NSRange) -> [Residue]? {
        guard range.location < residueSequence.count, range.length > 0 else { return nil }
        
        return Array(residueSequence[range.location..<range.location + range.length])
    }
    
    public func residueLocations(with identifiers: [String]) -> [Int] {
        let result = identifiers.map { i in
            return residueSequence.indices.filter { (residueSequence[$0].identifier) == i }
        }

        return result.flatMap { $0 }
    }
}

extension BioSequence {
    public func allowedModifications(at location: Int) -> [Modification]? {
        if let residue = residue(at: location) {
            var modifications = residue.allowedModifications()
 
         // add N and C term groups
            if location == 0 {
                let nTermGroups = modificationsLibrary.filter { $0.sites.contains("NTerminal") == true }
                modifications.append(contentsOf: nTermGroups)
            }

            if location == sequenceString.count - 1 {
                let cTermGroups = modificationsLibrary.filter { $0.sites.contains("CTerminal") == true }
                modifications.append(contentsOf: cTermGroups)
            }
            
            return modifications
        }
        
        return nil
    }
    
    public func currentModifications() -> Set<LocalizedModification> {
        var result: Set<LocalizedModification> = []
        
        for (index, residue) in residueSequence.enumerated() {
            if let mod = residue.modification {
               result.insert(LocalizedModification(modification: mod, location: index))
            }
        }

        return result
    }
    
    public func addModification(_ mod: LocalizedModification) {
        residueSequence.modifyElement(atIndex: mod.location) { residue in
            if let modification = mod.modification {
                residue.setModification(modification)
            }
        }
    }
    
    public func removeModification(at location: Int) {
        residueSequence.modifyElement(atIndex: location) { residue in
            residue.setModification(nil)
        }
    }

    public func modifications(at locations: [Int]) -> [LocalizedModification]? {
        return Array(modifications.filter( { locations.contains( $0.location ) } ))
    }
}
