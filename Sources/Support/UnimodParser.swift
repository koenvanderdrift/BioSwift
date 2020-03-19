//
//  UnimodParser.swift
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

private let skipTitleStrings = [cation, unknown, xlink]

public class UnimodParser: NSObject {
    let parser: XMLParser
    
    var elementSymbol = ""
    var elementFullName = ""
    var elementMonoisotopicMass = ""
    var elementAverageMass = ""
    
    var modificationName = ""
    var modificationSites = [String]()
    var modificationElements = [String : Int]()

    var aminoAcidName = ""
    var aminoAcidOneLetterCode = ""
    var aminoAcidThreeLetterCode = ""
    var aminoAcidElements = [String : Int]()

    var isAminoAcid = false
    var isModification = false
    var isNeutralLoss = false

    public init(xml: String) {
        let xmlData = xml.data(using: String.Encoding.utf8)!
        parser = XMLParser(data: xmlData)
        
        super.init()
        
        parser.delegate = self
    }
    
    public func parseXML() -> Bool {
        return parser.parse()
    }
}

// MARK: XML Parser Delegate

extension UnimodParser: XMLParserDelegate {
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        if elementName == modification {
            isModification = true
            
            if let title = attributeDict[titleAttributeKey],
                skipTitleStrings.contains(where: title.hasPrefix) == false {
                modificationName = title
            }
        }
            
        else if elementName == specificity {
            if let site = attributeDict[siteAttributeKey],
                let classification = attributeDict[classificationAttributeKey], classification.contains("Isotopic label") == false {
                modificationSites.append(site)
            }
        }
            
        else if elementName == neutralLoss {
            isNeutralLoss = true
        }
            
        else if elementName == element {
            if isNeutralLoss == false,
                let symbol = attributeDict[symbolAttributeKey],
                let number = attributeDict[numberAttributeKey] {

                if isAminoAcid == true {
                    aminoAcidElements[symbol] = Int(number)
                }
                
                else if isModification == true {
                    modificationElements[symbol] = Int(number)
                }
            }
        }

        else if elementName == aminoAcid {
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
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if elementName == neutralLoss {
            isNeutralLoss = false
        }
        
        else if elementName == modification {
            if modificationName.isEmpty == false {
                let mod = Modification(name: modificationName, elements: modificationElements, sites: modificationSites)

                uniModifications.append(mod)
                
                modificationName.removeAll()
                modificationSites.removeAll()
                modificationElements.removeAll()
                
                isModification = false
            }
        }
            
        else if elementName == aminoAcid {
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
