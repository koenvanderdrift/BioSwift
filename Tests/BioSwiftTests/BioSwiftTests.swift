@testable import BioSwift
import XCTest

final class BioSwiftTests: XCTestCase {
    var protein = Protein()
    var peptide = Peptide()

    override func setUp() {
        super.setUp()

        // https://stackoverflow.com/questions/29504712/how-can-i-get-xctest-to-wait-for-async-calls-in-setup-before-tests-are-run
        debugPrint("test setup")
        let exp = expectation(description: "BioSwiftTests setUp")

        dataLibrary.loadUnimod { success in
            guard success else { return }

            self.protein = Protein(sequence: "MPSSVSWGILLLAGLCCLVPVSLAEDPQGDAAQKTDTSHHDQDHPTFNKITPNLAEFAFSLYRQLAHQSNSTNIFFSPVSIATAFAMLSLGTKADTHDEILEGLNFNLTEIPEAQIHEGFQELLRTLNQPDSQLQLTTGNGLFLSEGLKLVDKFLEDVKKLYHSEAFTVNFGDTEEAKKQINDYVEKGTQGKIVDLVKELDRDTVFALVNYIFFKGKWERPFEVKDTEEEDFHVDQVTTVKVPMMKRLGMFNIQHCKKLSSWVLLMKYLGNATAIFFLPDEGKLQHLENELTHDIITKFLENEDRRSASLHLPKLSITGTYDLKSVLGQLGITKVFSNGADLSGVTEEAPLKLSKAVHKAVLTIDEKGTEAAGAMFLEAIPMSIPPEVKFNKPFVFLMIEQNTKSPLFMGKVVNPTQK")

            self.peptide = Peptide(sequence: "DWSSD")

            exp.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)
    }

    func testSequenceLength() {
        XCTAssertEqual(protein.sequenceLength(), 418)
        XCTAssertEqual(peptide.sequenceString.count, 5)
    }

    func testSequenceLengthWithIllegalCharacters() {
        let protein = Protein(sequence: "D___WS83SD")
        XCTAssertEqual(protein.sequenceLength(), 5)
    }

    func testFormula() {
        let formula = Formula("AgCuRu4(H)2[CO]12{PPh3}2")
        XCTAssertEqual(formula.countFor(element: "C"), 12)
    }

    func testPeptideFormula() {
        let peptide = Peptide(sequence: "DWSSD")
        XCTAssertEqual(peptide.formula.countFor(element: "C"), 25)
    }

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

    func testLoadFasta() {
        let fasta = try? parseFastaDataFromBundle(from: "ecoli")
        XCTAssertEqual(fasta?.count, 4392)

        let record = fasta?.first(where: { $0.accession == "P02919" })

        XCTAssertEqual(record?.entryName, "PBPB_ECOLI")
        XCTAssertEqual(record?.proteinName, "Penicillin-binding protein 1B")
        XCTAssertEqual(record?.organism, "Escherichia coli (strain K12)")
    }

    func testSubChain() {
        if let chain = protein.chains.first {
            let range1: ChainRange = 3...9 // 0 based
            let subChain1 = chain.subChain(removing: range1)
            XCTAssertEqual(subChain1?.sequenceString, "MPSLLAGLCCLVPVSLAEDPQGDAAQKTDTSHHDQDHPTFNKITPNLAEFAFSLYRQLAHQSNSTNIFFSPVSIATAFAMLSLGTKADTHDEILEGLNFNLTEIPEAQIHEGFQELLRTLNQPDSQLQLTTGNGLFLSEGLKLVDKFLEDVKKLYHSEAFTVNFGDTEEAKKQINDYVEKGTQGKIVDLVKELDRDTVFALVNYIFFKGKWERPFEVKDTEEEDFHVDQVTTVKVPMMKRLGMFNIQHCKKLSSWVLLMKYLGNATAIFFLPDEGKLQHLENELTHDIITKFLENEDRRSASLHLPKLSITGTYDLKSVLGQLGITKVFSNGADLSGVTEEAPLKLSKAVHKAVLTIDEKGTEAAGAMFLEAIPMSIPPEVKFNKPFVFLMIEQNTKSPLFMGKVVNPTQK")

            let range2: ChainRange = 0...9 // 0 based
            let subChain2 = chain.subChain(removing: range2)
            XCTAssertEqual(subChain2?.sequenceString, "LLAGLCCLVPVSLAEDPQGDAAQKTDTSHHDQDHPTFNKITPNLAEFAFSLYRQLAHQSNSTNIFFSPVSIATAFAMLSLGTKADTHDEILEGLNFNLTEIPEAQIHEGFQELLRTLNQPDSQLQLTTGNGLFLSEGLKLVDKFLEDVKKLYHSEAFTVNFGDTEEAKKQINDYVEKGTQGKIVDLVKELDRDTVFALVNYIFFKGKWERPFEVKDTEEEDFHVDQVTTVKVPMMKRLGMFNIQHCKKLSSWVLLMKYLGNATAIFFLPDEGKLQHLENELTHDIITKFLENEDRRSASLHLPKLSITGTYDLKSVLGQLGITKVFSNGADLSGVTEEAPLKLSKAVHKAVLTIDEKGTEAAGAMFLEAIPMSIPPEVKFNKPFVFLMIEQNTKSPLFMGKVVNPTQK")

            let range3: ChainRange = 11...400 // 1 based
            let subChain3 = chain.subChain(removing: range3, based: 1)
            XCTAssertEqual(subChain3?.sequenceString, "MPSSVSWGILQNTKSPLFMGKVVNPTQK")
        }
    }

    func testDigest() {
        if let chain = protein.chains.first {
            let missedCleavages = 1

            let trypsin = enzymeLibrary.first(where: { $0.name == "Trypsin" })

            if let regex = trypsin?.regex() {
                let peptides: [Peptide] = chain.digest(using: regex, with: missedCleavages)

                XCTAssertEqual(peptides[0].sequenceString, "MPSSVSWGILLLAGLCCLVPVSLAEDPQGDAAQK")
                XCTAssertEqual(peptides[1].sequenceString, "TDTSHHDQDHPTFNK")
            }

            let aspN = enzymeLibrary.first(where: { $0.name == "Asp-N" })

            if let regex = aspN?.regex() {
                let peptides: [Peptide] = chain.digest(using: regex, with: missedCleavages)

                let _ = print(peptides.map { $0.sequenceString })

                XCTAssertEqual(peptides[0].sequenceString, "MPSSVSWGILLLAGLCCLVPVSLAE")
                XCTAssertEqual(peptides[1].sequenceString, "DPQG")
            }
        }
    }

    func testMassSearch() {
        if let chain = protein.chains.first {
            let searchParameters = MassSearchParameters(searchValue: 609.71,
                                                        tolerance: MassTolerance(type: .ppm, value: 20),
                                                        searchType: .sequential,
                                                        massType: .monoisotopic)
            
            let peptides: [Peptide] = chain.searchMass(params: searchParameters)
            print(peptides.map { $0.sequenceString })

            XCTAssert(peptides.contains(where: { $0.sequenceString == "IFFSP" }))
        }
    }
    
    func testMassSearchWithModification() {
        if var chain = protein.chains.first,
           let phos = modificationLibrary.filter({ $0.name.contains("Phospho") == true }).first {
            
            chain.addModification(LocalizedModification(phos, at: 76)) // zero-based
            
            let searchParameters = MassSearchParameters(searchValue: 689,
                                                        tolerance: MassTolerance(type: .ppm, value: 20),
                                                        searchType: .sequential,
                                                        massType: .nominal)
            
            let peptides: [Peptide] = chain.searchMass(params: searchParameters)
            print(peptides.map { $0.sequenceString })
            
            XCTAssert(peptides.contains(where: { $0.sequenceString == "IFFSP" }))
        }
    }}
