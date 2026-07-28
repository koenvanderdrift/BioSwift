//
//  Chain.swift
//  BioSwift
//
//  Created by Koen van der Drift on 5/22/17.
//  Copyright © 2017 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

// https://medium.com/swift2go/mastering-generics-with-protocols-the-specification-pattern-5e2e303af4ca

/// Chain is a protocol that describes ``Residue`` array
public protocol Chain {
    associatedtype ResidueType: Residue

    var name: String { get set }
    var residues: [ResidueType] { get set }
    var nTerminal: Modification { get set }
    var cTerminal: Modification { get set }
    var adducts: [Adduct] { get set }
    var range: Range<Int> { get set }
    var parentLength: Int { get set }

    init(sequence: String)
    init(residues: [ResidueType])

    func createResidues(from string: String) -> [ResidueType]
}

extension Chain {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.sequenceString == rhs.sequenceString && lhs.name == rhs.name
    }

    public var formula: Formula {
        var f = zeroFormula

        for residue in residues {
            f += residue.formula

            if let mod = residue.modification { f += mod.formula }
        }

        f += nTerminal.formula + cTerminal.formula

        return f
    }

    public var sequenceString: String { residues.map(\.identifier).joined() }

    public var sequenceLength: Int { numberOfResidues }

    public var symbolSequence: [Symbol] { residues }

    public var symbolSet: SymbolSet? { SymbolSet(array: symbolSequence) }

    public func symbol(at index: Int) -> Symbol? { symbolSequence[index] }

    public func residue(at index: Int) -> ResidueType? { residues[index] }

    public var numberOfResidues: Int { residues.count }

    public func countAllResidues() -> NSCountedSet { NSCountedSet(array: residues) }

    public func countOneResidue(with identifier: String) -> Int {
        var count = 0

        for residue in residues where residue.oneLetterCode == identifier { count += 1 }

        return count
    }
}

extension Chain {
    public mutating func insertResidue(_ residue: ResidueType, at location: Int) {
        guard residues.indices.contains(location) || location == residues.endIndex else { return }

        residues.insert(residue, at: location)
    }

    public mutating func insertResidue(_ residue: any Residue, at location: Int) {
        guard let residue = residue as? ResidueType else { return }

        insertResidue(residue, at: location)
    }

    public mutating func insertResidues(_ newResidues: [ResidueType], at location: Int) {
        guard location >= residues.startIndex, location <= residues.endIndex else { return }

        residues.insert(contentsOf: newResidues, at: location)
    }

    public mutating func insertResidues(_ newResidues: [any Residue], at location: Int) {
        let typedResidues = newResidues.compactMap { $0 as? ResidueType }

        guard typedResidues.count == newResidues.count else { return }

        insertResidues(typedResidues, at: location)
    }

    public mutating func removeResidue(at location: Int) {
        guard residues.indices.contains(location) else { return }

        residues.remove(at: location)
    }

    public mutating func removeResidues(in range: Range<Int>) {
        guard range.lowerBound >= residues.startIndex, range.upperBound <= residues.endIndex else {
            return
        }

        residues.removeSubrange(range)
    }

    public mutating func replaceResidue(at location: Int, with residue: ResidueType) {
        guard residues.indices.contains(location) else { return }

        residues[location] = residue
    }

    public mutating func replaceResidue(at location: Int, with residue: any Residue) {
        guard let residue = residue as? ResidueType else { return }

        replaceResidue(at: location, with: residue)
    }
}

extension Chain {
    // Sequence domain logic: zero-based residue positions

    /// Returns the sequence contained within a zero-based, non-inclusive residue range.
    ///
    /// Example:
    /// `sequenceString == "MKWVTFISLL"` and `range == 3..<6`
    /// returns `"VTF"`.
    public func subSequence(range: Range<Int>) -> String {
        precondition(range.lowerBound >= 0)

        precondition(range.upperBound < sequenceString.count)

        let lowerIndex = sequenceString.index(
            sequenceString.startIndex, offsetBy: range.lowerBound - 1)

        let upperIndex = sequenceString.index(sequenceString.startIndex, offsetBy: range.upperBound)

        return String(sequenceString[lowerIndex..<upperIndex])
    }

    public func subChain(range: Range<Int>) -> Self {
        let validRange = range.clamped(toSequenceLength: residues.count)

        guard validRange.isValidRange else { return Self(residues: []) }

        let newResidues = Array(residues[validRange])

        var subChain = Self(residues: newResidues)

        subChain.range = validRange

        return subChain
    }

    public func removing(_ range: Range<Int>) -> Self {
        let validRange = range.clamped(toSequenceLength: residues.count)

        guard validRange.isValidRange else { return Self(residues: residues) }

        var newResidues = residues
        newResidues.removeSubrange(validRange)

        var subChain = Self(residues: newResidues)

        subChain.range = validRange

        return subChain
    }

    public func residueLocations(with identifiers: Set<String>) -> [Int] {
        var locations: [Int] = []
        locations.reserveCapacity(residues.count)

        for index in residues.indices {
            if identifiers.contains(residues[index].identifier) { locations.append(index) }
        }

        return locations
    }
}

extension Chain {
    public mutating func setTermini(nTerm: Modification, cTerm: Modification) {
        nTerminal = nTerm
        cTerminal = cTerm
    }

    public func allowedModifications(at location: Int) -> [Modification]? {
        if let residue = residue(at: location) { return residue.allowedModifications() }

        return nil
    }

    public func getModifications() -> [Modification] {
        var result: [Modification] = []

        for residue in residues { if let mod = residue.modification { result.append(mod) } }

        return result
    }

    public func modification(at location: Int) -> Modification? {
        residue(at: location)?.modification
    }

    public mutating func addModification(_ mod: Modification, at loc: Int) {
        guard residues.indices.contains(loc) else { return }
        residues[loc].modification = mod
    }

    public mutating func removeModification(at loc: Int) {
        guard residues.indices.contains(loc) else { return }
        residues[loc].modification = nil
    }

    public mutating func modifyResidues(for identifier: String, with modification: Modification) {
        for index in residues.indices {
            if residues[index].identifier == identifier {
                residues[index].modification = modification
            }
        }
    }

    public mutating func removeModifications(for identifier: String) {
        for index in residues.indices {
            if residues[index].identifier == identifier { residues[index].modification = nil }
        }
    }
}
