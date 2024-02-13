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

public struct Chain<T: Residue>: Structure {
    public var rangeInParent: ChainRange = zeroChainRange

    public var name: String = ""
    public var adducts: [Adduct] = []

    public var residues: [T] = []
    public var termini: (first: Modification, last: Modification)? = (nTermModification, cTermModification)
    public var modifications: [LocalizedModification] = [] // TODO: do we need LocalizedModification?

    public var fragmentType: PeptideFragmentType = .undefined
    public var index: Int = -1

    init(sequence: String) {
        self.residues = createResidues(from: sequence)
    }

    init(residues: [T]) {
        self.residues = residues
    }
}

extension Chain {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.sequenceString == rhs.sequenceString && lhs.name == rhs.name
    }

    public var masses: MassContainer {
        mass(of: residues) + modificationMasses() + terminalMasses()
    }

    public var formula: Formula {
        var f = Formula(residues.reduce("") { $0 + $1.formula.formulaString })

        if let termini {
            f += termini.first.formula + termini.last.formula
        } else {
            f += water.formula
        }

        return f
    }

    var sequenceString: String {
        residues.map(\.identifier).joined()
    }

    var sequenceLength: Int {
        sequenceString.count
    }

    var symbolSequence: [Symbol] {
        residues // TODO: Fix me
    }

    var symbolSet: SymbolSet? {
        SymbolSet(array: symbolSequence)
    }

    func symbol(at index: Int) -> Symbol? {
        symbolSequence[index]
    }

    func residue(at index: Int) -> Residue? {
        residues[index]
    }

    func numberOfResidues() -> Int {
        residues.count
    }

    func createResidues(from string: String) -> [T] {
        string.compactMap { char in
            aminoAcidLibrary.first(where: { $0.identifier == String(char) }) as? T // TODO: don't hardcode library
        }
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

    func residueLocations(with identifiers: [String]) -> [Int] {
        let result = identifiers.map { i in
            residues.indices.filter { (residues[$0].identifier) == i }
        }

        return result.flatMap { $0 }
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
            if let mod = termini?.first {
                sub.termini?.first = mod
            }
        }

        if basedRange.upperBound == numberOfResidues() {
            if let mod = termini?.last {
                sub.termini?.last = mod
            }
        }

        return sub
    }

    func subChain(with range: ChainRange) -> Self? {
        guard let residues = residueChain(with: range) else { return nil }

        var sub = Self(residues: residues)
        sub.termini = termini
        sub.adducts = adducts

        if range.lowerBound == 0 {
            if let mod = termini?.first {
                sub.termini?.first = mod
            }
        }

        if range.upperBound == numberOfResidues() {
            if let mod = termini?.last {
                sub.termini?.last = mod
            }
        }

        sub.rangeInParent = range

        return sub
    }

    func subChain(with range: NSRange) -> Self? {
        subChain(with: range.chainRange())
    }

    func subChain(from: Int, to: Int) -> Self? {
        guard from < numberOfResidues(), to >= from else { return nil }

        return subChain(with: from ... to)
    }

    func residueChain(with range: ChainRange) -> [T]? {
        guard range != zeroChainRange else { return nil }

        return Array(residues[range])
    }

    func residueChain(with range: NSRange) -> [T]? {
        residueChain(with: range.chainRange())
    }

    func residueChain(from: Int, to: Int) -> [T]? {
        guard from < numberOfResidues(), to >= from else { return nil }

        return residueChain(with: from ... to)
    }

    mutating func setTermini(first: Modification, last: Modification) {
        termini = (first: first, last: last)
    }
}

extension Chain {
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
