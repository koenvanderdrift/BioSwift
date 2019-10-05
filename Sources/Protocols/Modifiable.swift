//
//  Modifiable.swift
//  BioSwift
//
//  Created by Koen van der Drift on 10/5/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

protocol Modifiable {
    var modifications: [Modification] { get set }
}

extension Modifiable {
    public func modificationMasses() -> MassContainer {
        return modifications.reduce(zeroMass, {$0 + $1.group.masses})
    }
}
