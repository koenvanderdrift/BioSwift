//
//  UnimodParser.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/14/20.
//  Copyright © 2020 Koen van der Drift. All rights reserved.
//

import Foundation

public var uniModifications = [Modification]()

private let modificationElement = "umod:mod"
private let specificityElement = "umod:specificity"
private let neutralLossElement = "umod:NeutralLoss"
private let elementElement = "umod:element"

private let modificationTitleAttributeKey = "title"
private let modificationSiteAttributeKey = "site"
private let classificationAttributeKey = "classification"
private let symbolAttributeKey = "symbol"
private let numberAttributeKey = "number"

private let unknownTitle = "Unknown"
private let xlinkTitle = "Xlink"

private let skipTitleStrings = [unknownTitle, xlinkTitle]

public class UnimodParser: NSObject {
    let parser: XMLParser
    
    var elementSymbol = ""
    var elementFullName = ""
    var elementMonoisotopicMass = ""
    var elementAverageMass = ""
    
    var modificationName = ""
    var modificationSites = [String]()
    var modificationElements = [String : Int]()
    var isNeutralLoss = false
    
    public init(xml: String) {
        let xmlData = xml.data(using: String.Encoding.utf8)!
        parser = XMLParser(data: xmlData)
        
        super.init()
        
        parser.delegate = self
    }
    
    public func parseXML() {
        parser.parse()
    }
    
    // MARK: XML Parser Delegate
}

extension UnimodParser: XMLParserDelegate {
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        if elementName == modificationElement {
            if let title = attributeDict[modificationTitleAttributeKey],
                shouldUse(title) {
                modificationName = title
            }
        }
            
        else if elementName == specificityElement {
            if let site = attributeDict[modificationSiteAttributeKey],
                let classification = attributeDict[classificationAttributeKey], classification.contains("Isotopic label") == false {
                modificationSites.append(site)
            }
        }
            
        else if elementName == neutralLossElement {
            isNeutralLoss = true
        }
            
        else if elementName == elementElement {
            if isNeutralLoss == false, let symbol = attributeDict[symbolAttributeKey],
                let number = attributeDict[numberAttributeKey] {
                modificationElements[symbol] = Int(number)
            }
        }
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if elementName == neutralLossElement {
            isNeutralLoss = false
        }
        
        else if elementName == modificationElement {
            if modificationName.isEmpty == false {
                let mod = Modification(name: modificationName, dict: modificationElements, sites: modificationSites)
                uniModifications.append(mod)
                
                modificationName.removeAll()
                modificationSites.removeAll()
                modificationElements.removeAll()
            }
        }
    }
    
    private func shouldUse(_ title: String) -> Bool {
        return skipTitleStrings.contains(where: title.hasPrefix) == false
    }
}
