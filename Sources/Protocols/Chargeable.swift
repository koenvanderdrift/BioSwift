//
//  Chargeable.swift
//  BioSwift
//
//  Created by Koen van der Drift on 9/29/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

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
