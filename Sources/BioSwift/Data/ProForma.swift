//
//  ProForma.swift
//  BioSwift
//

import Foundation

/// The location of a modification in a linear ProForma peptidoform.
public enum ProFormaModificationLocation: Hashable, Codable, Sendable {
    case nTerminal
    case residue(Int)
    case cTerminal
}

/// A single, localized ProForma modification tag.
///
/// `value` is retained verbatim (without brackets), allowing names, controlled-vocabulary
/// accessions, formulas, glycan compositions, and signed mass shifts to round-trip without
/// forcing them into a chemical model prematurely.
public struct ProFormaModification: Hashable, Codable, Sendable {
    public let value: String
    public let location: ProFormaModificationLocation

    public init(value: String, location: ProFormaModificationLocation) {
        self.value = value
        self.location = location
    }
}

/// The standards-core subset of a ProForma peptidoform supported by BioSwift.
public struct ProFormaPeptidoform: Hashable, Codable, Sendable, CustomStringConvertible {
    public let sequence: String
    public let modifications: [ProFormaModification]
    public let charge: Int?

    public init(
        sequence: String,
        modifications: [ProFormaModification] = [],
        charge: Int? = nil
    ) throws {
        guard !sequence.isEmpty else { throw ProFormaError.emptySequence }
        guard sequence.allSatisfy({ $0.isASCII && $0.isLetter && $0.isUppercase }) else {
            throw ProFormaError.invalidSequence(sequence)
        }
        if let charge, charge <= 0 { throw ProFormaError.invalidCharge(charge) }
        for modification in modifications {
            guard !modification.value.isEmpty else { throw ProFormaError.emptyModification }
            if case .residue(let index) = modification.location {
                guard index >= 0, index < sequence.count else {
                    throw ProFormaError.invalidResidueIndex(index)
                }
            }
        }
        self.sequence = sequence
        self.modifications = modifications
        self.charge = charge
    }

    public var proFormaString: String {
        var result = ""
        for modification in modifications where modification.location == .nTerminal {
            result += "[\(modification.value)]"
        }
        if modifications.contains(where: { $0.location == .nTerminal }) { result += "-" }

        for (index, residue) in sequence.enumerated() {
            result.append(residue)
            for modification in modifications where modification.location == .residue(index) {
                result += "[\(modification.value)]"
            }
        }

        let cTerminal = modifications.filter { $0.location == .cTerminal }
        if !cTerminal.isEmpty {
            result += "-"
            for modification in cTerminal { result += "[\(modification.value)]" }
        }
        if let charge { result += "/\(charge)" }
        return result
    }

    public var description: String { proFormaString }

    /// Creates a BioSwift peptide after resolving each ProForma tag to a chemical modification.
    public func peptide(
        name: String = "",
        resolvingWith resolver: (ProFormaModification) throws -> Modification
    ) throws -> Peptide {
        var peptide = try Peptide(sequence: sequence, name: name)
        for annotation in modifications {
            let modification = try resolver(annotation)
            switch annotation.location {
            case .nTerminal: peptide.nTerminal = modification
            case .residue(let index): try peptide.addModification(modification, at: index)
            case .cTerminal: peptide.cTerminal = modification
            }
        }
        return peptide
    }
}

public enum ProFormaError: Error, Equatable, Sendable, LocalizedError {
    case emptySequence
    case invalidSequence(String)
    case emptyModification
    case unterminatedModification
    case misplacedModification
    case invalidCharge(Int)
    case invalidChargeText(String)
    case invalidResidueIndex(Int)
    case unsupportedFeature(String)

    public var errorDescription: String? {
        switch self {
        case .emptySequence: "A ProForma sequence cannot be empty."
        case .invalidSequence(let value): "Invalid ProForma amino-acid sequence: \(value)."
        case .emptyModification: "A ProForma modification tag cannot be empty."
        case .unterminatedModification: "The ProForma modification tag is not terminated."
        case .misplacedModification: "The ProForma modification is not attached to a residue or terminus."
        case .invalidCharge(let charge): "ProForma charge must be positive; received \(charge)."
        case .invalidChargeText(let value): "Invalid ProForma charge: \(value)."
        case .invalidResidueIndex(let index): "Invalid ProForma residue index: \(index)."
        case .unsupportedFeature(let feature): "This ProForma feature is not yet supported: \(feature)."
        }
    }
}

/// Parses BioSwift's standards-core ProForma subset: one linear sequence, localized and
/// terminal bracket modifications, and an optional positive charge.
public struct ProFormaParser: Sendable {
    public init() {}

    public func parse(_ text: String) throws -> ProFormaPeptidoform {
        let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { throw ProFormaError.emptySequence }

        for marker in ["{", "}", "<", ">", "?", "(", ")", "#"] where input.contains(marker) {
            throw ProFormaError.unsupportedFeature("syntax containing '\(marker)'")
        }

        let (body, charge) = try splitCharge(input)
        var sequence = ""
        var modifications: [ProFormaModification] = []
        var index = body.startIndex

        while index < body.endIndex, body[index] == "[" {
            let (value, next) = try readTag(in: body, from: index)
            modifications.append(.init(value: value, location: .nTerminal))
            index = next
        }
        if !modifications.isEmpty {
            guard index < body.endIndex, body[index] == "-" else {
                throw ProFormaError.misplacedModification
            }
            index = body.index(after: index)
        }

        var residueIndex = -1
        while index < body.endIndex {
            let character = body[index]
            if character == "-" {
                index = body.index(after: index)
                guard index < body.endIndex else { throw ProFormaError.misplacedModification }
                while index < body.endIndex {
                    guard body[index] == "[" else { throw ProFormaError.misplacedModification }
                    let (value, next) = try readTag(in: body, from: index)
                    modifications.append(.init(value: value, location: .cTerminal))
                    index = next
                }
                break
            }
            if character == "[" {
                guard residueIndex >= 0 else { throw ProFormaError.misplacedModification }
                let (value, next) = try readTag(in: body, from: index)
                modifications.append(.init(value: value, location: .residue(residueIndex)))
                index = next
                continue
            }
            guard character.isASCII, character.isLetter, character.isUppercase else {
                if character == "+" { throw ProFormaError.unsupportedFeature("multiple peptidoforms") }
                if character == "|" { throw ProFormaError.unsupportedFeature("multi-valued modification tags") }
                throw ProFormaError.invalidSequence(String(body))
            }
            sequence.append(character)
            residueIndex += 1
            index = body.index(after: index)
        }

        return try ProFormaPeptidoform(sequence: sequence, modifications: modifications, charge: charge)
    }

    private func splitCharge(_ input: String) throws -> (String, Int?) {
        guard let slash = input.lastIndex(of: "/") else { return (input, nil) }
        let value = String(input[input.index(after: slash)...])
        guard let charge = Int(value) else { throw ProFormaError.invalidChargeText(value) }
        guard charge > 0 else { throw ProFormaError.invalidCharge(charge) }
        return (String(input[..<slash]), charge)
    }

    private func readTag(in input: String, from opening: String.Index) throws -> (String, String.Index) {
        guard let closing = input[input.index(after: opening)...].firstIndex(of: "]") else {
            throw ProFormaError.unterminatedModification
        }
        let value = String(input[input.index(after: opening)..<closing])
        guard !value.isEmpty else { throw ProFormaError.emptyModification }
        if value.contains("|") {
            throw ProFormaError.unsupportedFeature("multi-valued modification tags")
        }
        return (value, input.index(after: closing))
    }
}
