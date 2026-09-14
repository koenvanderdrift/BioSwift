//
//  PSIMod.swift
//  BioSwift
//
//  Copyright © 2026 Koen van der Drift. All rights reserved.
//

import Foundation

struct PSIModParseResult {
    let version: String
    let modifications: [Modification]
    let rejectedTermCount: Int
}

enum PSIModReferenceLibraryLoader {
    static func load(elements: ElementReferences) throws -> ModificationLibrary {
        let text = try loadText(from: "PSI-MOD", withExtension: "obo", in: .module)
        let result = PSIModParser(elements: elements).parse(text)

        return ModificationLibrary(
            vocabulary: .psiMod,
            version: result.version,
            modifications: result.modifications,
            rejectedTermCount: result.rejectedTermCount
        )
    }

    static func parse(_ text: String, elements: ElementReferences) -> PSIModParseResult {
        PSIModParser(elements: elements).parse(text)
    }
}

private struct PSIModTerm {
    var accession = ""
    var name = ""
    var definition = ""
    var synonyms: [String] = []
    var preferredLabel: String?
    var differenceFormula: String?
    var origins: [String] = []
    var terminalSpecificity: String?
    var source: String?
    var isObsolete = false
}

private struct PSIModParser {
    private let elements: ElementReferences
    private let canonicalOrigins = Set("ACDEFGHIKLMNPQRSTVWYX".map(String.init))

    init(elements: ElementReferences) {
        self.elements = elements
    }

    func parse(_ text: String) -> PSIModParseResult {
        let normalizedText = text.replacingOccurrences(of: "\r\n", with: "\n")
        let sections = normalizedText.components(separatedBy: "[Term]")
        let version = headerValue(named: "data-version", in: sections.first ?? "") ?? ""
        let terms = sections.dropFirst().compactMap(parseTerm)
        let modifications = terms.compactMap(makeModification)

        return PSIModParseResult(
            version: version,
            modifications: modifications,
            rejectedTermCount: terms.count - modifications.count
        )
    }

    private func parseTerm(_ section: String) -> PSIModTerm? {
        let stanza = section.components(separatedBy: "[Typedef]").first ?? section
        let lines = stanza.split(whereSeparator: \.isNewline).map(String.init)

        guard let accession = value(for: "id", in: lines),
            let name = value(for: "name", in: lines)
        else {
            return nil
        }

        let xrefs = values(for: "xref", in: lines)
        let synonymLines = values(for: "synonym", in: lines)
        let synonyms = synonymLines.compactMap(quotedValue)

        var term = PSIModTerm()
        term.accession = accession
        term.name = name
        term.definition = quotedValue(value(for: "def", in: lines)) ?? ""
        term.synonyms = synonyms
        term.preferredLabel = synonymLines.first(where: { $0.contains("PSI-MOD-label") })
            .flatMap(quotedValue)
        term.differenceFormula = xrefValue(named: "DiffFormula", in: xrefs)
        term.origins = xrefValue(named: "Origin", in: xrefs)?
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) } ?? []
        term.terminalSpecificity = xrefValue(named: "TermSpec", in: xrefs)
        term.source = xrefValue(named: "Source", in: xrefs)
        term.isObsolete = value(for: "is_obsolete", in: lines) == "true"
        return term
    }

    private func makeModification(from term: PSIModTerm) -> Modification? {
        guard !term.isObsolete,
            let differenceFormula = term.differenceFormula,
            differenceFormula != "none",
            term.origins.count == 1,
            let origin = term.origins.first,
            !origin.hasPrefix("MOD:"),
            canonicalOrigins.contains(origin),
            let elementCounts = parseDifferenceFormula(differenceFormula),
            !elementCounts.isEmpty
        else {
            return nil
        }

        let position: String
        switch term.terminalSpecificity {
        case "N-term":
            position = "Any N-term"
        case "C-term":
            position = "Any C-term"
        default:
            position = "Anywhere"
        }

        return Modification(
            accession: term.accession,
            name: term.preferredLabel ?? term.name,
            fullName: term.name,
            synonyms: term.synonyms,
            elements: elementCounts,
            specificities: [
                ModificationSpecificity(
                    site: origin,
                    position: position,
                    classification: term.source ?? ""
                )
            ]
        )
    }

    private func parseDifferenceFormula(_ formula: String) -> [String: Int]? {
        let components = formula.split(whereSeparator: \.isWhitespace)
        guard components.count.isMultiple(of: 2) else {
            return nil
        }

        var result: [String: Int] = [:]
        for index in stride(from: 0, to: components.count, by: 2) {
            let symbol = String(components[index])
            guard !symbol.hasPrefix("("),
                elements.element(symbol: symbol) != nil,
                let count = Int(components[index + 1])
            else {
                return nil
            }

            if count != 0 {
                result[symbol, default: 0] += count
            }
        }

        return result
    }

    private func headerValue(named name: String, in text: String) -> String? {
        value(for: name, in: text.split(whereSeparator: \.isNewline).map(String.init))
    }

    private func value(for key: String, in lines: [String]) -> String? {
        lines.first(where: { $0.hasPrefix("\(key):") }).map {
            String($0.dropFirst(key.count + 1)).trimmingCharacters(in: .whitespaces)
        }
    }

    private func values(for key: String, in lines: [String]) -> [String] {
        lines.compactMap { line in
            guard line.hasPrefix("\(key):") else {
                return nil
            }

            return String(line.dropFirst(key.count + 1)).trimmingCharacters(in: .whitespaces)
        }
    }

    private func quotedValue(_ value: String?) -> String? {
        guard let value, let openingQuote = value.firstIndex(of: "\"") else {
            return nil
        }

        var index = value.index(after: openingQuote)
        var result = ""
        var isEscaped = false

        while index < value.endIndex {
            let character = value[index]
            if character == "\"", !isEscaped {
                return result
            }

            if character == "\\", !isEscaped {
                isEscaped = true
            } else {
                result.append(character)
                isEscaped = false
            }
            index = value.index(after: index)
        }

        return nil
    }

    private func xrefValue(named name: String, in xrefs: [String]) -> String? {
        xrefs.first(where: { $0.hasPrefix("\(name):") }).flatMap(quotedValue)
    }
}
