//
//  Fragment.swift
//  BioSwift
//
//  Created by Koen van der Drift on 4/12/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public enum FragmentType { // this is only for peptides...
    case precursorIon
//    case precursorIonMinusWater
//    case precursorIonMinusAmmonia
    case immoniumIon
    case aIon
//    case aIonMinusWater
//    case aIonMinusAmmonia
    case bIon
//    case bIonMinusWater
//    case bIonMinusAmmonia
    case cIon
//    case cIonMinusWater
//    case cIonMinusAmmonia
    case yIon
//    case yIonMinusWater
//    case yIonMinusAmmonia
    case xIon
//    case xIonMinusWater
//    case xIonMinusAmmonia
    case zIon
//    case zIonMinusWater
//    case zIonMinusAmmonia
    case undefined
}

public protocol Fragment {
    var fragmentType: FragmentType { get set }
}
