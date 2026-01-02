//
//  Unimod.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/14/20.
//  Copyright © 2020 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

public struct UnimodController {
    public func loadUnimod() async throws {
        do {
            let unimodParser = UnimodParser()
            try await unimodParser.parseXML()
        } catch {
            debugPrint("Failed parsing unimod.xml")

            throw (error)
        }
    }
}

public class UnimodParser: NSObject {
    private let modification = "umod:mod"
    private let specificity = "umod:specificity"
    private let neutralLoss = "umod:NeutralLoss"
    private let element = "umod:element"

    private let titleAttributeKey = "title"
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

    var elementSymbol = ""
    var elementFullName = ""
    var elementMonoisotopicMass = ""
    var elementAverageMass = ""

    var modificationTitle = ""
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

    public func parseXML() async throws {
        //        skipTitleStrings = [cation, unknown, xlink, atypeion, "2H", "13C", "15N"]

        do {
            debugPrint("Started parsing unimod.xml")

            let data = try loadDataFromBundle(from: "unimod", withExtension: "xml")
            let parser = XMLParser(data: data)
            parser.delegate = self

            if parser.parse() == false {
                if let error = parser.parserError {
                    throw (error)
                } else {
                    throw LoadError.fileParsingFailed(name: "unimod")
                }
            }

            debugPrint("Finished parsing unimod.xml")
        }
    }

    public func parseXML() throws {
//        skipTitleStrings = [cation, unknown, xlink, atypeion, "2H", "13C", "15N"]

        do {
            let data = try loadDataFromBundle(from: "unimod", withExtension: "xml")
            let parser = XMLParser(data: data)
            parser.delegate = self

            if parser.parse() == false {
                if let error = parser.parserError {
                    throw (error)
                } else {
                    throw LoadError.fileParsingFailed(name: "unimod")
                }
            }
        }
    }
}

// MARK: XML Parser Delegate

extension UnimodParser: XMLParserDelegate {
    public func parser(_: XMLParser, didStartElement xmlElementName: String, namespaceURI _: String?, qualifiedName _: String?, attributes attributeDict: [String: String] = [:]) {
        if xmlElementName == elements {
            isElement = true
        } else if xmlElementName == modification {
            isModification = true

            if let title = attributeDict[titleAttributeKey],
               skipTitleStrings.contains(where: title.contains) == false
            {
                modificationTitle = title.replacingOccurrences(of: "->", with: " " + rightArrow + " ")
            }
            if let fullName = attributeDict[fullNameAttributeKey],
               skipTitleStrings.contains(where: fullName.contains) == false
            {
                modificationFullName = fullName
            }

        } else if xmlElementName == specificity {
            if let site = attributeDict[siteAttributeKey], let position = attributeDict[positionAttributeKey],
               let classification = attributeDict[classificationAttributeKey]
            {
                modificationSpecificities.append(ModificationSpecificity(site: site, position: position, classification: classification))
            }
        } else if xmlElementName == neutralLoss {
            isNeutralLoss = true
        } else if xmlElementName == element {
            if isNeutralLoss == false,
               let symbol = attributeDict[symbolAttributeKey],
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

    public func parser(_: XMLParser, didEndElement xmlElementName: String, namespaceURI _: String?, qualifiedName _: String?) {
        if xmlElementName == elem {
            if elementFullName.isEmpty == false {
                let chemicalElement = ChemicalElement(name: elementFullName, symbol: elementSymbol, monoisotopicMass: Dalton(string: elementMonoisotopicMass) ?? 0.0, averageMass: Dalton(string: elementAverageMass) ?? 0.0)

                elementLibrary.append(chemicalElement)

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
                let mod = Modification(name: modificationTitle, fullName: modificationFullName, elements: modificationElements, specificities: modificationSpecificities)

                modificationLibrary.append(mod)

                modificationTitle.removeAll()
                modificationFullName.removeAll()
                modificationElements.removeAll()
                modificationSpecificities.removeAll()

                isModification = false
            }
        } else if xmlElementName == aminoAcid {
            if aminoAcidName.isEmpty == false {
                let aa = AminoAcid(name: aminoAcidName, oneLetterCode: aminoAcidOneLetterCode, threeLetterCode: aminoAcidThreeLetterCode, elements: aminoAcidElements)

                aminoAcidLibrary.append(aa)

                aminoAcidName.removeAll()
                aminoAcidOneLetterCode.removeAll()
                aminoAcidThreeLetterCode.removeAll()
                aminoAcidElements.removeAll()

                isAminoAcid = false
            }
        }
    }
}
