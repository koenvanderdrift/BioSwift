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

public class BioSequence {
    var residueSequence: [Residue]? = []

    var sequenceString: String {
        didSet {
            let result = sequenceString.map { s in
                return symbolLibrary.first(where: { $0.identifier == String(s) })
            }
            debugPrint("didSet sequence")

            residueSequence = result as? [Residue]
        }
    }
    
    var symbolSequence: [Symbol]? {
        return residueSequence
    }
    
    var sequenceType: SequenceType = .undefined
    var symbolLibrary: [Symbol] = []
    
    public var modifications: [Modification] {
        var result: [Modification] = []
        
        residueSequence?.forEach { residue in
            result.append(contentsOf: residue.modifications)
        }
        
        return result
    }    
    
    public required init(sequence: String) {
        self.sequenceString = sequence
    }
}

extension BioSequence: Equatable {
    public static func == (lhs: BioSequence, rhs: BioSequence) -> Bool {
        return lhs.sequenceString == rhs.sequenceString
    }
}

extension BioSequence {
    // this is very expensive, symbolSequence() is re-created everytime
    // better is to have a property edit directly based on old and new string
    
    public func updateSequence(with string: String) {
        sequenceString = string
    }
    
    public func symbolSet() -> SymbolSet? {
        guard let symbols = symbolSequence else { return nil }

        return SymbolSet(array: symbols)
    }
    
    public func symbols(from string: String) -> [Symbol]? {
        let result = sequenceString.map { s in
            return symbolLibrary.first(where: { $0.identifier == String(s) })
        }
        
        return result as? [Symbol]
    }

    public func symbol(at index: Int) -> Symbol? {
        var result: Symbol? = nil

        if !sequenceString.isEmpty {
            result = symbolLibrary.first(where: { $0.identifier == String(sequenceString[index]) })
        }

        return result
    }
    
    public func subSymbolSequence(from: Int, to: Int) -> [Symbol] {
        return Array((symbolSequence?[from...to])!)
    }
    
    public func symbolLocations(with identifiers: [String]) -> [Int] {
        guard let enumeratedSymbols = symbolSequence?.enumerated() else { return [] }

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

    public func add(_ modification: Modification) {
        for site in modification.sites {
            residueSequence?.modifyElement(atIndex: site) {
                let mod = Modification(group: modification.group, sites: [site])
                $0.modifications.append(mod)
            }
        }
    }

    public func remove(_ modification: Modification) {
        for site in modification.sites {
            residueSequence?.modifyElement(atIndex: site) { residue in
                residue.modifications = residue.modifications.filter { $0.sites.first != site }
            }
        }
    }
    
    public func addModification(with name: String, at location: Int = -1) {
        if let group = functionalGroupLibrary.first(where: { $0.name == name }) {
            add(Modification(group: group, sites: [location]))
        }
    }
            
    public func removeModification(with name: String, at location: Int = -1) {
        if let group = functionalGroupLibrary.first(where: { $0.name == name }) {
            remove(Modification(group: group, sites: [location]))
        }
    }
    
}

extension Array {
    mutating func modifyForEach(_ body: (_ index: Index, _ element: inout Element) -> ()) {
        for index in indices {
            modifyElement(atIndex: index) { body(index, &$0) }
        }
    }
    
    mutating func modifyElement(atIndex index: Index, _ modifyElement: (_ element: inout Element) -> ()) {
        var element = self[index]
        modifyElement(&element)
        self[index] = element
    }
}
