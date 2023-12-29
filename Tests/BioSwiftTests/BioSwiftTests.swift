@testable import BioSwift
import XCTest

final class BioSwiftTests: XCTestCase {
    lazy var testProtein = Protein(sequence: "MPSSVSWGILLLAGLCCLVPVSLAEDPQGDAAQKTDTSHHDQDHPTFNKITPNLAEFAFSLYRQLAHQSNSTNIFFSPIVSIATAFAMLSLGTKADTHDEILEGLNFNLTEIPEAQIHEGFQELLRTLNQPDSQLQLTTGNGLFLSEGLKLVDKFLEDVKKLYHSEAFTVNFGDTEEAKKQINDYVEKGTQGKIVDLVKELDRDTVFALVNYIFFKGKWERPFEVKDTEEEDFHVDQVTTVKVPMMKRLGMFNIQHCKKLSSWVLLMKYLGNATAIFFLPDEGKLQHLENELTHDIITKFLENEDRRSASLHLPKLSITGTYDLKSVLGQLGITKVFSNGADLSGVTEEAPLKLSKAVHKAVLTIDEKGTEAAGAMFLEAIPMSIPPEVKFNKPFVFMIEQNTKSPLFMGKVVNPTQK")

    lazy var testPeptide = Peptide(sequence: "DWSSD")

    override class func setUp() {
        super.setUp()
        
        do {
            try dataLibrary.loadUnimod()
        }
        catch {
            debugPrint(error)
        }
    }

    func testSequenceLength() {
        XCTAssertEqual(testProtein.sequenceLength(), 418)
        XCTAssertEqual(testPeptide.sequenceString.count, 5)
    }
    
    func testSequenceLengthWithIllegalCharacters() {
        let protein = Protein(sequence: "D___WS83SD")
        XCTAssertEqual(protein.sequenceLength(), 5)
    }
    
    func testFormula() {
        let formula = Formula("{AgCuRu4(H)2[CO]12}2")
        XCTAssertEqual(formula.countFor(element: "C"), 24)
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
        testPeptide.setAdducts(type: protonAdduct, count: 1)
        
        XCTAssertEqual(testPeptide.pseudomolecularIon().monoisotopicMass.roundedDecimalAsString(to: 4), "609.2151")
    }
    
    func testPeptideAverageMass() {
        testPeptide.setAdducts(type: protonAdduct, count: 1)
        
        XCTAssertEqual(testPeptide.pseudomolecularIon().averageMass.roundedDecimalAsString(to: 4), "609.5636")
    } // 609.563
    
    func testPeptideSerinePhosphorylationMonoisotopicMass() {
        if let phos = modificationLibrary.filter({ $0.name.contains("Phospho") == true }).first {
            testPeptide.addModification(LocalizedModification(phos, at: 3)) // zero-based
            testPeptide.setAdducts(type: protonAdduct, count: 1)
            
            XCTAssertEqual(testPeptide.pseudomolecularIon().monoisotopicMass.roundedDecimalAsString(to: 4), "689.1814")
            
            testPeptide.setAdducts(type: protonAdduct, count: 2)
            
            XCTAssertEqual(testPeptide.pseudomolecularIon().monoisotopicMass.roundedDecimalAsString(to: 4), "345.0944")
        }
    }
    
    //    func testBioMolecule() {
    //        var bm = protein
    //    }
    
    func testProteinMonoisotopicMass() {
        if var chain = testProtein.chains.first {
            chain.setAdducts(type: protonAdduct, count: 1)
            XCTAssertEqual(chain.pseudomolecularIon().monoisotopicMass.roundedDecimalAsString(to: 4), "46708.0267")
        }
    }
    
    func testProteinAverageMass() {
        if var chain = testProtein.chains.first {
            chain.setAdducts(type: protonAdduct, count: 1)
            XCTAssertEqual(chain.pseudomolecularIon().averageMass.roundedDecimalAsString(to: 4), "46737.9568")
        }
    } // 46737.0703
    
    func testProteinFormula() {
        if var chain = testProtein.chains.first {
            chain.setAdducts(type: protonAdduct, count: 1)
            XCTAssertEqual(chain.formula.countedElements().count(for: "C"), 211)
        }
        
        //        XCTAssertEqual(protein.formula, Formula.init("C2112H3314N539O629S13"))
    } // C2112H3313N539O629S13
    
    func testProteinAtomCount() {
        if var chain = testProtein.chains.first {
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
        if let chain = testProtein.chains.first {
            let range1: ChainRange = 3 ... 9 // 0 based
            let subChain1 = chain.subChain(removing: range1)
            XCTAssertEqual(subChain1?.sequenceString, "MPSLLAGLCCLVPVSLAEDPQGDAAQKTDTSHHDQDHPTFNKITPNLAEFAFSLYRQLAHQSNSTNIFFSPVSIATAFAMLSLGTKADTHDEILEGLNFNLTEIPEAQIHEGFQELLRTLNQPDSQLQLTTGNGLFLSEGLKLVDKFLEDVKKLYHSEAFTVNFGDTEEAKKQINDYVEKGTQGKIVDLVKELDRDTVFALVNYIFFKGKWERPFEVKDTEEEDFHVDQVTTVKVPMMKRLGMFNIQHCKKLSSWVLLMKYLGNATAIFFLPDEGKLQHLENELTHDIITKFLENEDRRSASLHLPKLSITGTYDLKSVLGQLGITKVFSNGADLSGVTEEAPLKLSKAVHKAVLTIDEKGTEAAGAMFLEAIPMSIPPEVKFNKPFVFMIEQNTKSPLFMGKVVNPTQK")
            
            let range2: ChainRange = 0 ... 9 // 0 based
            let subChain2 = chain.subChain(removing: range2)
            XCTAssertEqual(subChain2?.sequenceString, "LLAGLCCLVPVSLAEDPQGDAAQKTDTSHHDQDHPTFNKITPNLAEFAFSLYRQLAHQSNSTNIFFSPVSIATAFAMLSLGTKADTHDEILEGLNFNLTEIPEAQIHEGFQELLRTLNQPDSQLQLTTGNGLFLSEGLKLVDKFLEDVKKLYHSEAFTVNFGDTEEAKKQINDYVEKGTQGKIVDLVKELDRDTVFALVNYIFFKGKWERPFEVKDTEEEDFHVDQVTTVKVPMMKRLGMFNIQHCKKLSSWVLLMKYLGNATAIFFLPDEGKLQHLENELTHDIITKFLENEDRRSASLHLPKLSITGTYDLKSVLGQLGITKVFSNGADLSGVTEEAPLKLSKAVHKAVLTIDEKGTEAAGAMFLEAIPMSIPPEVKFNKPFVFMIEQNTKSPLFMGKVVNPTQK")
            
            let range3: ChainRange = 11 ... 400 // 1 based
            let subChain3 = chain.subChain(removing: range3, based: 1)
            XCTAssertEqual(subChain3?.sequenceString, "MPSSVSWGILQNTKSPLFMGKVVNPTQK")
        }
    }
    
    func testDigest() {
        if let chain = testProtein.chains.first {
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
                
                let _ = print(peptides.map(\.sequenceString))
                
                XCTAssertEqual(peptides[0].sequenceString, "MPSSVSWGILLLAGLCCLVPVSLAE")
                XCTAssertEqual(peptides[1].sequenceString, "DPQG")
            }
        }
    }
    
    func testMassSearch() {
        if let chain = testProtein.chains.first {
            let searchParameters = MassSearchParameters(searchValue: 609.71,
                                                        tolerance: MassTolerance(type: .ppm, value: 20),
                                                        searchType: .sequential,
                                                        massType: .monoisotopic)
            
            let peptides: [Peptide] = chain.searchMass(params: searchParameters)
            print(peptides.map(\.sequenceString))
            
            XCTAssert(peptides.contains(where: { $0.sequenceString == "IFFSP" }))
        }
    }
    
    func testLowMassSearch() {
        if let chain = testProtein.chains.first {
            let searchParameters = MassSearchParameters(searchValue: 1,
                                                        tolerance: MassTolerance(type: .ppm, value: 20),
                                                        searchType: .sequential,
                                                        massType: .monoisotopic)
            
            let peptides: [Peptide] = chain.searchMass(params: searchParameters)
            print(peptides.map(\.sequenceString))
            
            XCTAssert(peptides.count == 0)
        }
    }
    
    func testMassSearchWithModification() {
        if var chain = testProtein.chains.first,
           let phos = modificationLibrary.filter({ $0.name.contains("Phospho") == true }).first
        {
            chain.addModification(LocalizedModification(phos, at: 76)) // zero-based
            
            let searchParameters = MassSearchParameters(searchValue: 689,
                                                        tolerance: MassTolerance(type: .ppm, value: 20),
                                                        searchType: .sequential,
                                                        massType: .nominal)
            
            let peptides: [Peptide] = chain.searchMass(params: searchParameters)
            print(peptides.map(\.sequenceString))
            
            XCTAssert(peptides.contains(where: { $0.sequenceString == "IFFSP" }))
        }
    }
    
    func testFragmentCount() {
        var peptide = Peptide(sequence: "SAMPLER")
        peptide.setAdducts(type: protonAdduct, count: 1)
        
        let fragments = peptide.fragment()
        
        let precursors = fragments.filter { $0.fragmentType == .precursorIon }
        XCTAssert(precursors.count == 3)
        
        let immoniumIons = fragments.filter { $0.fragmentType == .immoniumIon }
        XCTAssert(immoniumIons.count == 7)

        let bIons = fragments.filter { $0.fragmentType == .bIon }
        XCTAssert(bIons.count == 10)

        let yIons = fragments.filter { $0.fragmentType == .yIon }
        XCTAssert(yIons.count == 17)
    }

    func testFragmentMass() {
        var peptide = Peptide(sequence: "SAMPLER")
        peptide.setAdducts(type: protonAdduct, count: 1)

        XCTAssert(peptide.chargedMass().monoisotopicMass.roundTo(places: 4) == 803.4080)
        
        let fragments = peptide.fragment()
        let precursors = fragments.filter { $0.fragmentType == .precursorIon }.sorted { $0.monoisotopicMass < $1.monoisotopicMass }
        
        XCTAssert(precursors[0].chargedMass().monoisotopicMass.roundTo(places: 4) == 785.3974)
        XCTAssert(precursors[1].chargedMass().monoisotopicMass.roundTo(places: 4) == 786.3815)
        XCTAssert(precursors[2].chargedMass().monoisotopicMass.roundTo(places: 4) == 803.4080)

        let aIons = fragments.filter { $0.fragmentType == .aIon }.sorted { $0.monoisotopicMass < $1.monoisotopicMass }
        XCTAssert(aIons[0].chargedMass().monoisotopicMass.roundTo(places: 4) == 131.0815) // a1

        let bIons = fragments.filter { $0.fragmentType == .bIon }.sorted { $0.monoisotopicMass < $1.monoisotopicMass }
        XCTAssert(bIons[0].chargedMass().monoisotopicMass.roundTo(places: 4) == 141.0659) // b2
        XCTAssert(bIons[1].chargedMass().monoisotopicMass.roundTo(places: 4) == 159.0764) // b2-H2O
        XCTAssert(bIons[2].chargedMass().monoisotopicMass.roundTo(places: 4) == 272.1063) // b3-H2O

        let xIons = fragments.reversed().filter { $0.fragmentType == .xIon }.sorted { $0.monoisotopicMass < $1.monoisotopicMass }
        print(xIons.map { $0.chargedMass().monoisotopicMass.roundTo(places: 4) })
        XCTAssert(xIons[0].chargedMass().monoisotopicMass.roundTo(places: 4) == 201.0982) // x1

        let yIons = fragments.reversed().filter { $0.fragmentType == .yIon }.sorted { $0.monoisotopicMass < $1.monoisotopicMass }
        XCTAssert(yIons[0].chargedMass().monoisotopicMass.roundTo(places: 4) == 158.0924) // y1-NH3
        XCTAssert(yIons[1].chargedMass().monoisotopicMass.roundTo(places: 4) == 175.1190) // y1
        XCTAssert(yIons[2].chargedMass().monoisotopicMass.roundTo(places: 4) == 286.1510) // y2-H2O
    }
    
    func testFragmentMass2() {
        var peptide = Peptide(sequence: "SAMPLEVAAAGQTHR")
        peptide.setAdducts(type: protonAdduct, count: 1)
        
        XCTAssert(peptide.chargedMass().monoisotopicMass.roundTo(places: 4) == 1538.7744)
        let fragments = peptide.fragment()
        
        let bIons = fragments.filter { $0.fragmentType == .bIon }.sorted { $0.monoisotopicMass < $1.monoisotopicMass }
        XCTAssert(bIons.count == 29)
        
        XCTAssert(bIons[0].chargedMass().monoisotopicMass.roundTo(places: 4) == 141.0659)   // b2
        XCTAssert(bIons[20].chargedMass().monoisotopicMass.roundTo(places: 4) == 1108.5456) // b12 - H2O
        XCTAssert(bIons[21].chargedMass().monoisotopicMass.roundTo(places: 4) == 1109.5296) // b12 - NH3
        XCTAssert(bIons[22].chargedMass().monoisotopicMass.roundTo(places: 4) == 1126.5561) // b12
        
        let zIons = fragments.filter { $0.fragmentType == .zIon }.sorted { $0.monoisotopicMass < $1.monoisotopicMass }
        XCTAssert(zIons.count == 13)

        let cIons = fragments.filter { $0.fragmentType == .cIon }.sorted { $0.monoisotopicMass < $1.monoisotopicMass }
        XCTAssert(cIons.count == 13)
        XCTAssert(cIons[0].chargedMass().monoisotopicMass.roundTo(places: 4) == 105.0659)   // c1 TODO
    }
    
    func testFragmentMass3() {
        var peptide = Peptide(sequence: "SAMPLEVAMAAGQTHR")
        peptide.setAdducts(type: protonAdduct, count: 1)
        
        if let ox = modificationLibrary.filter({ $0.name.contains("Oxidation") == true }).first {
            peptide.addModification(LocalizedModification(ox, at: 8))
            XCTAssert(peptide.chargedMass().monoisotopicMass.roundTo(places: 4) == 1685.8098)
            
            let fragments = peptide.fragment()
            let bIons = fragments.filter { $0.fragmentType == .bIon }.sorted { $0.monoisotopicMass < $1.monoisotopicMass }

            XCTAssert(bIons[15].chargedMass().monoisotopicMass.roundTo(places: 4) == 946.4373)   // b8 M-ox
        }
    }
}
