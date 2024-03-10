//
//  Chargeable.swift
//  BioSwift
//
//  Created by Koen van der Drift on 9/29/19.
//  Copyright © 2019 - 2024 Koen van der Drift. All rights reserved.
//

import Foundation

public typealias Adduct = (group: FunctionalGroup, charge: Int)

public let protonAdduct = Adduct(group: proton, charge: 1)
public let sodiumAdduct = Adduct(group: sodium, charge: 1)
public let ammoniumAdduct = Adduct(group: ammonium, charge: 1)

public protocol ChargedMass: Mass {
    var adducts: [Adduct] { get set }
}

public extension ChargedMass {
    var charge: Int {
        adducts.reduce(0) { $0 + $1.charge }
    }

    mutating func setAdducts(type: Adduct, count: Int) {
        adducts = [Adduct](repeating: type, count: count)
    }

    func pseudomolecularIon() -> MassContainer {
        chargedMass()
    }

    func chargedMass() -> MassContainer {
        let result = calculateMasses()

        if adducts.count > 0 {
            let chargedMass = (
                result + adducts.map { $0.group.masses - ($0.charge * electron) }
                    .reduce(zeroMass) { $0 + $1 }
            ) / adducts.count

            return chargedMass
        }

        return result
    }
}

public extension Collection where Element: ChargedMass {
    func charge(minCharge: Int, maxCharge: Int) -> [Element] {
        flatMap { sequence in
            (minCharge ... maxCharge).map { charge in
                var chargedSequence = sequence
                chargedSequence.adducts.append(contentsOf: repeatElement(protonAdduct, count: charge))

                return chargedSequence
            }
        }
    }
}
