//
//  UnimodParser.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/14/20.
//  Copyright © 2020 Koen van der Drift. All rights reserved.
//

import Foundation

public var uniModifications = [Modification]()

public class UnimodParser: NSObject, XMLParserDelegate {
    var parser: XMLParser
    
    var name = ""
    var sites = [String]()
    var delta = [String : Int]()
    var neutralLoss = false
    
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
    
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "umod:mod" {
            if let title = attributeDict["title"],
                title.starts(with: "Unknown") == false,
                title.starts(with: "Xlink") == false {
                name = title
            }
        }
            
        else if elementName == "umod:specificity" {
            if let site = attributeDict["site"], let classification = attributeDict["classification"], classification.contains("Isotopic label") == false {
                sites.append(site)
            }
        }
            
        else if elementName == "umod:NeutralLoss" {
            neutralLoss = true
        }

        else if elementName == "umod:element" {
            if neutralLoss == false, let symbol = attributeDict["symbol"],
                let number = attributeDict["number"] {
                delta[symbol] = Int(number)
            }
        }
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if elementName == "umod:NeutralLoss" {
            neutralLoss = false
        }
        
        else if elementName == "umod:mod" {
            if name.isEmpty == false {
                let mod = Modification(name: name, dict: delta, sites: sites)
                uniModifications.append(mod)
                
                name.removeAll()
                sites.removeAll()
                delta.removeAll()
            }
        }
    }
}
