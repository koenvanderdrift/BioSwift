//
//  Chain.swift
//  BioSwift
//
//  Created by Koen van der Drift on 5/22/17.
//  Copyright © 2017 - 2026 Koen van der Drift. All rights reserved.
//

import Foundation

// https://medium.com/swift2go/mastering-generics-with-protocols-the-specification-pattern-5e2e303af4ca

/// Chain is a protocol that describes ``Residue`` array
public protocol Chain: Identifiable {
    associatedtype ResidueType: Residue

    var id: UUID {
        get
    }
    
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

/// Errors produced by validated structural edits to a chain.
public enum ChainEditingError: Error, Equatable, Sendable {
    case indexOutOfBounds(index: Int, residueCount: Int)
    case rangeOutOfBounds(range: Range<Int>, residueCount: Int)
    case incompatibleResidueType
}

extension Chain {
    public var charge: Charge {
        adducts.reduce(0) { $0 + $1.charge }
    }

    public mutating func setAdducts(_ adducts: [Adduct]) {
        self.adducts = adducts
    }

    public mutating func setAdducts(type: Adduct, count: Int) {
        setAdducts(Array(repeating: type, count: count))
    }

    public func withAdducts(_ adducts: [Adduct]) -> Self {
        var copy = self
        copy.setAdducts(adducts)
        return copy
    }

    public func withAdducts(type: Adduct, count: Int) -> Self {
        var copy = self
        copy.setAdducts(type: type, count: count)
        return copy
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.sequenceString == rhs.sequenceString && lhs.name == rhs.name
    }

    public var sequenceString: String {
        residues.map(\.identifier).joined()
    }

    public var sequenceLength: Int {
        residueCount
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

    public var residueCount: Int {
        residues.count
    }

    public var residueCounts: NSCountedSet {
        NSCountedSet(array: residues)
    }

    public func residueCount(for identifier: String) -> Int {
        var count = 0

        for residue in residues where residue.oneLetterCode == identifier {
            count += 1
        }

        return count
    }

    func calculatedMasses() -> MassContainer {
        if let ionizable = self as? any Ionizable {
            return ionizable.masses
        }

        if let massRepresentable = self as? any MassRepresentable {
            return massRepresentable.masses
        }

        var masses = residueMasses()
        if let aminoAcidChain = self as? any AminoAcidChain {
            masses += aminoAcidChain.terminalMasses()
        }

        return masses
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

public protocol AminoAcidChain: Chain, Structure where ResidueType == AminoAcid {
    var nTerminal: Modification {
        get set
    }

    var cTerminal: Modification {
        get set
    }
}

extension AminoAcidChain {
    static func createResidues(from sequence: String) -> [AminoAcid] {
        sequence.compactMap {
            AminoAcidReferenceDefaults.bundled.aminoAcid(identifier: String($0))
        }
    }

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
        var countedElements: [ChemicalElement: Int] = [:]

        func add(_ formula: Formula) {
            for (element, count) in formula.countedElements {
                countedElements[element, default: 0] += count
            }
        }

        for residue in residues {
            add(residue.formula)

            if let mod = residue.modification {
                add(mod.formula)
            }
        }

        add(nTerminal.formula)
        add(cTerminal.formula)

        return Formula(with: countedElements)
    }

    func terminalMasses() -> MassContainer {
        nTerminal.masses + cTerminal.masses
    }

    public mutating func setTermini(nTerm: Modification, cTerm: Modification) {
        nTerminal = nTerm
        cTerminal = cTerm
    }

    public func withTermini(nTerm: Modification, cTerm: Modification) -> Self {
        var copy = self
        copy.setTermini(nTerm: nTerm, cTerm: cTerm)
        return copy
    }
}

extension Chain where ResidueType == AminoAcid {
    public func hydrophobicityValues(for hydrophobicityScale: String) -> [Double] {
        let values = HydrophobicityReferenceDefaults.bundled.numericHydrophobicityValues(named: hydrophobicityScale)

        return residues.compactMap {
            values[$0.oneLetterCode]
        }
    }

    public func hydrophobicityValues(for hydrophobicityScale: HydrophobicityScaleName) -> [Double] {
        hydrophobicityValues(for: hydrophobicityScale.rawValue)
    }

    public func hydrophobicityProfile(
        for hydrophobicityScale: String,
        windowSize: Int = 1
    ) -> [HydrophobicityProfilePoint] {
        guard windowSize > 0, windowSize.isMultiple(of: 2) == false, windowSize <= residues.count else {
            return []
        }

        let values = hydrophobicityValues(for: hydrophobicityScale)

        guard values.count == residues.count else {
            return []
        }

        let firstCenterPosition = (Double(windowSize) + 1) / 2

        return values.consecutiveGroups(ofSize: windowSize)
            .enumerated()
            .map { index, window in
                HydrophobicityProfilePoint(
                    position: Double(index) + firstCenterPosition,
                    value: window.reduce(0, +) / Double(windowSize)
                )
            }
    }

    public func hydrophobicityProfile(
        for hydrophobicityScale: HydrophobicityScaleName,
        windowSize: Int = 1
    ) -> [HydrophobicityProfilePoint] {
        hydrophobicityProfile(for: hydrophobicityScale.rawValue, windowSize: windowSize)
    }

    public func isoelectricPoint() -> Double {
        IsoelectricPointCalculator.isoElectricPoint(for: residues)
    }
}

extension AminoAcidChain {
    /// The isoelectric point calculated with free N- and C-termini.
    public var isoElectricPoint: Double {
        isoelectricPoint()
    }

    public func isoelectricPoint(
        nTerminalIonization: TerminalIonization = .free,
        cTerminalIonization: TerminalIonization = .free
    ) -> Double {
        IsoelectricPointCalculator.isoElectricPoint(
            for: residues,
            nTerminal: nTerminalIonization,
            cTerminal: cTerminalIonization
        )
    }
}

extension Chain {
    public mutating func insertResidue(_ residue: ResidueType, at location: Int) throws {
        guard residues.indices.contains(location) || location == residues.endIndex else {
            throw ChainEditingError.indexOutOfBounds(
                index: location,
                residueCount: residues.count
            )
        }

        residues.insert(residue, at: location)
        normalizeEditedSequenceMetadata()
    }

    public mutating func insertResidue(_ residue: any Residue, at location: Int) throws {
        guard let residue = residue as? ResidueType else {
            throw ChainEditingError.incompatibleResidueType
        }

        try insertResidue(residue, at: location)
    }

    public mutating func insertResidues(_ newResidues: [ResidueType], at location: Int) throws {
        guard location >= residues.startIndex, location <= residues.endIndex else {
            throw ChainEditingError.indexOutOfBounds(
                index: location,
                residueCount: residues.count
            )
        }

        guard newResidues.isEmpty == false else {
            return
        }

        residues.insert(contentsOf: newResidues, at: location)
        normalizeEditedSequenceMetadata()
    }

    public mutating func insertResidues(_ newResidues: [any Residue], at location: Int) throws {
        let typedResidues = newResidues.compactMap {
            $0 as? ResidueType
        }

        guard typedResidues.count == newResidues.count else {
            throw ChainEditingError.incompatibleResidueType
        }

        try insertResidues(typedResidues, at: location)
    }

    public mutating func removeResidue(at location: Int) throws {
        guard residues.indices.contains(location) else {
            throw ChainEditingError.indexOutOfBounds(
                index: location,
                residueCount: residues.count
            )
        }

        residues.remove(at: location)
        normalizeEditedSequenceMetadata()
    }

    public mutating func removeResidues(in range: Range<Int>) throws {
        guard range.isValidRange,
            range.lowerBound >= residues.startIndex,
            range.upperBound <= residues.endIndex
        else {
            throw ChainEditingError.rangeOutOfBounds(
                range: range,
                residueCount: residues.count
            )
        }

        guard range.isEmpty == false else {
            return
        }

        residues.removeSubrange(range)
        normalizeEditedSequenceMetadata()
    }

    public mutating func replaceResidue(at location: Int, with residue: ResidueType) throws {
        guard residues.indices.contains(location) else {
            throw ChainEditingError.indexOutOfBounds(
                index: location,
                residueCount: residues.count
            )
        }

        residues[location] = residue
        normalizeEditedSequenceMetadata()
    }

    public mutating func replaceResidue(at location: Int, with residue: any Residue) throws {
        guard let residue = residue as? ResidueType else {
            throw ChainEditingError.incompatibleResidueType
        }

        try replaceResidue(at: location, with: residue)
    }

    public func insertingResidue(_ residue: ResidueType, at location: Int) throws -> Self {
        var copy = self
        try copy.insertResidue(residue, at: location)
        return copy
    }

    public func insertingResidue(_ residue: any Residue, at location: Int) throws -> Self {
        var copy = self
        try copy.insertResidue(residue, at: location)
        return copy
    }

    public func insertingResidues(_ newResidues: [ResidueType], at location: Int) throws -> Self {
        var copy = self
        try copy.insertResidues(newResidues, at: location)
        return copy
    }

    public func insertingResidues(_ newResidues: [any Residue], at location: Int) throws -> Self {
        var copy = self
        try copy.insertResidues(newResidues, at: location)
        return copy
    }

    public func removingResidue(at location: Int) throws -> Self {
        var copy = self
        try copy.removeResidue(at: location)
        return copy
    }

    /// Returns a copy with the residues in a zero-based, half-open range removed.
    ///
    /// This is a structural edit. Conformer-specific state that is not stored on
    /// the removed residues is preserved, including an amino-acid chain's
    /// N- and C-terminal modifications. Removing an endpoint can expose a new
    /// biological terminus, so callers modeling cleavage should explicitly set
    /// its chemistry with ``AminoAcidChain/withTermini(nTerm:cTerm:)``.
    ///
    /// For example, after removing an N-terminal signal peptide:
    ///
    /// ```swift
    /// let matureChain = try precursor
    ///     .removingResidues(in: signalPeptideRange)
    ///     .withTermini(
    ///         nTerm: hydrogenModification,
    ///         cTerm: precursor.cTerminal
    ///     )
    /// ```
    ///
    /// After removing a C-terminal lysine:
    ///
    /// ```swift
    /// let matureChain = try precursor
    ///     .removingResidues(in: lysineRange)
    ///     .withTermini(
    ///         nTerm: precursor.nTerminal,
    ///         cTerm: hydroxylModification
    ///     )
    /// ```
    public func removingResidues(in range: Range<Int>) throws -> Self {
        var copy = self
        try copy.removeResidues(in: range)
        return copy
    }

    public func replacingResidue(at location: Int, with residue: ResidueType) throws -> Self {
        var copy = self
        try copy.replaceResidue(at: location, with: residue)
        return copy
    }

    public func replacingResidue(at location: Int, with residue: any Residue) throws -> Self {
        var copy = self
        try copy.replaceResidue(at: location, with: residue)
        return copy
    }

    private mutating func normalizeEditedSequenceMetadata() {
        range = residues.startIndex..<residues.endIndex
        parentLength = residues.count
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

        subChain.name = name
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

        subChain.name = name
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

    public func searchMass(params: MassSearchParameters) -> [Range<Int>] {
        // prefixValues[i] is the sum of items[0..<i].
        var prefixValues = Array(repeating: zeroMass, count: residues.count + 1)

        for index in residues.indices {
            prefixValues[index + 1] = prefixValues[index] + residues[index].masses
        }

        var candidateCount = 0

        func massContainer(from start: Int, to end: Int) -> MassContainer {
            let itemSum = prefixValues[end] - prefixValues[start]

            candidateCount += 1

            let adducts = Array(repeating: protonAdduct, count: max(0, params.charge))
            return (water.masses + itemSum).applying(adducts: adducts)
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

extension Chain where ResidueType == AminoAcid {
    public func allowedModifications(at location: Int) -> [Modification]? {
        if let residue = residue(at: location) {
            return residue.allowedModifications
        }

        return nil
    }
}

extension Chain {
    public var modifications: [Modification] {
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

    public func addingModification(_ modification: Modification, at location: Int) -> Self {
        var copy = self
        copy.addModification(modification, at: location)
        return copy
    }

    public mutating func removeModification(at loc: Int) {
        guard residues.indices.contains(loc) else {
            return
        }

        residues[loc].modification = nil
    }

    public func removingModification(at location: Int) -> Self {
        var copy = self
        copy.removeModification(at: location)
        return copy
    }

    public mutating func modifyResidues(for identifier: String, with modification: Modification) {
        for index in residues.indices {
            if residues[index].identifier == identifier {
                residues[index].modification = modification
            }
        }
    }

    public func modifyingResidues(
        for identifier: String,
        with modification: Modification
    ) -> Self {
        var copy = self
        copy.modifyResidues(for: identifier, with: modification)
        return copy
    }

    public mutating func removeModifications(for identifier: String) {
        for index in residues.indices {
            if residues[index].identifier == identifier {
                residues[index].modification = nil
            }
        }
    }

    public func removingModifications(for identifier: String) -> Self {
        var copy = self
        copy.removeModifications(for: identifier)
        return copy
    }
}
