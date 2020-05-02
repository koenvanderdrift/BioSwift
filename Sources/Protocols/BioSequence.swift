//
//  BioSequence.swift
//  BioSwift
//
//  Created by Koen van der Drift on 5/22/17.
//  Copyright © 2017 Koen van der Drift. All rights reserved.
//

import Foundation

public let zeroSequenceRange: Range<Int> = 0..<0

public typealias RangeableSequence = BioSequence & Rangeable

public protocol Rangeable {
    var rangeInParent: Range<Int> { get set }
}

public protocol BioSequence: Structure, Equatable {
    var symbolLibrary: [Symbol]  { get set }
    var residues: [Residue] { get set }
    var termini: (first: Residue, last: Residue)?  { get set }

    var modifications: ModificationSet { get set }

    init(residues: [Residue])
    init(sequence: String)
}

extension BioSequence {
    public var name: String {
        return ""
    }
    
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
            fatalError()
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
    
    public func residueSequence(with range: NSRange) -> [Residue]? {
        guard range.location < residues.count, range.length > 0 else { return nil }
        
        return Array(residues[range.location ..< range.location + range.length])
    }
    
    public func residueLocations(with identifiers: [String]) -> [Int] {
        let result = identifiers.map { i in
            residues.indices.filter { (residues[$0].identifier) == i }
        }
        
        return result.flatMap { $0 }
    }
    
    public func subSequence<T: BioSequence>(from: Int, to: Int) -> T {
        let sub = Array(residues[from ..< to])
        
        return T.init(residues: sub)
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
        
        for (index, residue) in residues.enumerated() {
            if let mod = residue.modification {
                result.insert(LocalizedModification(modification: mod, location: index))
            }
        }
        
        return result
    }
    
    public mutating func addModification(_ mod: LocalizedModification) {
        residues.modifyElement(atIndex: mod.location) { residue in
            if let modification = mod.modification {
                residue.setModification(modification)
            }
        }
    }
    
    public mutating func removeModification(at location: Int) {
        residues.modifyElement(atIndex: location) { residue in
            residue.setModification(nil)
        }
    }
    
    public func modification(at location: Int) -> LocalizedModification? {
        return modifications.first(where: { $0.location == location })
    }
}
