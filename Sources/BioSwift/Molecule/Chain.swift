//
//  Chain.swift
//  BioSwift
//
//  Created by Koen van der Drift on 5/22/17.
//  Copyright © 2017 Koen van der Drift. All rights reserved.
//

import Foundation

public protocol RangedSequence: Chain {
    var rangeInParent: SequenceRange { get set }
}

public protocol Chain: Structure, Equatable {
    var name: String { get set }
    var symbolLibrary: [Symbol]  { get }
    
    var residues: [Residue] { get set }
    
    var termini: (first: Residue, last: Residue)?  { get set }
    var modifications: ModificationSet { get set }

    init(residues: [Residue])
    init(sequence: String)
}

extension Chain {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.sequenceString == rhs.sequenceString && lhs.name == rhs.name
    }
    
    public var symbolSequence: [Symbol] {
        return residues
    }
    
    public var sequenceString: String {
        return residues.map { $0.identifier }.joined()
    }
    
    public var formula: Formula {
        var f = Formula(residues.reduce("") { $0 + $1.formula.string })
        
        if let termini = termini {
            f += termini.first.formula + termini.last.formula
        } else {
            f += water.formula
        }
        
        return f
    }
    
    public var symbolSet: SymbolSet? {
        return SymbolSet(array: symbolSequence)
    }

    public mutating func update(with sequence: String, in editedRange: NSRange, changeInLength: Int) {
        if sequence == sequenceString {
            return
        }
        
        switch changeInLength {
        case Int.min ..< 0:
            let range = editedRange.location ..< editedRange.location - changeInLength
            residues.removeSubrange(range)
            
        case 0 ..< Int.max:
            let range = editedRange.location ..< editedRange.location + changeInLength
            let s = String(sequence[range])
            
            let newResidues = createResidues(from: s)
            residues.insert(contentsOf: newResidues, at: editedRange.location)
            
        default:
            fatalError("TODO")
        }
    }
    
    public func createResidues(from string: String) -> [Residue] {
        let result = string.map { char -> Residue in
            symbolLibrary.first(where: { $0.identifier == String(char) }) as! Residue
        }
        
        return result
    }
    
    public func symbol(at index: Int) -> Symbol? {
        return symbolSequence[index]
    }
    
    public func residue(at index: Int) -> Residue? {
        return residues[index]
    }
    
    public func residueLocations(with identifiers: [String]) -> [Int] {
        let result = identifiers.map { i in
            residues.indices.filter { (residues[$0].identifier) == i }
        }
        
        return result.flatMap { $0 }
    }
    
    public func numberOfResidues() -> Int {
        return residues.count
    }
    
    public func subChain<T: Chain>(with range: SequenceRange) -> T? {
        guard let residues = residueChain(with: range) else { return nil }
        
        var sub = T.init(residues: residues)
        sub.termini = self.termini
        
        if range.lowerBound == 0 {
            sub.termini?.first.modification = self.termini?.first.modification
        }
        
        if range.upperBound == numberOfResidues() {
            sub.termini?.last.modification = self.termini?.last.modification
        }
        
        return sub
    }

    public func subChain<T: Chain>(with range: NSRange) -> T? {
        return subChain(with: range.sequenceRange())
    }
    
    public func subChain<T: Chain>(from: Int, to: Int) -> T? {
        guard from < numberOfResidues(), to >= from else { return nil }
        
        return subChain(with: from...to)
    }

    public func residueChain(with range: SequenceRange) -> [Residue]? {
        guard range != zeroSequenceRange else { return nil }
        
        return Array(residues[range])
    }

    public func residueChain(with range: NSRange) -> [Residue]? {
        return residueChain(with: range.sequenceRange())
    }
    
    public func residueChain(from: Int, to: Int) -> [Residue]? {
        guard from < numberOfResidues(), to >= from else { return nil }

        return residueChain(with: from...to)
    }
    
    public mutating func setTermini(first: Residue, last: Residue) {
        termini = (first: first, last: last)
    }
    
    public func terminalMasses() -> MassContainer {
        var result = zeroMass
        
        if let first = termini?.first {
            result += first.masses
        }
        
        if let last = termini?.last {
            result += last.masses
        }
        
        return result
    }
    
    public func allowedModifications(at location: Int) -> [Modification]? {
        if let residue = residue(at: location) {
            return residue.allowedModifications()
        }
        
        return nil
    }
    
    public func currentModifications() -> ModificationSet {
        var result: ModificationSet = []
        
        for residue in residues {
            if let mod = residue.modification {
                result.insert(mod)
            }
        }
        
        return result
    }
    
    public mutating func addModification(_ mod: Modification) {
        residues.modifyElement(atIndex: mod.location) { residue in
            residue.setModification(mod)
        }
    }
    
    public mutating func removeModification(at location: Int) {
        residues.modifyElement(atIndex: location) { residue in
            residue.setModification(nil)
        }
    }
    
    public func modification(at location: Int) -> Modification? {
        return modifications.first(where: { $0.location == location })
    }
}
