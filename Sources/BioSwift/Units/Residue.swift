//
//  Residue.swift
//  BioSwift
//
//  Created by Koen van der Drift on 9/21/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public protocol Residue: Symbol, Structure, Modifiable {
    var oneLetterCode: String { get }
    var threeLetterCode: String { get }
    var modification: Modification? { get set }
}

public extension Residue {
    var identifier: String {
        oneLetterCode
    }

    var masses: MassContainer {
        calculateMasses()
    }
}

//public protocol Residue: Structure, Symbol, Modifiable {
//    var oneLetterCode: String { get }
//    var threeLetterCode: String { get }
//    var modification: Modification? { get set }
//}
//
//public extension Residue {
//    var identifier: String {
//        oneLetterCode
//    }
//}
