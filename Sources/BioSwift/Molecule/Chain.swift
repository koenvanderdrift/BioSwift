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

public protocol Chain: ChargedMass {
    var residues: [Residue] { get set }
    var rangeInParent: ChainRange { get set }
    var name: String { get set }
    var termini: (first: Modification, last: Modification)? { get set }
    var modifications: [LocalizedModification] { get set }
    var adducts: [Adduct] { get set }
    
    init(sequence: String)
    init(residues: [Residue])
    
    func createResidues(from string: String) -> [Residue]
}

public extension Chain {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.sequenceString == rhs.sequenceString && lhs.name == rhs.name
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

    var sequenceString: String {
        residues.map(\.identifier).joined()
    }

    var sequenceLength: Int {
        numberOfResidues
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

    var numberOfResidues: Int {
        residues.count
    }
}

public extension Chain {
    var masses: MassContainer {
        calculateMasses()
    }

    func calculateMasses() -> MassContainer {
        mass(of: residues) + modificationMasses() + terminalMasses()
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

        if basedRange.upperBound == numberOfResidues {
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

        if range.upperBound == numberOfResidues {
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
        guard from < numberOfResidues, to >= from else { return nil }

        return subChain(with: from ... to)
    }

    func residueChain(with range: ChainRange) -> [Residue]? {
        guard range != zeroChainRange else { return nil }

        return Array(residues[range])
    }

    func residueChain(with range: NSRange) -> [Residue]? {
        residueChain(with: range.chainRange())
    }

    func residueChain(from: Int, to: Int) -> [Residue]? {
        guard from < numberOfResidues, to >= from else { return nil }

        return residueChain(with: from ... to)
    }

    func residueLocations(with identifiers: [String]) -> [Int] {
        let result = identifiers.map { i in
            residues.indices.filter { (residues[$0].identifier) == i }
        }

        return result.flatMap { $0 }
    }

    mutating func setTermini(first: Modification, last: Modification) {
        termini = (first: first, last: last)
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
