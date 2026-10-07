//
//  Unimod.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/14/20.
//  Copyright © 2020 - 2026 Koen van der Drift. All rights reserved.
//

import Foundation

// MARK: - Partial XML result

struct UnimodReferenceLibraries {
    let aminoAcids: [AminoAcid]
    let modifications: [Modification]
}

// MARK: - XML loader

enum UnimodReferenceLibraryLoader {
    static func load() throws -> UnimodReferenceLibraries {
        let elements = ElementReferences(elements: try ElementsLibraryDefaults.loadBundled())

        return try load(elements: elements)
    }

    static func load(elements: ElementReferences) throws -> UnimodReferenceLibraries {
        let data = try loadData(from: "unimod", withExtension: "xml", in: .module)

        let parser = UnimodXMLParser(elements: elements)
        return try parser.parse(data: data)
    }

    /// Handy for tests with custom XML data.
    static func parse(data: Data) throws -> UnimodReferenceLibraries {
        let elements = ElementReferences(elements: try ElementsLibraryDefaults.loadBundled())

        let parser = UnimodXMLParser(elements: elements)
        return try parser.parse(data: data)
    }
}

final class UnimodXMLParser: NSObject {
    private let elementReferences: ElementReferences
    private var parseError: Error?

    private let modification = "umod:mod"
    private let specificity = "umod:specificity"
    private let neutralLoss = "umod:NeutralLoss"
    private let element = "umod:element"

    private let titleAttributeKey = "title"
    private let recordIDAttributeKey = "record_id"
    private let siteAttributeKey = "site"
    private let positionAttributeKey = "position"
    private let classificationAttributeKey = "classification"
    private let symbolAttributeKey = "symbol"
    private let numberAttributeKey = "number"

    private let elements = "umod:elements"
    private let elem = "umod:elem"
    private let averageMassAttributeKey = "avge_mass"
    private let monoisotopicMassAttributeKey = "mono_mass"

    private let aminoAcid = "umod:aa"
    private let fullNameAttributeKey = "full_name"
    private let threeLetterAttributeKey = "three_letter"

    private let unknown = "Unknown"
    private let xlink = "Xlink"
    private let cation = "Cation"
    private let atypeion = "a-type-ion"

    private var skipTitleStrings: [String] = []

    var parsedElements: [ChemicalElement] = []
    var parsedAminoAcids: [AminoAcid] = []
    var parsedModifications: [Modification] = []

    var elementSymbol = ""
    var elementFullName = ""
    var elementMonoisotopicMass = ""
    var elementAverageMass = ""

    var modificationTitle = ""
    var modificationAccession: String?
    var modificationFullName = ""
    var modificationElements = [String: Int]()
    var modificationSpecificities = [ModificationSpecificity]()

    var aminoAcidName = ""
    var aminoAcidOneLetterCode = ""
    var aminoAcidThreeLetterCode = ""
    var aminoAcidElements = [String: Int]()

    var isElement = false
    var isAminoAcid = false
    var isModification = false
    var isNeutralLoss = false

    let rightArrow = "\u{2192}"

    init(elements: ElementReferences) {
        self.elementReferences = elements
        super.init()
    }

    func parse(data: Data) throws -> UnimodReferenceLibraries {
        skipTitleStrings = [cation, unknown, xlink, atypeion, "2H", "13C", "15N"]

        parseError = nil
        parsedElements = []
        parsedAminoAcids = []
        parsedModifications = []

        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = self

        let didParse = xmlParser.parse()

        guard didParse else {
            let error = parseError ?? xmlParser.parserError
                ?? LoadError.fileParsingFailed(name: "unimod.xml", underlyingError: nil)
            throw BioSwiftDiagnostics.logged(error)
        }

        return UnimodReferenceLibraries(aminoAcids: parsedAminoAcids, modifications: parsedModifications)
    }

    private func resetModificationState() {
        modificationTitle.removeAll()
        modificationAccession = nil
        modificationFullName.removeAll()
        modificationElements.removeAll()
        modificationSpecificities.removeAll()
    }

    private func makeModification() throws -> Modification {
        var elementsBySymbol = Dictionary(
            uniqueKeysWithValues: elementReferences.elements.map { ($0.symbol, $0) })
        for element in parsedElements {
            elementsBySymbol[element.symbol] = element
        }
        let references = ElementReferences(elements: Array(elementsBySymbol.values))
        var reactions: [Reaction] = []

        let removedElements = modificationElements.filter { $0.value < 0 }
        if removedElements.isEmpty == false {
            let formula = try FormulaParser.parse(elements: removedElements, using: references)
            reactions.append(.remove(FunctionalGroup(name: modificationTitle, formula: formula)))
        }

        let addedElements = modificationElements.filter { $0.value > 0 }
        if addedElements.isEmpty == false {
            let formula = try FormulaParser.parse(elements: addedElements, using: references)
            reactions.append(.add(FunctionalGroup(name: modificationTitle, formula: formula)))
        }

        return Modification(
            accession: modificationAccession,
            name: modificationTitle,
            fullName: modificationFullName,
            reactions: reactions,
            specificities: modificationSpecificities
        )
    }
}

// MARK: XML Parser Delegate

extension UnimodXMLParser: XMLParserDelegate {
    func parserDidStartDocument(_: XMLParser) {
        BioSwiftDiagnostics.log("Started parsing unimod.xml")
    }

    func parser(
        _: XMLParser, didStartElement xmlElementName: String, namespaceURI _: String?,
        qualifiedName _: String?, attributes attributeDict: [String: String] = [:]
    ) {
        if xmlElementName == elements {
            isElement = true
        } else if xmlElementName == modification {
            isModification = true
            resetModificationState()

            if let recordID = attributeDict[recordIDAttributeKey] {
                modificationAccession = "UNIMOD:\(recordID)"
            }

            if let title = attributeDict[titleAttributeKey],
                skipTitleStrings.contains(where: title.contains) == false
            {
                modificationTitle = title.replacingOccurrences(
                    of: "->", with: " " + rightArrow + " ")
            }
            if let fullName = attributeDict[fullNameAttributeKey],
                skipTitleStrings.contains(where: fullName.contains) == false
            {
                modificationFullName = fullName
            }

        } else if xmlElementName == specificity {
            if let site = attributeDict[siteAttributeKey],
                let position = attributeDict[positionAttributeKey],
                let classification = attributeDict[classificationAttributeKey]
            {
                modificationSpecificities.append(
                    ModificationSpecificity(
                        site: site, position: position, classification: classification))
            }
        } else if xmlElementName == neutralLoss {
            isNeutralLoss = true
        } else if xmlElementName == element {
            if isNeutralLoss == false, let symbol = attributeDict[symbolAttributeKey],
                let number = attributeDict[numberAttributeKey]
            {
                if isAminoAcid == true {
                    aminoAcidElements[symbol] = Int(number)
                } else if isModification == true {
                    modificationElements[symbol] = Int(number)
                }
            }
        } else if xmlElementName == elem {
            if isElement == true {
                if let symbol = attributeDict[titleAttributeKey],
                    let name = attributeDict[fullNameAttributeKey],
                    let monoisotopicMass = attributeDict[monoisotopicMassAttributeKey],
                    let averageMass = attributeDict[averageMassAttributeKey]
                {
                    elementSymbol = symbol
                    elementFullName = name
                    elementMonoisotopicMass = monoisotopicMass
                    elementAverageMass = averageMass
                }
            }
        } else if xmlElementName == aminoAcid {
            isAminoAcid = true

            if let title = attributeDict[titleAttributeKey],
                let threeLetterCode = attributeDict[threeLetterAttributeKey],
                let name = attributeDict[fullNameAttributeKey]
            {
                aminoAcidName = name
                aminoAcidOneLetterCode = title
                aminoAcidThreeLetterCode = threeLetterCode
            }
        }
    }

    func parser(
        _ parser: XMLParser, didEndElement xmlElementName: String, namespaceURI _: String?,
        qualifiedName _: String?
    ) {
        if xmlElementName == elem {
            if elementFullName.isEmpty == false {
                guard let monoisotopicMass = Dalton(string: elementMonoisotopicMass) else {
                    parseError = ReferenceDataError.invalidNumericValue(
                        source: "unimod.xml", field: "mono_mass", value: elementMonoisotopicMass)
                    parser.abortParsing()
                    return
                }
                guard let averageMass = Dalton(string: elementAverageMass) else {
                    parseError = ReferenceDataError.invalidNumericValue(
                        source: "unimod.xml", field: "avge_mass", value: elementAverageMass)
                    parser.abortParsing()
                    return
                }
                let chemicalElement = ChemicalElement(
                    name: elementFullName, symbol: elementSymbol,
                    monoisotopicMass: monoisotopicMass,
                    averageMass: averageMass)

                parsedElements.append(chemicalElement)

                elementSymbol.removeAll()
                elementFullName.removeAll()
                elementMonoisotopicMass.removeAll()
                elementAverageMass.removeAll()
            }
        } else if xmlElementName == elements {
            isElement = false
        } else if xmlElementName == neutralLoss {
            isNeutralLoss = false
        } else if xmlElementName == modification {
            if modificationTitle.isEmpty == false {
                let mod: Modification
                do {
                    mod = try makeModification()
                } catch {
                    parseError = error
                    parser.abortParsing()
                    return
                }

                parsedModifications.append(mod)
            }

            resetModificationState()
            isModification = false
        } else if xmlElementName == aminoAcid {
            if aminoAcidName.isEmpty == false {
                let aa: AminoAcid
                do {
                    aa = try AminoAcid(
                        name: aminoAcidName, oneLetterCode: aminoAcidOneLetterCode,
                        threeLetterCode: aminoAcidThreeLetterCode, elements: aminoAcidElements)
                } catch {
                    parseError = error
                    parser.abortParsing()
                    return
                }

                parsedAminoAcids.append(aa)

                aminoAcidName.removeAll()
                aminoAcidOneLetterCode.removeAll()
                aminoAcidThreeLetterCode.removeAll()
                aminoAcidElements.removeAll()

                isAminoAcid = false
            }
        }
    }

    func parserDidEndDocument(_: XMLParser) {
        BioSwiftDiagnostics.log("Finished parsing unimod.xml")
    }

    func parser(_: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError
    }
}
