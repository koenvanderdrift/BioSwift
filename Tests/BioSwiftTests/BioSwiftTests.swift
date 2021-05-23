@testable import BioSwift
import XCTest

final class BioSwiftTests: XCTestCase {
    override func setUp() {
        super.setUp()

        let exp = expectation(description: "BioSwiftTests setUp")

        // Issue an async request
        loadUnimod { success in
            guard success else { return }
            
            exp.fulfill()
        }

        // Wait for the async request to complete
        waitForExpectations(timeout: 1, handler: nil)
    }

    
    func testProteinLength() {
        let protein = Protein(sequence: "DWSSD")
        XCTAssertEqual(protein.sequenceString.count, 5)
    }

//    func testProteinLengthWithIllegalCharacters() {
//        let protein = Protein(sequence: "D___WS83SD")
//        XCTAssertEqual(protein.sequenceString.count, 5)
//    }

    /*
     MH+1(av)    MH+1(mono)
     protpros            609.5731    609.2151
     molmass             609.5636    609.2156
     sysbiol             609.56940   609.21514
     bioswift (-el)      609.563     609.2151
     bioswift            609.5635    609.2156
     bioswift (+el)      609.5641    609.2162

     */
//    func testFormuls() {
//        let formula = Formula("AgCuRu4(H)2[CO]12{PPh3}2")
//
//        XCTAssertEqual(formula.countFor(element: "C"), 12)
//    }
//
//    func testPeptideFormula() {
//        let peptide = Peptide(sequence: "DWSSD")
//
//        XCTAssertEqual(peptide.formula.countFor(element: "C"), 25)
//    }
//
    func testPeptideMonoisotopicMass() {
        var peptide = Peptide(sequence: "DWSSD")
        peptide.setAdducts(type: protonAdduct, count: 1)
        XCTAssertEqual(peptide.pseudomolecularIon().monoisotopicMass.roundedDecimalAsString(to: 4), "609.2151")
    }

    func testPeptideAverageMass() {
        var peptide = Peptide(sequence: "DWSSD")
        peptide.setAdducts(type: protonAdduct, count: 1)

        XCTAssertEqual(peptide.pseudomolecularIon().averageMass.roundedDecimalAsString(to: 4), "609.5636")
    } // 609.563

    func testPeptideSerinePhosphorylationMonoisotopicMass() {
        var peptide = Peptide(sequence: "DWSSD")

        if let phos = uniModifications.filter({ $0.name.contains("Phospho") == true }).first {
//            phos.location = 3
//            let site = 4
            peptide.addModification(Modification(modification: phos, location: 3))// zero-based
            peptide.setAdducts(type: protonAdduct, count: 1)

            XCTAssertEqual(peptide.pseudomolecularIon().monoisotopicMass.roundedDecimalAsString(to: 4), "689.1814")

            peptide.setAdducts(type: protonAdduct, count: 2)

            XCTAssertEqual(peptide.pseudomolecularIon().monoisotopicMass.roundedDecimalAsString(to: 4), "345.0944")
        }
    }
    
    func testBioMolecule() {
        let protein = Protein(sequence: "MPSSVSWGILLLAGLCCLVPVSLAEDPQGDAAQKTDTSHHDQDHPTFNKITPNLAEFAFSLYRQLAHQSNSTNIFFSPVSIATAFAMLSLGTKADTHDEILEGLNFNLTEIPEAQIHEGFQELLRTLNQPDSQLQLTTGNGLFLSEGLKLVDKFLEDVKKLYHSEAFTVNFGDTEEAKKQINDYVEKGTQGKIVDLVKELDRDTVFALVNYIFFKGKWERPFEVKDTEEEDFHVDQVTTVKVPMMKRLGMFNIQHCKKLSSWVLLMKYLGNATAIFFLPDEGKLQHLENELTHDIITKFLENEDRRSASLHLPKLSITGTYDLKSVLGQLGITKVFSNGADLSGVTEEAPLKLSKAVHKAVLTIDEKGTEAAGAMFLEAIPMSIPPEVKFNKPFVFLMIEQNTKSPLFMGKVVNPTQK")
       
        var bm = BioMolecule<Protein>()
        bm.chains.append(protein)
    }

    func testProteinMonoisotopicMass() {
        var protein = Protein(sequence: "MPSSVSWGILLLAGLCCLVPVSLAEDPQGDAAQKTDTSHHDQDHPTFNKITPNLAEFAFSLYRQLAHQSNSTNIFFSPVSIATAFAMLSLGTKADTHDEILEGLNFNLTEIPEAQIHEGFQELLRTLNQPDSQLQLTTGNGLFLSEGLKLVDKFLEDVKKLYHSEAFTVNFGDTEEAKKQINDYVEKGTQGKIVDLVKELDRDTVFALVNYIFFKGKWERPFEVKDTEEEDFHVDQVTTVKVPMMKRLGMFNIQHCKKLSSWVLLMKYLGNATAIFFLPDEGKLQHLENELTHDIITKFLENEDRRSASLHLPKLSITGTYDLKSVLGQLGITKVFSNGADLSGVTEEAPLKLSKAVHKAVLTIDEKGTEAAGAMFLEAIPMSIPPEVKFNKPFVFLMIEQNTKSPLFMGKVVNPTQK")

        protein.setAdducts(type: protonAdduct, count: 1)

        XCTAssertEqual(protein.pseudomolecularIon().monoisotopicMass.roundedDecimalAsString(to: 4), "46708.0267")
    }

    func testProteinAverageMass() {
        var protein = Protein(sequence: "MPSSVSWGILLLAGLCCLVPVSLAEDPQGDAAQKTDTSHHDQDHPTFNKITPNLAEFAFSLYRQLAHQSNSTNIFFSPVSIATAFAMLSLGTKADTHDEILEGLNFNLTEIPEAQIHEGFQELLRTLNQPDSQLQLTTGNGLFLSEGLKLVDKFLEDVKKLYHSEAFTVNFGDTEEAKKQINDYVEKGTQGKIVDLVKELDRDTVFALVNYIFFKGKWERPFEVKDTEEEDFHVDQVTTVKVPMMKRLGMFNIQHCKKLSSWVLLMKYLGNATAIFFLPDEGKLQHLENELTHDIITKFLENEDRRSASLHLPKLSITGTYDLKSVLGQLGITKVFSNGADLSGVTEEAPLKLSKAVHKAVLTIDEKGTEAAGAMFLEAIPMSIPPEVKFNKPFVFLMIEQNTKSPLFMGKVVNPTQK")

        protein.setAdducts(type: protonAdduct, count: 1)

        XCTAssertEqual(protein.pseudomolecularIon().averageMass.roundedDecimalAsString(to: 4), "46737.9568")
    } // 46737.0703
    
    
    func testProteinFormula() {
        var protein = Protein(sequence: "MPSSVSWGILLLAGLCCLVPVSLAEDPQGDAAQKTDTSHHDQDHPTFNKITPNLAEFAFSLYRQLAHQSNSTNIFFSPVSIATAFAMLSLGTKADTHDEILEGLNFNLTEIPEAQIHEGFQELLRTLNQPDSQLQLTTGNGLFLSEGLKLVDKFLEDVKKLYHSEAFTVNFGDTEEAKKQINDYVEKGTQGKIVDLVKELDRDTVFALVNYIFFKGKWERPFEVKDTEEEDFHVDQVTTVKVPMMKRLGMFNIQHCKKLSSWVLLMKYLGNATAIFFLPDEGKLQHLENELTHDIITKFLENEDRRSASLHLPKLSITGTYDLKSVLGQLGITKVFSNGADLSGVTEEAPLKLSKAVHKAVLTIDEKGTEAAGAMFLEAIPMSIPPEVKFNKPFVFLMIEQNTKSPLFMGKVVNPTQK")

        protein.setAdducts(type: protonAdduct, count: 1)
        
 //       XCTAssertEqual(protein.formula, Formula.init("C2112H3314N539O629S13"))
    } // C2112H3313N539O629S13

    func testProteinAtomCount() {
        var protein = Protein(sequence: "MPSSVSWGILLLAGLCCLVPVSLAEDPQGDAAQKTDTSHHDQDHPTFNKITPNLAEFAFSLYRQLAHQSNSTNIFFSPVSIATAFAMLSLGTKADTHDEILEGLNFNLTEIPEAQIHEGFQELLRTLNQPDSQLQLTTGNGLFLSEGLKLVDKFLEDVKKLYHSEAFTVNFGDTEEAKKQINDYVEKGTQGKIVDLVKELDRDTVFALVNYIFFKGKWERPFEVKDTEEEDFHVDQVTTVKVPMMKRLGMFNIQHCKKLSSWVLLMKYLGNATAIFFLPDEGKLQHLENELTHDIITKFLENEDRRSASLHLPKLSITGTYDLKSVLGQLGITKVFSNGADLSGVTEEAPLKLSKAVHKAVLTIDEKGTEAAGAMFLEAIPMSIPPEVKFNKPFVFLMIEQNTKSPLFMGKVVNPTQK")

        protein.setAdducts(type: protonAdduct, count: 1)

        XCTAssertEqual(protein.formula.elements.count, 6606)
    }
    func testFormulaAverageMass() { // C4H5NO3 + C11H10N2O + C3H5NO2 + C3H5NO2 + C4H5NO3 + H2O
//        let formula = Formula("C2112H3313N539O629S13H")
//        let masses = mass(of: formula.elements)
//        debugPrint(masses)
        let group = FunctionalGroup(name: "", formula: "C25H32N6O12")
        
        XCTAssertEqual(group.averageMass.roundedDecimalAsString(to: 4), "608.5557")
    } // 608.5556

    func testWaterAverageMass() { // H2O
        XCTAssertEqual(water.averageMass.roundedDecimalAsString(to: 4), "18.0153")
    }

    func testAmmoniaAverageMass() { // NH3
        XCTAssertEqual(ammonia.averageMass.roundedDecimalAsString(to: 4), "17.0305")
    }

    func testMethylAverageMass() { // CH3
//        XCTAssertEqual(methyl.averageMass.roundedDecimalAsString(to: 4), "15.0346")
    }
}
