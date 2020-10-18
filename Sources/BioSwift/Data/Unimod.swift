//
//  Unimod.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/14/20.
//  Copyright © 2020 Koen van der Drift. All rights reserved.
//

import Foundation

public var uniModifications = [Modification]()
public var uniAminoAcids = [AminoAcid]()

private let modification = "umod:mod"
private let specificity = "umod:specificity"
private let neutralLoss = "umod:NeutralLoss"
private let element = "umod:element"

private let titleAttributeKey = "title"
private let siteAttributeKey = "site"
private let classificationAttributeKey = "classification"
private let symbolAttributeKey = "symbol"
private let numberAttributeKey = "number"

private let aminoAcid = "umod:aa"
private let fullNameAttributeKey = "full_name"
private let threeLetterAttributeKey = "three_letter"

private let unknown = "Unknown"
private let xlink = "Xlink"
private let cation = "Cation"
private let atypeion = "a-type-ion"

private let skipTitleStrings = [cation, unknown, xlink, atypeion, "2H", "13C", "15N"]
public let unimodDidLoadNotification = Notification.Name("UnimodDidLoadNotification")

//public let unimodURL = Bundle.module.url(forResource: "unimod", withExtension: "xml")

public func loadUnimod() {
//    guard let bundle = Bundle(identifier: bioSwiftBundleIdentifier) else {
//        fatalError("Unable to load bundle")
//    }
//
//    guard let url = bundle.url(forResource: "unimod", withExtension: "xml") else {
//        fatalError("Unable to find unimod.xml")
//    }

    guard let url = Bundle.module.url(forResource: "unimod", withExtension: "xml") else {
        fatalError("Unable to find unimod.xml")
    }
    
    DispatchQueue.global(qos: .userInitiated).async {
        debugPrint("Start parsing unimod.xml")

        let unimodParser = UnimodParser(with: url)
        let success = unimodParser.parseXML()

        if success {
            DispatchQueue.main.async {
                debugPrint("Finished parsing unimod.xml")

                NotificationCenter.default.post(name: unimodDidLoadNotification, object: nil)
            }
        } else {
            debugPrint("Failed parsing unimod.xml")
        }
    }
}

public class UnimodParser: NSObject {
    let url: URL

    var elementSymbol = ""
    var elementFullName = ""
    var elementMonoisotopicMass = ""
    var elementAverageMass = ""

    var modificationName = ""
    var modificationSites = [String]()
    var modificationElements = [String: Int]()

    var aminoAcidName = ""
    var aminoAcidOneLetterCode = ""
    var aminoAcidThreeLetterCode = ""
    var aminoAcidElements = [String: Int]()

    var isAminoAcid = false
    var isModification = false
    var isNeutralLoss = false

    let rightArrow = "\u{2192}"
    
    public init(with url: URL) {
        self.url = url

        super.init()
    }

    public func parseXML() -> Bool {
        var result = false

        if let parser = XMLParser(contentsOf: url) {
            parser.delegate = self

            result = parser.parse()
        }

        return result
    }
}

// MARK: XML Parser Delegate

extension UnimodParser: XMLParserDelegate {
    public func parser(_: XMLParser, didStartElement elementName: String, namespaceURI _: String?, qualifiedName _: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == modification {
            isModification = true

            if let title = attributeDict[titleAttributeKey],
                skipTitleStrings.contains(where: title.contains) == false {
                modificationName = title.replacingOccurrences(of: "->", with: " " + rightArrow + " ")
            }
        } else if elementName == specificity {
            if let site = attributeDict[siteAttributeKey],
                let classification = attributeDict[classificationAttributeKey], classification.contains("Isotopic label") == false {
                modificationSites.append(site)
            }
        } else if elementName == neutralLoss {
            isNeutralLoss = true
        } else if elementName == element {
            if isNeutralLoss == false,
                let symbol = attributeDict[symbolAttributeKey],
                let number = attributeDict[numberAttributeKey] {
                if isAminoAcid == true {
                    aminoAcidElements[symbol] = Int(number)
                } else if isModification == true {
                    modificationElements[symbol] = Int(number)
                }
            }
        } else if elementName == aminoAcid {
            isAminoAcid = true

            if let title = attributeDict[titleAttributeKey],
                let threeLetterCode = attributeDict[threeLetterAttributeKey],
                let name = attributeDict[fullNameAttributeKey] {
                aminoAcidName = name
                aminoAcidOneLetterCode = title
                aminoAcidThreeLetterCode = threeLetterCode
            }
        }
    }

    public func parser(_: XMLParser, didEndElement elementName: String, namespaceURI _: String?, qualifiedName _: String?) {
        if elementName == neutralLoss {
            isNeutralLoss = false
        } else if elementName == modification {
            if modificationName.isEmpty == false {
                let mod = Modification(name: modificationName, elements: modificationElements, sites: modificationSites)

                uniModifications.append(mod)

                modificationName.removeAll()
                modificationSites.removeAll()
                modificationElements.removeAll()

                isModification = false
            }
        } else if elementName == aminoAcid {
            if aminoAcidName.isEmpty == false {
                let aa = AminoAcid(name: aminoAcidName, oneLetterCode: aminoAcidOneLetterCode, threeLetterCode: aminoAcidThreeLetterCode, elements: aminoAcidElements)

                uniAminoAcids.append(aa)

                aminoAcidName.removeAll()
                aminoAcidOneLetterCode.removeAll()
                aminoAcidThreeLetterCode.removeAll()
                aminoAcidElements.removeAll()

                isAminoAcid = false
            }
        }
    }
}
