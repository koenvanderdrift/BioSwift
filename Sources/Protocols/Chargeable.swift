//
//  Chargeable.swift
//  BioSwift
//
//  Created by Koen van der Drift on 9/29/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public typealias Adduct = (group: FunctionalGroup, charge: Int)
public let protonAdduct = (group: proton, charge: 1)
public let sodiumAdduct = (group: sodium, charge: 1)
public let ammoniumAdduct = (group: ammonium, charge: 1)

public protocol Chargeable: Mass {
    var adducts: [Adduct] { get set }
}

extension Chargeable {
    public func mass(over charge: Int) -> MassContainer {
        let masses = calculateMasses()
        
        if charge == 0 {
            return masses
        }
        
        return masses / charge
    }
    
    public func pseudomolecularIon() -> MassContainer {
        var charge = 0
        
        for adduct in adducts {
            charge += adduct.charge
        }
        
        return mass(over: charge)
    }
}

extension Collection where Element: BioSequence & Chargeable {
    public func charge(minCharge: Int, maxCharge: Int) -> [Element] {
        return self.flatMap { item in
            (minCharge...maxCharge).map { charge in
                var el = Element.init(sequence: item.sequenceString)
                el.adducts.append(contentsOf: repeatElement(protonAdduct, count: charge))
                
                return el
            }
        }
    }
}

