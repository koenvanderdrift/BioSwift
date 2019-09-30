//
//  BioSequence.swift
//  BioSwift
//
//  Created by Koen van der Drift on 5/22/17.
//  Copyright © 2017 Koen van der Drift. All rights reserved.
//

import Foundation

public enum SequenceType {
    case protein
    case dna
    case rna
    case undefined
}

public protocol BioSequence {
    var sequenceType: SequenceType { get }
    var symbolLibrary: [Symbol] { get }
    var sequenceString: String { get set }
    var modifications: [Modification] { get set }

    func symbolSequence() -> [Symbol]?
    func symbolSet() -> SymbolSet?
    func symbol(at index: Int) -> Symbol?
    
    init(sequenceString: String)
}

extension BioSequence {
    public func symbolSequence() -> [Symbol]? {
        let result = sequenceString.map { s in
            return symbolLibrary.first(where: { $0.identifier == String(s) })
        }

        return result as? [Symbol]
    }
    
    public func symbolSet() -> SymbolSet? {
        guard let symbols = symbolSequence() else { return nil }

        return SymbolSet(array: symbols)
    }

    public func symbol(at index: Int) -> Symbol? {
        var result: Symbol? = nil

        if !sequenceString.isEmpty {
            result = symbolLibrary.first(where: { $0.identifier == String(sequenceString[index]) })
        }

        return result
    }
    
    public func subSymbolSequence(from: Int, to: Int) -> [Symbol] {
        return Array((symbolSequence()?[from...to])!)
    }
    
    public func symbolLocations(with identifiers: [String]) -> [Int] {
        guard let enumeratedSymbols = symbolSequence()?.enumerated() else { return [] }

        var locations: [Int] = []

        for identifier in identifiers {
            let indices = enumeratedSymbols.filter {
                $0.element.identifier == identifier
            }

            locations += indices.map{ $0.offset }
        }

        return locations
    }
    
    public func possibleFunctionalGroups(at index: Int) -> [FunctionalGroup]? {
        if let symbol = symbol(at: index) {
            var possibleFunctionalGroups = functionalGroupLibrary.filter { $0.sites.contains(symbol.identifier) == true }
            // add N and C term groups
            if index == 0 {
                let nTermGroups = functionalGroupLibrary.filter { $0.sites.contains("NTerminal") == true }
                possibleFunctionalGroups.append(contentsOf: nTermGroups)
            }

            if index == sequenceString.count - 1 {
                let cTermGroups = functionalGroupLibrary.filter { $0.sites.contains("CTerminal") == true }
                possibleFunctionalGroups.append(contentsOf: cTermGroups)
            }

            return possibleFunctionalGroups
        }

        return nil
    }
}

//    public func addModification(with name: String, at location: Int = -1) {
//        if let group = functionalGroupLibrary.first(where: { $0.name == name }),
//            let residue = symbol(at: location) as? Residue {
//            residue.groups.append(group)
//        }
//    }
//
//    public func removeModification(_ modification: Modification) {
//        modifications = modifications.filter { $0 != modification }
//    }
//}




extension Collection where Element: BioSequence & Chargeable {
    public func charge(minCharge: Int, maxCharge: Int) -> [Element] {
        return self.flatMap { item in
            (minCharge...maxCharge).map { charge in
                var el = Element.init(sequenceString: item.sequenceString)
                el.adducts.append(contentsOf: repeatElement(protonAdduct, count: charge))
                return el
            }
        }
    }
}

