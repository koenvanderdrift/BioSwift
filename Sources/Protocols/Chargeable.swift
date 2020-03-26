//
//  Chargeable.swift
//  BioSwift
//
//  Created by Koen van der Drift on 9/29/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public typealias Adduct = (group: FunctionalGroup, charge: Int)

public let protonAdduct = Adduct(group: proton, charge: 1)
public let sodiumAdduct = Adduct(group: sodium, charge: 1)
public let ammoniumAdduct = Adduct(group: ammonium, charge: 1)

public protocol Chargeable: Mass {
    var adducts: [Adduct] { get set }
}

extension Chargeable {    
    public mutating func addCharge(_ adduct: Adduct) {
        adducts.append(adduct)
    }
    
    public func pseudomolecularIon() -> MassContainer {
        return calculateMasses().charged(with: adducts)
    }
    
    public var charge: Int {
        return adducts.reduce(0, { $0 + $1.charge })
    }
}

extension Collection where Element: BioSequence & Chargeable {
    public func charge(minCharge: Int, maxCharge: Int) -> [Element] {
        return self.flatMap { item in
            (minCharge...maxCharge).map { charge in
                var el = Element.init(residues: item.residueSequence)
                el.termini = item.termini

                el.adducts.append(contentsOf: repeatElement(protonAdduct, count: charge))
                
                return el
            }
        }
    }
}

