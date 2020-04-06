//
//  BioSequence.swift
//  BioSwift
//
//  Created by Koen van der Drift on 5/22/17.
//  Copyright © 2017 Koen van der Drift. All rights reserved.
//

import Foundation

public class BioSequence: Structure {
    public var name: String = ""
    
    public var symbolLibrary: [Symbol] = []
    
    public var residueSequence: [Residue] = [] {
        didSet {
            sequenceString = residueSequence.map { $0.identifier }.joined()
            formula = Formula(residueSequence.reduce("", { $0 + $1.formula.string }))
        }
    }
    
    public var sequenceString: String = ""
    public var formula: Formula = Formula("")
    
    var termini: (first: Residue, last: Residue)?
    
    var symbolSequence: [Symbol] {
        return residueSequence
    }
    
    public var rangeInParent = 0..<0
    
    public var modifications: ModificationSet = [] {
        didSet {
            oldValue.forEach {
                removeModification(at: $0.location )
            }
            
            modifications.forEach {
                addModification($0)
            }
        }
    }
    
    public init(sequence: String, library: [Symbol] = []) {
        symbolLibrary = library
        
        defer {
            residueSequence = residueSequence(from: sequence)
        }
    }
    
    public required init(residues: [Residue], library: [Symbol] = []) {
        symbolLibrary = library
        
        defer {
            residueSequence = residues
        }
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
        if sequence == sequenceString {
            return
        }
        
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
        let result = string.map { char -> Residue in
            return symbolLibrary.first(where: { $0.identifier == String(char) }) as! Residue
        }
        
        return result
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
    
    public func subSequence<T: BioSequence>(from: Int, to: Int) -> T {
        let sub = Array(self.residueSequence[from..<to])
        
        return T(residues: sub, library: self.symbolLibrary)
    }
}

extension BioSequence {
    public func allowedModifications(at location: Int) -> [Modification]? {
        if let residue = residue(at: location) {
            return residue.allowedModifications()
        }
        
        return nil
    }
    
    public func currentModifications() -> ModificationSet {
        var result: ModificationSet = []
        
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
    
    public func modification(at location: Int) -> LocalizedModification? {
        return modifications.first(where: { $0.location == location } )
    }
}

