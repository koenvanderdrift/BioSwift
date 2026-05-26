//
//  Chain.swift
//  BioSwift
//
//  Created by Koen van der Drift on 5/22/17.
//  Copyright © 2017 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

// https://medium.com/swift2go/mastering-generics-with-protocols-the-specification-pattern-5e2e303af4ca

public protocol Chain: Codable {
    associatedtype ResidueType: Residue

    var name: String { get set }
    var residues: [ResidueType] { get set }
    var modifications: [LocalizedModification] { get set }
    var nTerminal: Modification { get set }
    var cTerminal: Modification { get set }
    var adducts: [Adduct] { get set }
    var rangeInParent: ChainRange { get set }
    var parentLength: Int { get set }

    init(sequence: String)
    init(residues: [ResidueType])

    func createResidues(from string: String) -> [ResidueType]
}

public extension Chain {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.sequenceString == rhs.sequenceString && lhs.name == rhs.name
    }

    var formula: Formula {
        var f = zeroFormula

        for residue in residues {
            f += residue.formula

            if let mod = residue.modification {
                f += mod.formula
            }
        }

        f += nTerminal.formula + cTerminal.formula

        return f
    }

    var sequenceString: String {
        residues.map(\.identifier).joined()
    }

    var sequenceLength: Int {
        numberOfResidues
    }

    var symbolSequence: [Symbol] {
        residues
    }

    var symbolSet: SymbolSet? {
        SymbolSet(array: symbolSequence)
    }

    func symbol(at index: Int) -> Symbol? {
        symbolSequence[index]
    }

    func residue(at index: Int) -> ResidueType? {
        residues[index]
    }

    var numberOfResidues: Int {
        residues.count
    }

    func countAllResidues() -> NSCountedSet {
        NSCountedSet(array: residues)
    }

    func countOneResidue(with identifier: String) -> Int {
        var count = 0

        for residue in residues where residue.oneLetterCode == identifier {
            count += 1
        }

        return count
    }
}

public extension Chain {
    mutating func insertResidue(_ residue: ResidueType, at location: Int) {
        guard residues.indices.contains(location) || location == residues.endIndex else {
            return
        }

        residues.insert(residue, at: location)
    }

    mutating func insertResidue(_ residue: any Residue, at location: Int) {
        guard let residue = residue as? ResidueType else {
            return
        }

        insertResidue(residue, at: location)
    }

    mutating func insertResidues(_ newResidues: [ResidueType], at location: Int) {
        guard location >= residues.startIndex,
              location <= residues.endIndex
        else {
            return
        }

        residues.insert(contentsOf: newResidues, at: location)
    }

    mutating func insertResidues(_ newResidues: [any Residue], at location: Int) {
        let typedResidues = newResidues.compactMap { $0 as? ResidueType }

        guard typedResidues.count == newResidues.count else {
            return
        }

        insertResidues(typedResidues, at: location)
    }

    mutating func removeResidue(at location: Int) {
        guard residues.indices.contains(location) else {
            return
        }

        residues.remove(at: location)
    }

    mutating func removeResidues(in range: Range<Int>) {
        guard range.lowerBound >= residues.startIndex,
              range.upperBound <= residues.endIndex
        else {
            return
        }

        residues.removeSubrange(range)
    }

    mutating func replaceResidue(at location: Int, with residue: ResidueType) {
        guard residues.indices.contains(location) else {
            return
        }

        residues[location] = residue
    }

    mutating func replaceResidue(at location: Int, with residue: any Residue) {
        guard let residue = residue as? ResidueType else {
            return
        }

        replaceResidue(at: location, with: residue)
    }
}

public extension Chain {
    // Sequence domain logic: one-based residue positions

    /// Returns the sequence contained within a one-based, inclusive residue range.
    ///
    /// Example:
    /// `sequenceString == "MKWVTFISLL"` and `chainRange == 4...6`
    /// returns `"VTF"`.
    func subSequence(chainRange: ChainRange) -> String {
        precondition(
            chainRange.lowerBound >= 1,
            "ChainRange is one-based; the lower bound must be at least 1."
        )

        precondition(
            chainRange.upperBound <= sequenceString.count,
            "ChainRange exceeds the sequence length."
        )

        let lowerIndex = sequenceString.index(
            sequenceString.startIndex,
            offsetBy: chainRange.lowerBound - 1
        )

        let upperIndex = sequenceString.index(
            sequenceString.startIndex,
            offsetBy: chainRange.upperBound
        )

        return String(sequenceString[lowerIndex ..< upperIndex])
    }

    func subChain(chainRange: ChainRange) -> Self {
        let validRange = chainRange.clamped(
            toSequenceLength: residues.count
        )

        guard
            validRange.isValidChainRange,
            let arrayRange = validRange.zeroBasedArrayRange
        else {
            return Self(
                residues: []
            )
        }

        let newResidues = Array(
            residues[arrayRange]
        )

        var subChain = Self(
            residues: newResidues
        )

        subChain.adducts = adducts

        return subChain
    }

    func removing(_ chainRange: ChainRange) -> Self {
        let validRange = chainRange.clamped(
            toSequenceLength: residues.count
        )

        guard
            validRange.isValidChainRange,
            let arrayRange = validRange.zeroBasedArrayRange
        else {
            return Self(
                residues: residues
            )
        }

        var newResidues = residues
        newResidues.removeSubrange(arrayRange)

        var subChain = Self(
            residues: newResidues
        )

        subChain.adducts = adducts

        return subChain
    }

    func residueLocations(with identifiers: Set<String>) -> [Int] {
        var locations: [Int] = []
        locations.reserveCapacity(residues.count)

        for index in residues.indices {
            if identifiers.contains(residues[index].identifier) {
                locations.append(index)
            }
        }

        return locations
    }
}

public extension Chain {
    mutating func setTermini(nTerm: Modification, cTerm: Modification) {
        nTerminal = nTerm
        cTerminal = cTerm
    }

    func allowedModifications(at location: Int) -> [Modification]? {
        if let residue = residue(at: location) {
            return residue.allowedModifications()
        }

        return nil
    }

    func getModifications() -> [Modification] {
        var result: [Modification] = []

        for residue in residues {
            if let mod = residue.modification {
                result.append(mod)
            }
        }

        return result
    }

    func modification(at location: Int) -> Modification? {
        residue(at: location)?.modification
    }

    mutating func setModifcations(_ mods: [LocalizedModification]) {
        for mod in mods {
            addModification(mod)
        }
    }

    mutating func addModification(_ mod: LocalizedModification) {
        if var r = residue(at: mod.location) {
            r.setModification(mod.modification)
            residues[mod.location] = r
        }
    }

    mutating func removeModification(at location: Int) {
        if var r = residue(at: location) {
            r.removeModification()
            residues[location] = r
        }
    }

    mutating func removeModification(mod: LocalizedModification) {
        if var r = residue(at: mod.location) {
            r.removeModification()
            residues[mod.location] = r
        }
    }

    mutating func modifyResidues(for identifier: String, with modification: Modification) {
        for index in residues.indices {
            if residues[index].identifier == identifier {
                residues[index].setModification(modification)
            }
        }
    }

    mutating func removeModifications(for identifier: String) {
        for index in residues.indices {
            if residues[index].identifier == identifier {
                residues[index].removeModification()
            }
        }
    }
}
