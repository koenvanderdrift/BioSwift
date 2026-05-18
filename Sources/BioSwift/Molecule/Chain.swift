//
//  Chain.swift
//  BioSwift
//
//  Created by Koen van der Drift on 5/22/17.
//  Copyright © 2017 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

public typealias ChainRange = ClosedRange<Int>
public let zeroChainRange: ChainRange = 0 ... 0
public let zeroNSRange = NSMakeRange(NSNotFound, 0)

public extension ChainRange {
    var fromOneBased: ChainRange {
        lowerBound - 1 ... upperBound - 1
    }

    var toOneBased: ChainRange {
        lowerBound + 1 ... upperBound + 1
    }

    var length: Int {
        upperBound - lowerBound + 1
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

public protocol Chain: Codable {
    associatedtype ResidueType: Residue

    var name: String { get set }
    var residues: [ResidueType] { get set }
    var modifications: [LocalizedModification] { get set }
    var nTerminal: Modification { get set }
    var cTerminal: Modification { get set }
    var adducts: [Adduct] { get set }
    var range: ChainRange { get set }

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
}

public extension Chain {
    func countAllResidues() -> NSCountedSet {
        NSCountedSet(array: residues)
    }

    func countOneResidue(with identifier: String) -> Int {
        return residues
            .map { $0.oneLetterCode }
            .reduce(0) { $1 == identifier ? $0 + 1 : $0 }
    }

    mutating func insertResidue(_ residue: any Residue, at location: Int) {
        if let r = residue as? Self.ResidueType {
            residues.insert(r, at: location)
        }
    }

    mutating func insertResidues(_ newResidues: [any Residue], at location: Int) {
        if let r = newResidues as? [Self.ResidueType] {
            residues.insert(contentsOf: r, at: location)
        }
    }

    mutating func removeResidue(at location: Int) {
        residues.remove(at: location)
    }

    mutating func removeResidues(at _: Int) {
        // TODO:
    }

    mutating func replaceResidue(at location: Int, with residue: any Residue) {
        if let r = residue as? Self.ResidueType {
            residues[location] = r
        }
    }

    mutating func update(with sequence: String, in range: NSRange, changeInLength: Int) {
        if sequence == sequenceString {
            return
        }

        switch changeInLength {
        case Int.min ..< 0:
            let subRange = range.location ..< range.location - changeInLength
            residues.removeSubrange(subRange)

        case 0 ..< Int.max:
            let subRange = range.location ..< range.location + changeInLength
            let s = String(sequence[subRange])

            let newResidues = createResidues(from: s)
            residues.insert(contentsOf: newResidues, at: range.location)

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

        sub.range = range

        return sub
    }

    func subChain(with range: NSRange) -> Self? {
        subChain(with: range.chainRange())
    }

    func subChain(from: Int, to: Int) -> Self? {
        guard from < numberOfResidues, to >= from else { return nil }

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

    mutating func removeModification(mod: LocalizedModification) {
        if var r = residue(at: mod.location) {
            r.removeModification()
            residues[mod.location] = r
        }
    }

    func modification(at location: Int) -> Modification? {
        residue(at: location)?.modification
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
