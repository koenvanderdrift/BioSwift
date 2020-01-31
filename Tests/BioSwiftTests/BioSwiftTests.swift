import XCTest
@testable import BioSwift

final class BioSwiftTests: XCTestCase {
    func testProteinLength() {
        let protein = Protein(sequence: "DWSSD")
        XCTAssertEqual(protein.sequenceString.count, 5)
    }
    
    func testProteinLengthWithIllegalCharacters() {
        let protein = Protein(sequence: "D___WS83SD")
        XCTAssertEqual(protein.sequenceString.count, 5)
    }
    
    func testProteinMonoisotopicMass() {
        var protein = Protein(sequence: "DWSSD")
        protein.addCharge(protonAdduct)

        XCTAssertEqual(protein.pseudomolecularIon().monoisotopicMass.roundedString(4), "609.2151")
    }
    
    func testProteinAverageMass() {
        var protein = Protein(sequence: "DWSSD")
        protein.addCharge(protonAdduct)

        XCTAssertEqual(protein.pseudomolecularIon().averageMass.roundedString(4), "609.5731")
    }// -0.0099

    func testProteinSerinePhosphorylationMonoisotopicMass() {
        var protein = Protein(sequence: "DWSSD")
        let site = 4
        
        protein.addModification(with: "Phosphorylation", at: site - 1) // zero-based
        protein.addCharge(protonAdduct)

        XCTAssertEqual(protein.pseudomolecularIon().monoisotopicMass.roundedString(4), "689.1814")

        protein.addCharge(protonAdduct)

        XCTAssertEqual(protein.pseudomolecularIon().monoisotopicMass.roundedString(4), "345.0944")
    }
    
    func testAntiTrypsinMonoisotopicMass() {
        var protein = Protein(sequence: "MPSSVSWGILLLAGLCCLVPVSLAEDPQGDAAQKTDTSHHDQDHPTFNKITPNLAEFAFSLYRQLAHQSNSTNIFFSPVSIATAFAMLSLGTKADTHDEILEGLNFNLTEIPEAQIHEGFQELLRTLNQPDSQLQLTTGNGLFLSEGLKLVDKFLEDVKKLYHSEAFTVNFGDTEEAKKQINDYVEKGTQGKIVDLVKELDRDTVFALVNYIFFKGKWERPFEVKDTEEEDFHVDQVTTVKVPMMKRLGMFNIQHCKKLSSWVLLMKYLGNATAIFFLPDEGKLQHLENELTHDIITKFLENEDRRSASLHLPKLSITGTYDLKSVLGQLGITKVFSNGADLSGVTEEAPLKLSKAVHKAVLTIDEKGTEAAGAMFLEAIPMSIPPEVKFNKPFVFLMIEQNTKSPLFMGKVVNPTQK")
        
        protein.addCharge(protonAdduct)

        XCTAssertEqual(protein.pseudomolecularIon().monoisotopicMass.roundedString(4), "46708.0267")
    }

    func testAntiTrypsinAverageMass() {
        var protein = Protein(sequence: "MPSSVSWGILLLAGLCCLVPVSLAEDPQGDAAQKTDTSHHDQDHPTFNKITPNLAEFAFSLYRQLAHQSNSTNIFFSPVSIATAFAMLSLGTKADTHDEILEGLNFNLTEIPEAQIHEGFQELLRTLNQPDSQLQLTTGNGLFLSEGLKLVDKFLEDVKKLYHSEAFTVNFGDTEEAKKQINDYVEKGTQGKIVDLVKELDRDTVFALVNYIFFKGKWERPFEVKDTEEEDFHVDQVTTVKVPMMKRLGMFNIQHCKKLSSWVLLMKYLGNATAIFFLPDEGKLQHLENELTHDIITKFLENEDRRSASLHLPKLSITGTYDLKSVLGQLGITKVFSNGADLSGVTEEAPLKLSKAVHKAVLTIDEKGTEAAGAMFLEAIPMSIPPEVKFNKPFVFLMIEQNTKSPLFMGKVVNPTQK")
    
        protein.addCharge(protonAdduct)

        XCTAssertEqual(protein.pseudomolecularIon().averageMass.roundedString(4), "46737.9568")
    }
    
    func testFormulaAverageMass() { // C6H6O6N
        let group = FunctionalGroup(name: "", formula: Formula(stringValue: "C6H6O6N6"))
        XCTAssertEqual(group.averageMass.roundedString(4), "258.1487")
    }

    
    func testWaterAverageMass() { // H2O
        XCTAssertEqual(water.averageMass.roundedString(4), "18.0153")
    }
    
    func testAmmoniaAverageMass() { // NH3
        XCTAssertEqual(ammonia.averageMass.roundedString(5), "17.03053")
    }

    func testMethylAverageMass() { // CH3
        debugPrint(methyl.masses)
        XCTAssertEqual(methyl.averageMass.roundedString(5), "15.03456")
    }
}

