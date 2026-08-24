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

    var name: String {
        get set
    }

    var residues: [ResidueType] {
        get set
    }

    var adducts: [Adduct] {
        get set
    }

    var range: Range<Int> {
        get set
    }

    var parentLength: Int {
        get set
    }

    init(residues: [ResidueType])
}

public protocol AminoAcidChain: Chain, Structure where ResidueType == AminoAcid {
    var nTerminal: Modification {
        get set
    }

    var cTerminal: Modification {
        get set
    }
}

extension Chain {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.sequenceString == rhs.sequenceString && lhs.name == rhs.name
    }

    public var sequenceString: String {
        residues.map(\.identifier).joined()
    }

    public var sequenceLength: Int {
        numberOfResidues
    }

    public var symbolSequence: [Symbol] {
        residues
    }

    public var symbolSet: SymbolSet? {
        SymbolSet(array: symbolSequence)
    }

    public func symbol(at index: Int) -> Symbol? {
        guard symbolSequence.indices.contains(index) else {
            return nil
        }

        return symbolSequence[index]
    }

    public func residue(at index: Int) -> ResidueType? {
        guard residues.indices.contains(index) else {
            return nil
        }

        return residues[index]
    }

    public var numberOfResidues: Int {
        residues.count
    }

    public func countAllResidues() -> NSCountedSet {
        NSCountedSet(array: residues)
    }

    public func countOneResidue(with identifier: String) -> Int {
        var count = 0

        for residue in residues where residue.oneLetterCode == identifier {
            count += 1
        }

        return count
    }

    func residueMasses() -> MassContainer {
        residueMasses(in: residues.startIndex..<residues.endIndex)
    }

    func residueMasses(in range: Range<Int>) -> MassContainer {
        let validRange = range.clamped(toSequenceLength: residues.count)

        guard validRange.isValidRange, !validRange.isEmpty else {
            return zeroMass
        }

        return residues[validRange].reduce(zeroMass) {
            $0 + $1.masses
        }
    }
}

extension AminoAcidChain {
    func aminoAcidResidueMasses() -> MassContainer {
        aminoAcidResidueMasses(in: residues.startIndex..<residues.endIndex)
    }

    func aminoAcidResidueMasses(in range: Range<Int>) -> MassContainer {
        let validRange = range.clamped(toSequenceLength: residues.count)

        guard validRange.isValidRange, !validRange.isEmpty else {
            return zeroMass
        }

        var residueCounts: [String: Int] = [:]
        var unmodifiedMassesByResidue: [String: MassContainer] = [:]
        var modificationMasses = zeroMass

        for residue in residues[validRange] {
            let identifier = residue.oneLetterCode
            residueCounts[identifier, default: 0] += 1

            if unmodifiedMassesByResidue[identifier] == nil {
                unmodifiedMassesByResidue[identifier] = residue.formula.masses
            }

            if let modification = residue.modification {
                modificationMasses += modification.masses
            }
        }

        return residueCounts.reduce(modificationMasses) { result, item in
            let (identifier, count) = item
            guard let residueMasses = unmodifiedMassesByResidue[identifier] else {
                return result
            }

            return result + (count * residueMasses)
        }
    }

    public var formula: Formula {
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

    func terminalMasses() -> MassContainer {
        nTerminal.masses + cTerminal.masses
    }

    public mutating func setTermini(nTerm: Modification, cTerm: Modification) {
        nTerminal = nTerm
        cTerminal = cTerm
    }
}

extension Chain where ResidueType == AminoAcid {
    public func hydropathyValues(for hydropathyType: String, hydropathyReferences: HydropathyReferences = HydropathyReferenceDefaults.bundled) -> [Double] {
        let values = Hydropathy(residues: residues, hydropathyReferences: hydropathyReferences).hydropathyValues(for: hydropathyType)

        return residues.compactMap {
            values[$0.oneLetterCode]
        }
    }

    public func isoelectricPoint(
        hydropathyReferences: HydropathyReferences = HydropathyReferenceDefaults.bundled) -> Double {
        Hydropathy.isoElectricPoint(for: residues, hydropathyReferences: hydropathyReferences)
    }
}

extension Chain {
    public mutating func insertResidue(_ residue: ResidueType, at location: Int) {
        guard residues.indices.contains(location) || location == residues.endIndex else {
            return
        }

        residues.insert(residue, at: location)
    }

    public mutating func insertResidue(_ residue: any Residue, at location: Int) {
        guard let residue = residue as? ResidueType else {
            return
        }

        insertResidue(residue, at: location)
    }

    public mutating func insertResidues(_ newResidues: [ResidueType], at location: Int) {
        guard location >= residues.startIndex, location <= residues.endIndex else {
            return
        }

        residues.insert(contentsOf: newResidues, at: location)
    }

    public mutating func insertResidues(_ newResidues: [any Residue], at location: Int) {
        let typedResidues = newResidues.compactMap {
            $0 as? ResidueType
        }

        guard typedResidues.count == newResidues.count else {
            return
        }

        insertResidues(typedResidues, at: location)
    }

    public mutating func removeResidue(at location: Int) {
        guard residues.indices.contains(location) else {
            return
        }

        residues.remove(at: location)
    }

    public mutating func removeResidues(in range: Range<Int>) {
        guard range.lowerBound >= residues.startIndex, range.upperBound <= residues.endIndex else {
            return
        }

        residues.removeSubrange(range)
    }

    public mutating func replaceResidue(at location: Int, with residue: ResidueType) {
        guard residues.indices.contains(location) else {
            return
        }

        residues[location] = residue
    }

    public mutating func replaceResidue(at location: Int, with residue: any Residue) {
        guard let residue = residue as? ResidueType else {
            return
        }

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
        let validRange = range.clamped(toSequenceLength: sequenceString.count)

        guard validRange.isValidRange, !validRange.isEmpty else {
            return ""
        }

        let lowerIndex = sequenceString.index(sequenceString.startIndex, offsetBy: validRange.lowerBound)
        let upperIndex = sequenceString.index(sequenceString.startIndex, offsetBy: validRange.upperBound)

        return String(sequenceString[lowerIndex..<upperIndex])
    }

    public func subChain(range: Range<Int>) -> Self {
        let validRange = range.clamped(toSequenceLength: residues.count)

        guard validRange.isValidRange else {
            return Self(residues: [])
        }

        let newResidues = Array(residues[validRange])

        var subChain = Self(residues: newResidues)

        subChain.range = validRange

        return subChain
    }

    public func removing(_ range: Range<Int>) -> Self {
        let validRange = range.clamped(toSequenceLength: residues.count)

        guard validRange.isValidRange else {
            return Self(residues: residues)
        }

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
            if identifiers.contains(residues[index].identifier) {
                locations.append(index)
            }
        }

        return locations
    }

    public func searchSequence(searchString: String) -> [Self] {
        var result: [Self] = []

        for range in sequenceString.sequenceRanges(of: searchString) {
            var sub = subChain(range: range)
            sub.range = range

            result.append(sub)
        }

        return result
    }

    public func searchMass(params: MassSearchParameters) -> [Range<Int>] where Self: Ionizable {
        // prefixValues[i] is the sum of items[0..<i].
        var prefixValues = Array(repeating: zeroMass, count: residues.count + 1)

        for index in residues.indices {
            prefixValues[index + 1] = prefixValues[index] + residues[index].masses
        }

        var candidateCount = 0

        func massContainer(from start: Int, to end: Int) -> MassContainer {
            let itemSum = prefixValues[end] - prefixValues[start]

            candidateCount += 1

            return (water.masses + itemSum).moverz(for: params.charge)
        }

        let count = residues.count
        let acceptableRange = params.massRange

        var results: [Range<Int>] = []

        // First end whose value is not below the acceptable range.
        var firstAcceptableEnd = 1

        // First end whose value is above the acceptable range.
        var firstAboveEnd = 1

        for start in 0..<count {
            firstAcceptableEnd = max(firstAcceptableEnd, start + 1)

            while firstAcceptableEnd <= count {
                if !acceptableRange.isBelow(
                    massContainer(from: start, to: firstAcceptableEnd), for: params.massType)
                {
                    break
                }

                firstAcceptableEnd += 1
            }

            // No range beginning here can reach the lower bound.
            // With nonnegative contributions, no later start can either.
            guard firstAcceptableEnd <= count else {
                break
            }

            firstAboveEnd = max(firstAboveEnd, firstAcceptableEnd)

            while firstAboveEnd <= count {
                if acceptableRange.isAbove(
                    massContainer(from: start, to: firstAboveEnd), for: params.massType)
                {
                    break
                }

                firstAboveEnd += 1
            }

            // firstAboveEnd may be count + 1. That intentionally includes
            // a valid range whose exclusive upper bound is `count`.
            for end in firstAcceptableEnd..<firstAboveEnd {
                results.append(start..<end)
            }
        }

        BioSwiftDiagnostics.log("Candidates tested: \(candidateCount)")

        return results
    }

    public func searchMassBruteForce(params: MassSearchParameters) -> [Self] where Self: Ionizable {
        var result: [Self] = []

        for start in residues.indices {
            for end in (start + 1)..<residues.count {
                let subRange = start..<end
                var sub = subChain(range: subRange)

                sub.range = subRange
                sub.setAdducts(type: protonAdduct, count: params.charge)

                let moverz = sub.massOverCharge()

                if params.massRange.upperLimit(excludes: moverz) {
                    break
                }

                if params.massRange.contains(moverz, for: params.massType) {
                    if (start..<end).isValidRange {
                        result.append(sub)
                    }
                }
            }
        }

        return result
    }

    public func digest(using enzyme: Enzyme, with missedCleavages: Int = 0) -> [Self] {
        let regex = enzyme.regex()
        BioSwiftDiagnostics.log(regex)

        return digest(using: regex, with: missedCleavages)
    }

    public func digest(using regex: String, with missedCleavages: Int = 0) -> [Self] {
        let matches = cleavageSites(for: regex)  // site is first residue of new peptide 0-based

        let baseRanges: [Range<Int>] = zip(matches, matches.dropFirst()).map { start, end in
            start..<end
        }

        var ranges = baseRanges
        let chunksToCombine = missedCleavages + 1

        if missedCleavages > 0, chunksToCombine <= baseRanges.count {
            for startIndex in 0...(baseRanges.count - chunksToCombine) {
                let endIndex = startIndex + chunksToCombine - 1
                ranges.append(baseRanges[startIndex].lowerBound..<baseRanges[endIndex].upperBound)
            }
        }

        ranges.sort {
            if $0.lowerBound == $1.lowerBound {
                return $0.upperBound < $1.upperBound
            }

            return $0.lowerBound < $1.lowerBound
        }

        var chains = [Self]()

        for range in ranges {
            let validRange = range.clamped(toSequenceLength: residues.count)

            guard validRange.isValidRange else {
                continue
            }

            var digestedChain = subChain(range: validRange)
            digestedChain.range = validRange
            digestedChain.parentLength = sequenceLength

            chains.append(digestedChain)
        }

        return chains
    }

    func cleavageSites(for regex: String) -> [Int] {
        do {
            let matches = try sequenceString.matches(for: regex).map(\.range.location)

            let validatedSites = Array(
                Set(matches.filter {
                    $0 > 0 && $0 < residues.count
                })
            ).sorted()

            return [0] + validatedSites + [residues.count]
        } catch {
            BioSwiftDiagnostics.log(error.localizedDescription)
        }

        return []
    }
}

extension Chain {
    public func allowedModifications(at location: Int) -> [Modification]? {
        if let residue = residue(at: location) {
            return residue.allowedModifications()
        }

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
        guard residues.indices.contains(loc) else {
            return
        }

        residues[loc].modification = mod
    }

    public mutating func removeModification(at loc: Int) {
        guard residues.indices.contains(loc) else {
            return
        }

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
            if residues[index].identifier == identifier {
                residues[index].modification = nil
            }
        }
    }
}
