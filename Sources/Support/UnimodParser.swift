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
    var reactions = [Reaction]()
    
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
            if let title = attributeDict["title"] {
                name = title
            }
        }
        
        else if elementName == "umod:specificity" {
            if let site = attributeDict["site"], let classification = attributeDict["classification"] {
                if classification.contains("Isotopic label") == false {
                    sites.append(site)
                }
            }
        }
        
        else if elementName == "umod:element" {
            if let symbol = attributeDict["symbol"], let number = attributeDict["number"] {
                delta[symbol] = Int(number)
            }
        }
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if elementName == "umod:mod" {
            
            // todo -> move this code to Formula
            let negativeElements = delta.filter({ $0.value < 0 })
            if negativeElements.count > 0 {
                var formula = ""
                for (element, count) in negativeElements {
                    formula.append(element)
                    if count > 1 {
                        formula.append(String(abs(count)))
                    }
                }
                
                let group = FunctionalGroup(name: "", formula: Formula(formula))
                reactions.append(Reaction.remove(group))
            }
            
            let postiveElements = delta.filter { $0.value > 0 }
            if postiveElements.count > 0 {
                var formula = ""
                for (element, count) in postiveElements {
                    formula.append(element)
                    if count > 1 {
                        formula.append(String(abs(count)))
                    }
                }
                
                let group = FunctionalGroup(name: "", formula: Formula(formula))
                reactions.append(Reaction.add(group))
            }
            
            let mod = Modification(name: name, reactions: reactions, sites: sites)
            uniModifications.append(mod)
            
            name = ""
            sites.removeAll()
            delta.removeAll()
            reactions.removeAll()
        }
    }
}
