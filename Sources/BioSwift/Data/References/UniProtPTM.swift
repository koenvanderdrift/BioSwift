//
//  UniProtPTM.swift
//  BioSwift
//
//  Copyright © 2026 Koen van der Drift. All rights reserved.
//

import Foundation

enum UniProtPTMReferenceLibraryLoader {
    static func load(
        elements: ElementReferences,
        aminoAcids: AminoAcidReferences
    ) throws -> ModificationLibrary {
        let text = try loadText(from: "uniprot-ptm-list", withExtension: "txt", in: .module)
        return try UniProtPTMParser(elements: elements, aminoAcids: aminoAcids).parse(text)
    }

    static func parse(
        _ text: String,
        elements: ElementReferences,
        aminoAcids: AminoAcidReferences
    ) throws -> ModificationLibrary {
        try UniProtPTMParser(elements: elements, aminoAcids: aminoAcids).parse(text)
    }
}

private struct UniProtPTMRecord {
    let values: [String: [String]]

    func value(for key: String) -> String? {
        values[key]?.first
    }

    func values(for key: String) -> [String] {
        values[key] ?? []
    }
}

private struct UniProtPTMParser {
    private let elements: ElementReferences
    private let aminoAcidsByIdentifier: [String: AminoAcid]

    init(elements: ElementReferences, aminoAcids: AminoAcidReferences) {
        self.elements = elements
        var aminoAcidsByIdentifier: [String: AminoAcid] = [:]

        for aminoAcid in aminoAcids.aminoAcids {
            let identifiers = [
                aminoAcid.name,
                aminoAcid.oneLetterCode,
                aminoAcid.threeLetterCode,
            ] + aminoAcid.represents

            for identifier in identifiers {
                aminoAcidsByIdentifier[Self.normalizedAminoAcidIdentifier(identifier)] = aminoAcid
            }
        }

        self.aminoAcidsByIdentifier = aminoAcidsByIdentifier
    }

    func parse(_ text: String) throws -> ModificationLibrary {
        let normalizedText = text.replacingOccurrences(of: "\r\n", with: "\n")
        let version = parseVersion(from: normalizedText)
        let records = normalizedText.components(separatedBy: "\n//").compactMap(parseRecord)
        let convertedRecords = try records.compactMap(convert)
        let modifications = convertedRecords.map(\.modification)
        let metadata = Dictionary(
            uniqueKeysWithValues: convertedRecords.map {
                ($0.modification.accession ?? "", $0.metadata)
            }
        )

        return ModificationLibrary(
            vocabulary: .uniProtPTM,
            version: version,
            modifications: modifications,
            metadataByAccession: metadata
        )
    }

    private func parseRecord(_ section: String) -> UniProtPTMRecord? {
        var values: [String: [String]] = [:]

        for rawLine in section.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            let parts = line.split(maxSplits: 1, whereSeparator: \.isWhitespace)
            guard parts.count == 2 else {
                continue
            }

            let key = String(parts[0])
            guard Self.supportedKeys.contains(key) else {
                continue
            }

            let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
            values[key, default: []].append(value)
        }

        guard values["ID"] != nil else {
            return nil
        }
        return UniProtPTMRecord(values: values)
    }

    private func convert(
        _ record: UniProtPTMRecord
    ) throws -> (modification: Modification, metadata: ModificationMetadata)? {
        guard let feature = record.value(for: "FT"),
            feature != "CROSSLNK",
            let accession = record.value(for: "AC"),
            let name = record.value(for: "ID"),
            let target = record.value(for: "TG").map(removeTrailingPeriod),
            let aminoAcid = aminoAcidsByIdentifier[
                Self.normalizedAminoAcidIdentifier(target)
            ],
            let correctionFormula = record.value(for: "CF"),
            let elementCounts = parseCorrectionFormula(correctionFormula),
            !elementCounts.isEmpty
        else {
            return nil
        }

        let keywords = record.values(for: "KW").map(removeTrailingPeriod)
        let specificities = [
            ModificationSpecificity(
                site: aminoAcid.oneLetterCode,
                position: normalizedPosition(record.value(for: "PP")),
                classification: keywords.joined(separator: ", ")
            )
        ]
        let modification: Modification
        if let glycan = parsedGlycan(from: name) {
            let targetFormula = try FormulaParser.parse(elements: elementCounts, using: elements)
            modification = Modification(
                accession: accession,
                name: name,
                reactions: glycanReactions(glycan: glycan, targetFormula: targetFormula),
                specificities: specificities
            )
        } else {
            modification = try Modification(
                accession: accession,
                name: name,
                elements: elementCounts,
                specificities: specificities
            )
        }

        let metadata = ModificationMetadata(
            taxonomicRanges: record.values(for: "TR").compactMap(parseTaxonomicRange),
            keywords: keywords,
            cellularLocations: record.values(for: "LC").map(removeTrailingPeriod),
            crossReferences: record.values(for: "DR").compactMap(parseCrossReference)
        )
        return (modification, metadata)
    }

    private func parsedGlycan(from modificationName: String) -> Glycan? {
        guard let notation = firstParenthesizedExpression(in: modificationName),
              notation.contains("->"),
              notation.contains("...") == false else {
            return nil
        }
        return try? GlycanIUPACParser().parseUnlogged(notation)
    }

    private func firstParenthesizedExpression(in text: String) -> String? {
        guard let open = text.firstIndex(of: "(") else { return nil }
        var depth = 0
        for index in text.indices[open...] {
            switch text[index] {
            case "(": depth += 1
            case ")":
                depth -= 1
                if depth == 0 {
                    return String(text[text.index(after: open)..<index])
                }
            default: break
            }
        }
        return nil
    }

    private func glycanReactions(glycan: Glycan, targetFormula: Formula) -> [Reaction] {
        var reactions: [Reaction] = [.add(.glycan(glycan))]
        let correction = targetFormula - glycan.formula
        let removedElements = correction.countedElements.filter { $0.value < 0 }
            .mapValues { abs($0) }
        let addedElements = correction.countedElements.filter { $0.value > 0 }

        if removedElements.isEmpty == false {
            reactions.append(.remove(.functionalGroup(
                FunctionalGroup(
                    name: "glycan attachment loss",
                    formula: Formula(inputString: "", countedElements: removedElements)
                )
            )))
        }
        if addedElements.isEmpty == false {
            reactions.append(.add(.functionalGroup(
                FunctionalGroup(
                    name: "glycan attachment addition",
                    formula: Formula(inputString: "", countedElements: addedElements)
                )
            )))
        }
        return reactions
    }

    private func parseCorrectionFormula(_ formula: String) -> [String: Int]? {
        var result: [String: Int] = [:]

        for component in formula.split(whereSeparator: \.isWhitespace) {
            let token = String(component)
            guard let numberStart = token.firstIndex(where: {
                $0 == "-" || $0 == "+" || $0.isNumber
            }) else {
                return nil
            }

            let symbol = String(token[..<numberStart])
            let countText = String(token[numberStart...])
            guard !symbol.isEmpty,
                symbol.allSatisfy(\.isLetter),
                elements.element(symbol: symbol) != nil,
                let count = Int(countText)
            else {
                return nil
            }

            if count != 0 {
                result[symbol, default: 0] += count
            }
        }

        return result
    }

    private static func normalizedAminoAcidIdentifier(_ identifier: String) -> String {
        let normalizedIdentifier = identifier.lowercased().filter(\.isLetter)
        return uniProtTargetAliases[normalizedIdentifier] ?? normalizedIdentifier
    }

    private static let uniProtTargetAliases = [
        "aspartate": "asparticacid",
        "glutamate": "glutamicacid",
    ]

    private func parseTaxonomicRange(_ value: String) -> TaxonomicRange? {
        let cleanedValue = removeTrailingPeriod(value)
        guard let separator = cleanedValue.firstIndex(of: ";") else {
            return nil
        }

        let name = cleanedValue[..<separator].trimmingCharacters(in: .whitespaces)
        let remainder = cleanedValue[cleanedValue.index(after: separator)...]
            .trimmingCharacters(in: .whitespaces)
        guard remainder.hasPrefix("taxId:"),
            let identifierText = remainder.dropFirst("taxId:".count)
                .split(whereSeparator: \.isWhitespace).first,
            let identifier = Int(identifierText)
        else {
            return nil
        }

        return TaxonomicRange(name: name, taxonIdentifier: identifier)
    }

    private func parseCrossReference(_ value: String) -> ModificationCrossReference? {
        let components = removeTrailingPeriod(value).split(
            separator: ";", maxSplits: 1
        )
        guard components.count == 2 else {
            return nil
        }

        return ModificationCrossReference(
            database: components[0].trimmingCharacters(in: .whitespaces),
            identifier: components[1].trimmingCharacters(in: .whitespaces)
        )
    }

    private func normalizedPosition(_ position: String?) -> String {
        guard let position else {
            return "Anywhere"
        }

        return removeTrailingPeriod(position)
            .replacingOccurrences(of: "N-terminal", with: "N-term")
            .replacingOccurrences(of: "C-terminal", with: "C-term")
    }

    private func parseVersion(from text: String) -> String {
        for rawLine in text.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("Release:") {
                return line.dropFirst("Release:".count)
                    .trimmingCharacters(in: .whitespaces)
                    .split(whereSeparator: \.isWhitespace)
                    .first.map(String.init) ?? ""
            }
        }
        return ""
    }

    private func removeTrailingPeriod(_ value: String) -> String {
        value.hasSuffix(".") ? String(value.dropLast()) : value
    }

    private static let supportedKeys: Set<String> = [
        "ID", "AC", "FT", "TG", "PA", "PP", "CF", "LC", "TR", "KW", "DR",
    ]
}
