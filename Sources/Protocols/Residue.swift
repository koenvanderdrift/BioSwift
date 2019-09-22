//
//  Residue.swift
//  BioSwift
//
//  Created by Koen van der Drift on 9/21/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

protocol Residue {
    var oneLetterCode: String { get }
    var threeLetterCode: String { get }
    
    var groups: [FunctionalGroup] { get set }
}
