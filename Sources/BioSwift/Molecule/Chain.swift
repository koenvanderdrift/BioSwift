//
//  Chain.swift
//  BioSwift
//
//  Created by Koen van der Drift on 5/22/17.
//  Copyright © 2017 - 2024 Koen van der Drift. All rights reserved.
//

import Foundation

public typealias ChainRange = ClosedRange<Int>
public let zeroChainRange: ChainRange = -1 ... 0
public let zeroNSRange = NSMakeRange(NSNotFound, 0)

public extension ChainRange {
    var fromOneBased: ChainRange {
        lowerBound - 1 ... upperBound - 1
    }

    var toOneBased: ChainRange {
        lowerBound + 1 ... upperBound + 1
    }
}

public extension NSRange {
    init(from range: ChainRange) {
        self = NSMakeRange(range.lowerBound, range.upperBound - range.lowerBound + 1)
    }

    func chainRange() -> ChainRange {
        guard location != NSNotFound, length > 0 else { return zeroChainRange }

        return lowerBound ... upperBound - 1
    }
}

// https://medium.com/swift2go/mastering-generics-with-protocols-the-specification-pattern-5e2e303af4ca

public protocol Chain {
    associatedtype T: Residue

    var name: String { get set }
    var residues: [T] { get set }
    var modifications: [LocalizedModification] { get set }
    var nTerminal: Modification { get set }
    var cTerminal: Modification { get set }
    var adducts: [Adduct] { get set }
    var rangeInParent: ChainRange { get set }
    var library: [T] { get set }

    init(sequence: String)
    init(residues: [T])

    func createResidues(from string: String) -> [T]
}

public extension Chain {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.sequenceString == rhs.sequenceString && lhs.name == rhs.name
    }

    var formula: Formula {
        var f = Formula(residues.reduce("") { $0 + $1.formula.formulaString })

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
        residues as? [any Symbol] ?? [] // TODO: Fix me
    }

    var symbolSet: SymbolSet? {
        SymbolSet(array: symbolSequence)
    }

    func symbol(at index: Int) -> Symbol? {
        symbolSequence[index]
    }

    func residue(at index: Int) -> T? {
        residues[index]
    }

    var numberOfResidues: Int {
        residues.count
    }
}

public extension Chain {
    func countAllResidues() -> NSCountedSet {
        NSCountedSet(array: residues)
    }

    mutating func replaceResidue(at location: Int, with residue: any Residue) {
        if let r = residue as? Self.T {
            residues[location] = r
        }
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

    func subChain(removing range: ChainRange) -> Self? {
        // xxxx - ++++++++++++
        // ++ - xxxx - +++++++
        // ++++++++++++ - xxxx

        let subResidues = residues.indices.compactMap { range ~= $0 ? nil : residues[$0] }

        var sub = Self(residues: subResidues)
        sub.nTerminal = nTerminal
        sub.cTerminal = cTerminal
        sub.adducts = adducts

//        if range.lowerBound == 0 {
//            if let mod = termini?.first {
//                sub.termini?.first = mod
//            }
//        }
//
//        if range.upperBound == numberOfResidues {
//            if let mod = termini?.last {
//                sub.termini?.last = mod
//            }
//        }

        return sub
    }

    func subChain(with range: ChainRange) -> Self? {
        guard let subResidues = residueChain(with: range) else { return nil }

        var sub = Self(residues: subResidues)
        sub.nTerminal = nTerminal
        sub.cTerminal = cTerminal
        sub.adducts = adducts

//        if range.lowerBound == 0 {
//            if let mod = termini?.first {
//                sub.termini?.first = mod
//            }
//        }
//
//        if range.upperBound == numberOfResidues {
//            if let mod = termini?.last {
//                sub.termini?.last = mod
//            }
//        }

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

    func residueChain(with range: ChainRange) -> [T]? {
        guard range != zeroChainRange else { return nil }

        return Array(residues[range])
    }

    func residueChain(with range: NSRange) -> [T]? {
        residueChain(with: range.chainRange())
    }

    func residueChain(from: Int, to: Int) -> [T]? {
        guard from < numberOfResidues, to >= from else { return nil }

        return residueChain(with: from ... to)
    }

    func residueLocations(with identifiers: [String]) -> [Int] {
        let result = identifiers.map { i in
            residues.indices.filter { (residues[$0].identifier) == i }
        }

        return result.flatMap { $0 }
    }

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

    func modification(at location: Int) -> Modification? {
        residue(at: location)?.modification
    }
}
