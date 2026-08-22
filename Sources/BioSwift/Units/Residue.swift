//
//  Residue.swift
//  BioSwift
//
//  Created by Koen van der Drift on 9/21/19.
//  Copyright © 2019 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

/// Residue is a building block for a ``Chain``
///
public protocol Residue: Symbol, Structure, Hashable {
    var oneLetterCode: String {
        get
    }

    var threeLetterCode: String {
        get
    }

    var modification: Modification? {
        get set
    }
}

extension Residue {
    public var identifier: String {
        oneLetterCode
    }

    public var description: String {
        threeLetterCode
    }

    public var masses: MassContainer {
        formula.masses + modificationMasses()
    }

    public func modificationMasses() -> MassContainer {
        modification?.masses ?? zeroMass
    }

    public func allowedModifications() -> [Modification] {
        allowedModifications(modifications: ModificationReferenceDefaults.bundled)
    }

    public func allowedModifications(modifications: ModificationReferences) -> [Modification] {
        modifications.modifications(applicableTo: identifier)
    }
}

extension Residue {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.threeLetterCode == rhs.threeLetterCode
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(threeLetterCode)
    }
}
