//
//  BioSequence.swift
//  BioSwift
//
//  Created by Koen van der Drift on 5/22/17.
//  Copyright © 2017 Koen van der Drift. All rights reserved.
//

import Foundation

let protonAdduct = Modification(group: proton, location: 0)

public enum SequenceType {
    case protein
    case dna
    case rna
    case undefined
}

public class BioSequence: Mass {
    public var sequence: String
    public let type: SequenceType
    public var modifications: [Modification]

    public init(sequence: String, type: SequenceType, charge: Int = 0) {
        self.sequence = sequence
        self.type = type
        self.charge = charge
        self.modifications = []
    }

    lazy var symbolLibrary: [MassSymbol]? = {
        switch type {
        case .protein:
            return aminoAcidLibrary
            
        case .dna, .rna, .undefined:
            return nil
        }
    }()
    
    func symbolSequence() -> [MassSymbol]? {
        var result: [MassSymbol] = []

        // use map?
        for s in sequence {
            if let symbol = symbolLibrary?.first(where: { $0.identifier == String(s) }) {
                result.append(symbol)
            }
        }

        return result
    }
    
    public func symbol(at index: Int) -> MassSymbol? {
        var result: MassSymbol? = nil

        if !sequence.isEmpty {
            result = symbolLibrary?.first(where: { $0.identifier == String(sequence[index])
            })
        }

        return result
    }

    public var masses: MassContainer {
        get {
            return calculateMasses()
        }
    }

    public var charge: Int = 0 {
        didSet {
//            print(" didSet charge")
//            var mods = modifications.filter { $0 != protonAdduct }
//            for _ in 0..<charge {
//                mods.append(protonAdduct)
//            }
//          modifications = mods
        }
    }

    public func calculateMasses() -> MassContainer {
        let sequenceMass = symbolSequence()?.compactMap { $0.masses }
            .reduce(zeroMass, +) ?? zeroMass
        return sequenceMass + modificationMasses() + adductMasses() + nterm.masses + cterm.masses
    }
}

extension BioSequence {    
    private func modificationMasses() -> MassContainer {
        return modifications.reduce(zeroMass, {$0 + $1.group.masses})
    }
    
    private func adductMasses() -> MassContainer {
        // for now assume protonation only
        // adduct is a modification ?
        return charge * proton.masses
    }
}

extension BioSequence {
    public func possibleFunctionalGroups(at index: Int) -> [FunctionalGroup]? {
        if let symbol = symbol(at: index) {
            var possibleFunctionalGroups = functionalGroupLibrary.filter { $0.sites.contains(symbol.identifier) == true }
            // add N and C term groups
            if index == 0 {
                let nTermGroups = functionalGroupLibrary.filter { $0.sites.contains("NTerminal") == true }
                possibleFunctionalGroups.append(contentsOf: nTermGroups)
            }
            
            if index == sequence.count - 1 {
                let cTermGroups = functionalGroupLibrary.filter { $0.sites.contains("CTerminal") == true }
                possibleFunctionalGroups.append(contentsOf: cTermGroups)
            }
            
            return possibleFunctionalGroups
        }
        
        return nil
    }
    
//    public func addModification(with name: String, at location: Int = -1) {
//        if let group = functionalGroupsArray.first(where: { $0.name == name }) {
//            let mod = Modification(group: group, location: location, site: symbol(at: location)?.identifier ?? "")
//            modifications.append(mod)
//        }
//    }
//
//    public func removeModification(_ modification: Modification) {
//        modifications = modifications.filter { $0 != modification }
//    }
}
