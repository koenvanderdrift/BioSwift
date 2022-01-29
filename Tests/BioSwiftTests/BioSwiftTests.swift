@testable import BioSwift
import XCTest

final class BioSwiftTests: XCTestCase {
    
    var protein = Protein()
    var peptide = Peptide()

    override func setUp() {
        super.setUp()

        self.protein = Protein(sequence: "MPSSVSWGILLLAGLCCLVPVSLAEDPQGDAAQKTDTSHHDQDHPTFNKITPNLAEFAFSLYRQLAHQSNSTNIFFSPVSIATAFAMLSLGTKADTHDEILEGLNFNLTEIPEAQIHEGFQELLRTLNQPDSQLQLTTGNGLFLSEGLKLVDKFLEDVKKLYHSEAFTVNFGDTEEAKKQINDYVEKGTQGKIVDLVKELDRDTVFALVNYIFFKGKWERPFEVKDTEEEDFHVDQVTTVKVPMMKRLGMFNIQHCKKLSSWVLLMKYLGNATAIFFLPDEGKLQHLENELTHDIITKFLENEDRRSASLHLPKLSITGTYDLKSVLGQLGITKVFSNGADLSGVTEEAPLKLSKAVHKAVLTIDEKGTEAAGAMFLEAIPMSIPPEVKFNKPFVFLMIEQNTKSPLFMGKVVNPTQK")
        
        self.peptide = Peptide(sequence: "DWSSD")
    }

    func testSequenceLength() {
        XCTAssertEqual(peptide.sequenceString.count, 5)
    }

//    func testSequenceLengthWithIllegalCharacters() {
//        let protein = Protein(sequence: "D___WS83SD")
//        XCTAssertEqual(protein.sequenceString.count, 5)
//    }

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
    
/*
                        MH+1 (av)   MH+1 (mono)
     protpros            609.5731    609.2151
     molmass             609.5636    609.2156
     sysbiol             609.56940   609.21514
     bioswift (-el)      609.563     609.2151
     bioswift            609.5635    609.2156
     bioswift (+el)      609.5641    609.2162
*/

    func testPeptideMonoisotopicMass() {
        peptide.setAdducts(type: protonAdduct, count: 1)
        
        XCTAssertEqual(peptide.pseudomolecularIon().monoisotopicMass.roundedDecimalAsString(to: 4), "609.2151")
    }

    func testPeptideAverageMass() {
        peptide.setAdducts(type: protonAdduct, count: 1)
        
        XCTAssertEqual(peptide.pseudomolecularIon().averageMass.roundedDecimalAsString(to: 4), "609.5636")
    } // 609.563

    func testPeptideSerinePhosphorylationMonoisotopicMass() {
        if let phos = modificationLibrary.filter({ $0.name.contains("Phospho") == true }).first {
            peptide.addModification(LocalizedModification(phos, at: 3)) // zero-based
            peptide.setAdducts(type: protonAdduct, count: 1)

            XCTAssertEqual(peptide.pseudomolecularIon().monoisotopicMass.roundedDecimalAsString(to: 4), "689.1814")

            peptide.setAdducts(type: protonAdduct, count: 2)

            XCTAssertEqual(peptide.pseudomolecularIon().monoisotopicMass.roundedDecimalAsString(to: 4), "345.0944")
        }
    }
    
//    func testBioMolecule() {
//        var bm = protein
//    }

    func testProteinMonoisotopicMass() {
        if var chain = protein.chains.first {
            chain.setAdducts(type: protonAdduct, count: 1)
            XCTAssertEqual(chain.pseudomolecularIon().monoisotopicMass.roundedDecimalAsString(to: 4), "46708.0267")
        }
    }

    func testProteinAverageMass() {
        if var chain = protein.chains.first {
            chain.setAdducts(type: protonAdduct, count: 1)
            XCTAssertEqual(chain.pseudomolecularIon().averageMass.roundedDecimalAsString(to: 4), "46737.9568")
        }
    } // 46737.0703
    
    
    func testProteinFormula() {
        if var chain = protein.chains.first {
            chain.setAdducts(type: protonAdduct, count: 1)
            XCTAssertEqual(chain.formula.countedElements().count(for: "C"), 211)
        }
        
//        XCTAssertEqual(protein.formula, Formula.init("C2112H3314N539O629S13"))
    } // C2112H3313N539O629S13

    func testProteinAtomCount() {
        if var chain = protein.chains.first {
            chain.setAdducts(type: protonAdduct, count: 1)
            XCTAssertEqual(chain.formula.elements.count, 6606)
        }
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
       XCTAssertEqual(methyl.averageMass.roundedDecimalAsString(to: 4), "15.0346")
    }
}
