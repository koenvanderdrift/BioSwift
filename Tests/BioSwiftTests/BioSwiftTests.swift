import XCTest
@testable import BioSwift

final class BioSwiftTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(BioSwift().text, "Hello, World!")
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
        let site = 5
        
        protein.addModification(with: "Phosphorylation", at: site - 1) // zero-based
        XCTAssertEqual(protein.masses.averageMass.roundToDecimal(4), 688.5357)
    }
    
    

    static var allTests = [
        ("testExample", testExample),
    ]
}
