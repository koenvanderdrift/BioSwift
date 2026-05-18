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

extension Chain {
    mutating func update(with sequence: String, in range: NSRange, changeInLength: Int) {
        guard range.location >= 0, range.length >= 0 else { return }

        let newCount = range.length
        let oldCount = newCount - changeInLength

        guard oldCount >= 0 else { return }

        let oldStart = range.location
        let oldEnd = oldStart + oldCount

        guard oldStart >= residues.startIndex, oldEnd <= residues.endIndex else { return }

        guard let swiftRange = Range(range, in: sequence) else {
            return
        }

        let newSequencePart = String(sequence[swiftRange])
        let newResidues = createResidues(from: newSequencePart)

        residues.replaceSubrange(oldStart ..< oldEnd, with: newResidues)
    }

    func subChain(removing range: ChainRange) -> Self? {
        // xxxx - ++++++++++++
        // ++ - xxxx - +++++++
        // ++++++++++++ - xxxx

        guard range != zeroChainRange else { return nil }

        guard range.lowerBound >= residues.startIndex, range.upperBound < residues.endIndex else { return nil }

        var subResidues: [ResidueType] = []
        subResidues.reserveCapacity(residues.count - range.count)

        subResidues.append(contentsOf: residues[..<range.lowerBound])

        let afterRemovedRange = range.upperBound + 1

        if afterRemovedRange < residues.endIndex {
            subResidues.append(contentsOf: residues[afterRemovedRange...])
        }

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
        guard let subResidues = residueChainSlice(with: range) else {
            return nil
        }

        var sub = Self(residues: Array(subResidues))

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
        guard from >= residues.startIndex, to < residues.endIndex, to >= from else { return nil }

        return subChain(with: from ... to)
    }

    func residueChainSlice(with range: ChainRange) -> ArraySlice<ResidueType>? {
        guard range != zeroChainRange else { return nil }

        guard range.lowerBound >= residues.startIndex, range.upperBound < residues.endIndex else { return nil }

        return residues[range]
    }

    func residueChain(with range: ChainRange) -> ArraySlice<ResidueType>? {
        guard range != zeroChainRange else { return nil }

        guard range.lowerBound >= residues.startIndex, range.upperBound < residues.endIndex else { return nil }

        return residues[range]
    }

    func residueChain(with range: NSRange) -> ArraySlice<ResidueType>? {
        residueChain(with: range.chainRange())
    }

    func residueChain(from: Int, to: Int) -> ArraySlice<ResidueType>? {
        guard from <= to else { return nil }

        return residueChain(with: from ... to)
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

extension Chain {
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
