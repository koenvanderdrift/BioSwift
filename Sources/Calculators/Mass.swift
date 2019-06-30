////
////  Mass.swift
////  BioSwift
////
////  Created by Koen van der Drift on 1/31/19.
////  Copyright © 2019 Koen van der Drift. All rights reserved.
////
//
// import Foundation
//
// protocol Mass {
//    // element has isotopes -> stored once in the dictionary
//    // aminoAcid has elements -> stored once in the dictionary
//    // molecule has elements (counted set)
//    // functional group has elements
//    // struct molecule, typealisas -> functional group, amino acid
//    // protein has aminoacids (counted set)
//    // protein, aminoacid has functional groups
//    // do not add and remove symbols from a molecule, keep each item independent
//
//    // only calc if MassContainer of self is empty
//    // what if charge changes? Just return a new MassContainer with updated charge
//    // original MassContainer will remain intact
//    // when to recalculate? Everytime the number is needed?
//    // mass calculation is fast, don't fret about it
//
//    // TODO:
//    // calculateMasses() needs to return an optional
//    // molecularWeight() needs to check if self.masses is empty
//    // harmonize all conforming to Mass protocol
//    // rethink calculateMasses() in Element
//    // rename calculateMasses() to calculateMass()
//
////    var id: String { get }
//
//    var masses: MassContainer { get }
//
//    func symbolSet() -> CountedSet<String>?
//    func symbolArray() -> [Mass]?
// }
//
// extension Mass {
//    public func molecularWeight() -> MassContainer {
//        return calculateMasses()
//    }
//
//    public func calculateMasses() -> MassContainer {
//        guard
//            let symbolSet = symbolSet(),
//            let symbolArray = symbolArray()
//        else { return zeroMass }
//
//        var result = zeroMass
//        for symbol in symbolArray {
//            if let symbol = symbol as? BioSymbol & Mass {
//                let count = symbolSet.count(for: symbol.identifier)
//                let masses = symbol.masses
//
//                result += count * masses
//
//            }
//         }
//
//        return result
//    }
//
//    // THIS SHOULD BE IN MASS CONTAINER
//    public func massOverCharge(charge _: Int) -> MassContainer {
//        if masses.charge == 0 {
//            return masses
//        }
//
//        return masses / masses.charge
//    }
//
////    func charge(minCharge: Int, maxCharge: Int, adduct: Mass) -> [Mass] {
////        var chargedMass = [Mass]()
////
////        for z in minCharge..<maxCharge {
////            chargedMass.append(self.pseudoMolecularIon(charge: z, adduct: adduct) as! Mass)
////        }
////
////        return chargedMass
////    }
//
////    static func charge<T:Mass>(_ item: T, inCharges charges: [Int]) -> [T] {
////        var chargedItems = [T]()
////        for z in charges {
////            chargedItems.append(self.pseudoMolecularIon(charge: z, adduct: proton))
////        }
////
////        return chargedItems
////    }
// }
//
//// extension Collection where Iterator.Element == Mass {
////    func charge<T>(minCharge: Int, maxCharge: Int, adduct: Mass) -> [T] {
////        var items = [T]()
////
////        for charge in minCharge...maxCharge {
////            let chargedItems = map { (item) -> T in
////                var chargedItem = item
////                chargedItem.masses = chargedItem.pseudoMolecularIon(charge: charge, adduct: adduct)
////
////                return chargedItem as! T
////            }
////
////            items.append(contentsOf: chargedItems)
////        }
////
////        return items
////    }
//// }
