//
//  Chain.swift
//  BioSwift
//
//  Created by Koen van der Drift on 5/22/17.
//  Copyright © 2017 Koen van der Drift. All rights reserved.
//

import Foundation

public typealias ChainRange = ClosedRange<Int>

public let zeroChainRange: ChainRange = -1...0
public let zeroNSRange = NSMakeRange(NSNotFound, 0)

extension NSRange {
    public init(from range: ChainRange) {
        self = NSMakeRange(range.lowerBound, range.upperBound - range.lowerBound + 1)
    }
    
    public func chainRange() -> ChainRange {
        guard self.location != NSNotFound && self.length > 0 else { return zeroChainRange }

        return self.lowerBound...self.upperBound - 1
    }
}

public protocol RangedChain: Chain {
    var rangeInParent: ChainRange { get set }
}

public protocol Chain: Structure {
    associatedtype ResidueType: Residue

    var symbolLibrary: [Symbol]  { get }
    
    var residues: [ResidueType] { get set }

    var termini: (first: ResidueType, last: ResidueType)?  { get set }
    var adducts: [Adduct] { get set }

    var modifications: [LocalizedModification] { get set }
    
    init(sequence: String)
    init(residues: [ResidueType])
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
        var f = Formula(residues.reduce("") { $0 + $1.formula.formulaString })
        
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
    
    public func createResidues(from string: String) -> [ResidueType] {
        return string.compactMap { char in
            symbolLibrary.first(where: { $0.identifier == String(char) }) as? ResidueType
        }
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
    
    public func subChain(removing range: ChainRange) -> Self? { // incoming range is 1 based

        // xxxx - ++++++++++++
        // ++ - xxxx - +++++++
        // ++++++++++++ - xxxx
        
        let subResidues = residues.indices.compactMap { (range.lowerBound - 1)..<range.upperBound ~= $0 ? nil : residues[$0] }
                
        var sub = Self.init(residues: subResidues)
        sub.termini = self.termini
        
        if range.lowerBound == 0 {
            sub.termini?.first.modification = self.termini?.first.modification
        }
        
        if range.upperBound == numberOfResidues() {
            sub.termini?.last.modification = self.termini?.last.modification
        }
        
        return sub
    }
    
    
    public func subChain(with range: ChainRange) -> Self? {
        guard let residues = residueChain(with: range) else { return nil }
        
        var sub = Self.init(residues: residues)
        sub.termini = self.termini
        
        if range.lowerBound == 0 {
            sub.termini?.first.modification = self.termini?.first.modification
        }
        
        if range.upperBound == numberOfResidues() {
            sub.termini?.last.modification = self.termini?.last.modification
        }
        
        return sub
    }

    public func subChain(with range: NSRange) -> Self? {
        return subChain(with: range.chainRange())
    }
    
    public func subChain(from: Int, to: Int) -> Self? {
        guard from < numberOfResidues(), to >= from else { return nil }
        
        return subChain(with: from...to)
    }

    public func residueChain(with range: ChainRange) -> [ResidueType]? {
        guard range != zeroChainRange else { return nil }
        
        return Array(residues[range])
    }

    public func residueChain(with range: NSRange) -> [ResidueType]? {
        return residueChain(with: range.chainRange())
    }
    
    public func residueChain(from: Int, to: Int) -> [ResidueType]? {
        guard from < numberOfResidues(), to >= from else { return nil }

        return residueChain(with: from...to)
    }
    
    public mutating func setTermini(first: ResidueType, last: ResidueType) {
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
    
    public func getModifications() -> [Modification] {
        var result: [Modification] = []
        
        residues.forEach {
            if let mod = $0.modification {
                result.append(mod)
            }
        }

        return result
    }
    
    public mutating func setModifcations(_ mods: [LocalizedModification]) {
        mods.forEach {
            addModification($0)
        }
    }
    
    public mutating func addModification(_ mod: LocalizedModification) {
        residues.modifyElement(atIndex: mod.location) { residue in
            residue.setModification(mod.modification)
        }
    }
    
    public mutating func removeModification(at location: Int) {
        residues.modifyElement(atIndex: location) { residue in
            residue.setModification(nil)
        }
    }
    
    public func modification(at location: Int) -> Modification? {
        return residue(at: location)?.modification
    }
}
