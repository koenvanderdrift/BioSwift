//
//  Unimod.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/14/20.
//  Copyright © 2020 - 2024 Koen van der Drift. All rights reserved.
//

import Foundation

public struct UnimodController {
    public func loadUnimod() throws {
        do {
            debugPrint("Start parsing unimod.xml")

            let unimodParser = UnimodParser()
            try unimodParser.parseXML()

            debugPrint("Finished parsing unimod.xml")
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

    var modificationName = ""
    var modificationElements = [String: Int]()
    var modificationSpecificities = [ModificationSpecificity]()

    var aminoAcidName = ""
    var aminoAcidOneLetterCode = ""
    var aminoAcidThreeLetterCode = ""
    var aminoAcidElements = [String: Int]()

    var isElements = false
    var isAminoAcid = false
    var isModification = false
    var isNeutralLoss = false

    let rightArrow = "\u{2192}"

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    public func parseXML() async throws {
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
    public func parser(_: XMLParser, didStartElement elementName: String, namespaceURI _: String?, qualifiedName _: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == elements {
            isElements = true
        } else if elementName == modification {
            isModification = true

            if let title = attributeDict[titleAttributeKey],
               skipTitleStrings.contains(where: title.contains) == false
            {
                modificationName = title.replacingOccurrences(of: "->", with: " " + rightArrow + " ")
            }
        } else if elementName == specificity {
            if let site = attributeDict[siteAttributeKey], let position = attributeDict[positionAttributeKey],
               let classification = attributeDict[classificationAttributeKey], classification.contains("Isotopic label") == false
            {
                modificationSpecificities.append(ModificationSpecificity(site: site, position: position))
            }
        } else if elementName == neutralLoss {
            isNeutralLoss = true
        } else if elementName == element {
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
        } else if elementName == elem {
//            if isElements == true {
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
//            }
        } else if elementName == aminoAcid {
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

    public func parser(_: XMLParser, didEndElement elementName: String, namespaceURI _: String?, qualifiedName _: String?) {
        if elementName == elem {
            if elementFullName.isEmpty == false {
                let chemicalElement = ChemicalElement(name: elementFullName, symbol: elementSymbol, monoisotopicMass: Dalton(elementMonoisotopicMass) ?? 0.0, averageMass: Dalton(elementAverageMass) ?? 0.0)

                elementLibrary.append(chemicalElement)

                elementSymbol.removeAll()
                elementFullName.removeAll()
                elementMonoisotopicMass.removeAll()
                elementAverageMass.removeAll()
            }
        } else if elementName == elements {
            isElements = false
        } else if elementName == neutralLoss {
            isNeutralLoss = false
        } else if elementName == modification {
            if modificationName.isEmpty == false {
                let mod = Modification(name: modificationName, elements: modificationElements, specificities: modificationSpecificities)

                modificationLibrary.append(mod)

                modificationName.removeAll()
                modificationElements.removeAll()
                modificationSpecificities.removeAll()

                isModification = false
            }
        } else if elementName == aminoAcid {
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
