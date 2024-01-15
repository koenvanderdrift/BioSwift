//
//  Chain.swift
//  BioSwift
//
//  Created by Koen van der Drift on 5/22/17.
//  Copyright © 2017 Koen van der Drift. All rights reserved.
//

import Foundation

public typealias ChainRange = ClosedRange<Int>

public let zeroChainRange: ChainRange = -1 ... 0
public let zeroNSRange = NSMakeRange(NSNotFound, 0)

public extension NSRange {
    init(from range: ChainRange) {
        self = NSMakeRange(range.lowerBound, range.upperBound - range.lowerBound + 1)
    }

    func chainRange() -> ChainRange {
        guard location != NSNotFound, length > 0 else { return zeroChainRange }

        return lowerBound ... upperBound - 1
    }
}

public protocol RangedChain: Chain {
    var rangeInParent: ChainRange { get set }
}

public protocol Chain: Structure {
    associatedtype ResidueType: Residue

    var symbolLibrary: [Symbol] { get }

    var residues: [ResidueType] { get set }

    var termini: (first: ResidueType, last: ResidueType)? { get set }
    var adducts: [Adduct] { get set }

    var modifications: [LocalizedModification] { get set }

    init(sequence: String)
    init(residues: [ResidueType])
}

public extension Chain {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.sequenceString == rhs.sequenceString && lhs.name == rhs.name
    }

    var symbolSequence: [Symbol] {
        residues
    }

    var sequenceString: String {
        residues.map(\.identifier).joined()
    }

    var formula: Formula {
        var f = Formula(residues.reduce("") { $0 + $1.formula.formulaString })

        if let termini {
            f += termini.first.formula + termini.last.formula
        } else {
            f += water.formula
        }

        return f
    }

    var symbolSet: SymbolSet? {
        SymbolSet(array: symbolSequence)
    }

    mutating func update(with sequence: String, in editedRange: NSRange, changeInLength: Int) {
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

    func createResidues(from string: String) -> [ResidueType] {
        string.compactMap { char in
            symbolLibrary.first(where: { $0.identifier == String(char) }) as? ResidueType
        }
    }

    func symbol(at index: Int) -> Symbol? {
        symbolSequence[index]
    }

    func residue(at index: Int) -> Residue? {
        residues[index]
    }

    func residueLocations(with identifiers: [String]) -> [Int] {
        let result = identifiers.map { i in
            residues.indices.filter { (residues[$0].identifier) == i }
        }

        return result.flatMap { $0 }
    }

    func numberOfResidues() -> Int {
        residues.count
    }

    func subChain(removing range: ChainRange, based: Int = 0) -> Self? {
        // xxxx - ++++++++++++
        // ++ - xxxx - +++++++
        // ++++++++++++ - xxxx

        let lowerBound = range.lowerBound - based
        let upperBound = range.upperBound - based
        let basedRange = lowerBound ... upperBound

        let subResidues = residues.indices.compactMap { basedRange ~= $0 ? nil : residues[$0] }

        var sub = Self(residues: subResidues)
        sub.termini = termini
        sub.adducts = adducts

        if basedRange.lowerBound == 0 {
            sub.termini?.first.modification = termini?.first.modification
        }

        if basedRange.upperBound == numberOfResidues() {
            sub.termini?.last.modification = termini?.last.modification
        }

        return sub
    }

    func subChain(with range: ChainRange) -> Self? {
        guard let residues = residueChain(with: range) else { return nil }

        var sub = Self(residues: residues)
        sub.termini = termini
        sub.adducts = adducts
        
        if range.lowerBound == 0 {
            sub.termini?.first.modification = termini?.first.modification
        }

        if range.upperBound == numberOfResidues() {
            sub.termini?.last.modification = termini?.last.modification
        }

        return sub
    }

    func subChain(with range: NSRange) -> Self? {
        subChain(with: range.chainRange())
    }

    func subChain(from: Int, to: Int) -> Self? {
        guard from < numberOfResidues(), to >= from else { return nil }

        return subChain(with: from ... to)
    }

    func residueChain(with range: ChainRange) -> [ResidueType]? {
        guard range != zeroChainRange else { return nil }

        return Array(residues[range])
    }

    func residueChain(with range: NSRange) -> [ResidueType]? {
        residueChain(with: range.chainRange())
    }

    func residueChain(from: Int, to: Int) -> [ResidueType]? {
        guard from < numberOfResidues(), to >= from else { return nil }

        return residueChain(with: from ... to)
    }

    mutating func setTermini(first: ResidueType, last: ResidueType) {
        termini = (first: first, last: last)
    }

    func modificationMasses() -> MassContainer {
        var result = zeroMass
        
        modifications.forEach {
            result += $0.modification.masses
        }

        return result
    }

    func terminalMasses() -> MassContainer {
        var result = zeroMass

        if let first = termini?.first {
            result += first.masses
        }

        if let last = termini?.last {
            result += last.masses
        }

        return result
    }

    func allowedModifications(at location: Int) -> [Modification]? {
        if let residue = residue(at: location) {
            return residue.allowedModifications()
        }

        return nil
    }

    func getModifications() -> [Modification] {
        var result: [Modification] = []

        residues.forEach {
            if let mod = $0.modification {
                result.append(mod)
            }
        }

        return result
    }

    mutating func setModifcations(_ mods: [LocalizedModification]) {
        mods.forEach {
            addModification($0)
        }
    }

    mutating func addModification(_ mod: LocalizedModification) {
        residues.modifyElement(atIndex: mod.location) { residue in
            residue.setModification(mod.modification)
        }
    }

    mutating func removeModification(at location: Int) {
        residues.modifyElement(atIndex: location) { residue in
            residue.setModification(nil)
        }
    }

    func modification(at location: Int) -> Modification? {
        residue(at: location)?.modification
    }
}
