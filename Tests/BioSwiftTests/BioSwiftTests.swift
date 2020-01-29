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
        var protein = Protein(sequence: "DWSSD")
        protein.addCharge(protonAdduct)

        XCTAssertEqual(protein.pseudomolecularIon().monoisotopicMass.roundToDecimal(4), 609.2151)
    }
    
    func testProteinSerinePhosphorylationAverageMass() {
        var protein = Protein(sequence: "DWSSD")
        let site = 4
        
        protein.addModification(with: "Phosphorylation", at: site - 1) // zero-based
        protein.addCharge(protonAdduct)

        XCTAssertEqual(protein.pseudomolecularIon().monoisotopicMass.roundToDecimal(4), 689.1814)

        protein.addCharge(protonAdduct)
        
        XCTAssertEqual(protein.pseudomolecularIon().monoisotopicMass.roundToDecimal(4), 345.0944)
    }
    
    

    static var allTests = [
        ("testExample", testExample),
    ]
}
