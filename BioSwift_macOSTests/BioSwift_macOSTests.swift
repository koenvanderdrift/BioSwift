//
//  BioSwift_macOSTests.swift
//  BioSwift_macOSTests
//
//  Created by Koen van der Drift on 1/27/20.
//  Copyright © 2020 Koen van der Drift. All rights reserved.
//

import XCTest
@testable import BioSwift_macOS

class BioSwift_macOSTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testProteinLength() {  
        let protein = Protein(sequence: "DWSSD")
        XCTAssertEqual(protein.sequenceString.count, 5)
    }
    
    func testProteinLengthWithIllegalCharacters() {
        let protein = Protein(sequence: "D___WS83SD")
        XCTAssertEqual(protein.sequenceString.count, 5)
    }

    func testProteinAverageMass() {
        let protein = Protein(sequence: "DWSSD")
        XCTAssertEqual(protein.masses.averageMass.roundToDecimal(4), 608.5558)
    }
    
    func testProteinSerinePhosphorylationAverageMass() {
        let protein = Protein(sequence: "DWSSD")
        protein.addModification(with: "Phosphorylation", at: 4)
        XCTAssertEqual(protein.masses.averageMass.roundToDecimal(4), 688.5357)
    }



}
