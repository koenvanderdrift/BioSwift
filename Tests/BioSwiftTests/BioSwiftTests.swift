@testable import BioSwift
import XCTest

final class BioSwiftTests: XCTestCase {
    lazy var testProtein = Protein(sequence: "MPSSVSWGILLLAGLCCLVPVSLAEDPQGDAAQKTDTSHHDQDHPTFNKITPNLAEFAFSLYRQLAHQSNSTNIFFSPIVSIATAFAMLSLGTKADTHDEILEGLNFNLTEIPEAQIHEGFQELLRTLNQPDSQLQLTTGNGLFLSEGLKLVDKFLEDVKKLYHSEAFTVNFGDTEEAKKQINDYVEKGTQGKIVDLVKELDRDTVFALVNYIFFKGKWERPFEVKDTEEEDFHVDQVTTVKVPMMKRLGMFNIQHCKKLSSWVLLMKYLGNATAIFFLPDEGKLQHLENELTHDIITKFLENEDRRSASLHLPKLSITGTYDLKSVLGQLGITKVFSNGADLSGVTEEAPLKLSKAVHKAVLTIDEKGTEAAGAMFLEAIPMSIPPEVKFNKPFVFMIEQNTKSPLFMGKVVNPTQK")

    lazy var testPeptide = Peptide(sequence: "DWSSD")

    lazy var alanine = AminoAcid(name: "Alanine", oneLetterCode: "A", threeLetterCode: "Ala", formula: Formula("C3H5NO"))
    lazy var serine = AminoAcid(name: "Serine", oneLetterCode: "S", threeLetterCode: "Ser", formula: Formula("C3H5NO2"))

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
        
        XCTAssertEqual(formula.chemicalString, "{AgCuRu₄(H)₂[CO]₁₂}₂")
        XCTAssertEqual(formula.countFor(element: "C"), 24)
    }
    
    func testPeptideFormula() {
        let peptide = Peptide(sequence: "DWSSD")
        let formula = peptide.formula
        print(formula.formulaString)
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
        
        testPeptide.setAdducts(type: protonAdduct, count: 2)
        XCTAssertEqual(testPeptide.pseudomolecularIon().monoisotopicMass.roundedDecimalAsString(to: 4), "305.1112")
    }
    
    func testPeptideAverageMass() {
        testPeptide.setAdducts(type: protonAdduct, count: 1)
        XCTAssertEqual(testPeptide.pseudomolecularIon().averageMass.roundedDecimalAsString(to: 4), "609.5731") // 609.563

        testPeptide.setAdducts(type: protonAdduct, count: 2)
        XCTAssertEqual(testPeptide.pseudomolecularIon().averageMass.roundedDecimalAsString(to: 4), "305.2903") // 305.2852
    }
    
    func testPeptideSerinePhosphorylationMonoisotopicMass() {
        if let phos = modificationLibrary.filter({ $0.name.contains("Phospho") == true }).first {
            testPeptide.addModification(LocalizedModification(phos, at: 3)) // zero-based
            testPeptide.setAdducts(type: protonAdduct, count: 1)
            
            XCTAssertEqual(testPeptide.pseudomolecularIon().monoisotopicMass.roundedDecimalAsString(to: 4), "689.1814")
            
            testPeptide.setAdducts(type: protonAdduct, count: 2)
            
            XCTAssertEqual(testPeptide.pseudomolecularIon().monoisotopicMass.roundedDecimalAsString(to: 4), "345.0944")
        }
    }
    
    func testProteinMonoisotopicMass() {
        testProtein.setAdducts(type: protonAdduct, count: 1)
        XCTAssertEqual(testProtein.pseudomolecularIon().monoisotopicMass.roundedDecimalAsString(to: 4), "46708.0267")
    }
    
    func testProteinAverageMass() {
        testProtein.setAdducts(type: protonAdduct, count: 1)
        XCTAssertEqual(testProtein.pseudomolecularIon().averageMass.roundedDecimalAsString(to: 4), "46737.9568")
    } // 46737.0703
    
    func testProteinFormula() {
        testProtein.setAdducts(type: protonAdduct, count: 1)
        XCTAssertEqual(testProtein.formula.countFor(element: "C"), 2112)
    } // C2112H3313N539O629S13
    
    func testProteinIsoElectricPoint() {
        let pKa = testProtein.isoelectricPoint(for: 0)
        XCTAssertEqual(pKa.roundedDecimalAsString(to: 2), "5.37") // 5.39
    }
    
    func testProteinIsoElectricPointForRange() {
        let range = 375 ... 418
        let pKa = testProtein.isoelectricPoint(for: 0, with: range.toOneBased)
        XCTAssertEqual(pKa.roundedDecimalAsString(to: 2), "9.40") // 10.2
    }

    func testAddFormulas() {
        let formula1 = Formula("C12H23O7N5")
        let formula2 = Formula("C2H2O2")
        let formula3 = formula1 + formula2
        
        print(formula3.formulaString)
        
        XCTAssertEqual(formula3.countFor(element: "C"), 14)
        XCTAssertEqual(formula3.countFor(element: "N"), 5)
    }
    
    func testSubtractFormulas() {
        let formula1 = Formula("C12H23O7N5")
        let formula2 = Formula("C2H2O2")
        let formula3 = formula1 - formula2
        
        print(formula3.formulaString)
        
        XCTAssertEqual(formula3.countFor(element: "C"), 10)
        XCTAssertEqual(formula3.countFor(element: "N"), 5)
    }

    func testProteinAtomCount() {
        testProtein.setAdducts(type: protonAdduct, count: 1)
        XCTAssertEqual(testProtein.formula.elements.count, 6606)
    }
    
    func testSymbolAtIndex() {
        if let chain = testProtein.chains.first {
            let symbol = chain.symbol(at: 14)
            XCTAssertEqual(symbol?.identifier, "L")
        }
    }
    
    func testFormulaAverageMass() { // C4H5NO3 + C11H10N2O + C3H5NO2 + C3H5NO2 + C4H5NO3 + H2O
        //        let formula = Formula("C2112H3313N539O629S13H")
        //        let masses = mass(of: formula.elements)
        //        debugPrint(masses)
        let group = FunctionalGroup(name: "", formula: "C4H5NO3" + "C11H10N2O" + "C3H5NO2" + "C3H5NO2" + "C4H5NO3" + "H2O")

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
            XCTAssertEqual(subChain1?.sequenceString, "MPSLLAGLCCLVPVSLAEDPQGDAAQKTDTSHHDQDHPTFNKITPNLAEFAFSLYRQLAHQSNSTNIFFSPIVSIATAFAMLSLGTKADTHDEILEGLNFNLTEIPEAQIHEGFQELLRTLNQPDSQLQLTTGNGLFLSEGLKLVDKFLEDVKKLYHSEAFTVNFGDTEEAKKQINDYVEKGTQGKIVDLVKELDRDTVFALVNYIFFKGKWERPFEVKDTEEEDFHVDQVTTVKVPMMKRLGMFNIQHCKKLSSWVLLMKYLGNATAIFFLPDEGKLQHLENELTHDIITKFLENEDRRSASLHLPKLSITGTYDLKSVLGQLGITKVFSNGADLSGVTEEAPLKLSKAVHKAVLTIDEKGTEAAGAMFLEAIPMSIPPEVKFNKPFVFMIEQNTKSPLFMGKVVNPTQK")
            
            let range2: ChainRange = 0 ... 9 // 0 based
            let subChain2 = chain.subChain(removing: range2)
            XCTAssertEqual(subChain2?.sequenceString, "LLAGLCCLVPVSLAEDPQGDAAQKTDTSHHDQDHPTFNKITPNLAEFAFSLYRQLAHQSNSTNIFFSPIVSIATAFAMLSLGTKADTHDEILEGLNFNLTEIPEAQIHEGFQELLRTLNQPDSQLQLTTGNGLFLSEGLKLVDKFLEDVKKLYHSEAFTVNFGDTEEAKKQINDYVEKGTQGKIVDLVKELDRDTVFALVNYIFFKGKWERPFEVKDTEEEDFHVDQVTTVKVPMMKRLGMFNIQHCKKLSSWVLLMKYLGNATAIFFLPDEGKLQHLENELTHDIITKFLENEDRRSASLHLPKLSITGTYDLKSVLGQLGITKVFSNGADLSGVTEEAPLKLSKAVHKAVLTIDEKGTEAAGAMFLEAIPMSIPPEVKFNKPFVFMIEQNTKSPLFMGKVVNPTQK")
            
            let range3: ChainRange = 11 ... 400 // 1 based
            let subChain3 = chain.subChain(removing: range3.toOneBased)
            XCTAssertEqual(subChain3?.sequenceString, "MPSSVSWGILQNTKSPLFMGKVVNPTQK")
        }
    }
    
    func testSubChainWithModification() {
        var peptide = Peptide(sequence: "SAMPLEVCAAAGQTHR")
        peptide.setAdducts(type: protonAdduct, count: 1)
        XCTAssert(peptide.chargedMass().monoisotopicMass.roundTo(places: 4) == 1641.7836)

        guard let cysMod = modificationLibrary.first(where: { $0.name.lowercased() == "Carboxymethyl".lowercased() })
        else {
            return
        }

        peptide.addModification(LocalizedModification(cysMod, at: 7)) // zero-based
        XCTAssert(peptide.chargedMass().monoisotopicMass.roundTo(places: 4) == 1699.7891)
        
        let subChain = peptide.subChain(from: 3, to: 12) // zero-based
        XCTAssert(subChain?.sequenceString == "PLEVCAAAGQ")
        XCTAssert(subChain?.modification(at: 4) == cysMod) // zero-based
        XCTAssert(subChain?.chargedMass().monoisotopicMass.roundTo(places: 4) == 1016.4717)
    }

    func testDigest() {
        let digester = ProteinDigester(protein: testProtein)
        
        let missedCleavages = 1
            
        let trypsin = enzymeLibrary.first(where: { $0.name == "Trypsin" })
            
        if let regex = trypsin?.regex() {
            let peptides: [Peptide] = digester.peptides(using: regex, with: missedCleavages)
            
            XCTAssertEqual(peptides[0].sequenceString, "MPSSVSWGILLLAGLCCLVPVSLAEDPQGDAAQK")
            XCTAssertEqual(peptides[1].sequenceString, "TDTSHHDQDHPTFNK")
        }
            
        let aspN = enzymeLibrary.first(where: { $0.name == "Asp-N" })
            
        if let regex = aspN?.regex() {
            let peptides: [Peptide] = digester.peptides(using: regex, with: missedCleavages)
            
            XCTAssertEqual(peptides[0].sequenceString, "MPSSVSWGILLLAGLCCLVPVSLAE")
            XCTAssertEqual(peptides[1].sequenceString, "DPQG")
        }
    }
    
    func testMassSearch() {
        if let chain = testProtein.chains.first as? Peptide {
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
        if let chain = testProtein.chains.first as? Peptide {
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
        if var chain = testProtein.chains.first as? Peptide,
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
        
        let fragmenter = PeptideFragmenter(peptide: peptide)
        let fragments = fragmenter.fragments

        let precursors = fragments.filter { $0.fragmentType == .precursorIon }
        XCTAssert(precursors.count == 1)
        
        let immoniumIons = fragments.filter { $0.fragmentType == .immoniumIon }
        XCTAssert(immoniumIons.count == 7)

        let bIons = fragments.filter { $0.fragmentType == .bIon }
        XCTAssert(bIons.count == 5)

        let yIons = fragments.filter { $0.fragmentType == .yIon }
        XCTAssert(yIons.count == 6)
    }

    func testFragmentMass() {
        // theoretical masses via https://prospector.ucsf.edu/prospector/cgi-bin/msform.cgi?form=msproduct
        
        var peptide = Peptide(sequence: "SAMPLER")
        peptide.setAdducts(type: protonAdduct, count: 1)

        XCTAssert(peptide.chargedMass().monoisotopicMass.roundTo(places: 4) == 803.4080)
        XCTAssert(peptide.pseudomolecularIon().monoisotopicMass.roundTo(places: 4) == 803.4080)
        
        let fragmenter = PeptideFragmenter(peptide: peptide)
        let fragments = fragmenter.fragments
        
        let precursors = fragments.filter { $0.fragmentType == .precursorIon }
        
        XCTAssert(precursors[0].chargedMass().monoisotopicMass.roundTo(places: 4) == 803.4080)
//        XCTAssert(precursors[1].chargedMass().monoisotopicMass.roundTo(places: 4) == 786.3815)
//        XCTAssert(precursors[2].chargedMass().monoisotopicMass.roundTo(places: 4) == 803.4080)

        if let a1 = fragmenter.fragment(at: 1, for: .aIon) {
            XCTAssert(a1.chargedMass().monoisotopicMass.roundTo(places: 4) == 131.0815) // a1
        }

        if let b2 = fragmenter.fragment(at: 2, for: .bIon) {
            XCTAssert(b2.chargedMass().monoisotopicMass.roundTo(places: 4) == 159.0764) // b2
        }
        
        if let b2minH2O = fragmenter.fragment(at: 2, for: .bIonMinusWater) {
            XCTAssert(b2minH2O.chargedMass().monoisotopicMass.roundTo(places: 4) == 141.0659) // b2-H2O
        }
        
        if let b3minH2O = fragmenter.fragment(at: 3, for: .bIonMinusWater) {
            XCTAssert(b3minH2O.chargedMass().monoisotopicMass.roundTo(places: 4) == 272.1063) // b3-H2O
        }

        if let x1 = fragmenter.fragment(at: 1, for: .xIon) {
            XCTAssert(x1.chargedMass().monoisotopicMass.roundTo(places: 4) == 201.0982) // x1
        }

        if let y1 = fragmenter.fragment(at: 1, for: .yIon) {
            XCTAssert(y1.chargedMass().monoisotopicMass.roundTo(places: 4) == 175.1190) // y1
        }
        
        if let y1minNH3 = fragmenter.fragment(at: 1, for: .yIonMinusAmmonia) {
            XCTAssert(y1minNH3.chargedMass().monoisotopicMass.roundTo(places: 4) == 158.0924) // y1-NH3 (139.0746, diff = -19.02)
        }
        
        if let y2minH2O = fragmenter.fragment(at: 2, for: .yIonMinusWater) {
            XCTAssert(y2minH2O.chargedMass().monoisotopicMass.roundTo(places: 4) == 286.1510) // y2-H2O (267.1332, diff = -19.02
        }

//        XCTAssert(yIons[0].chargedMass().monoisotopicMass.roundTo(places: 4) == 158.0924) // y1-NH3
//        XCTAssert(yIons[2].chargedMass().monoisotopicMass.roundTo(places: 4) == 286.1510) // y2-H2O
    }
    
    func testFragmentMass2() {
        var peptide = Peptide(sequence: "SAMPLEVAAAGQTHR")
        peptide.setAdducts(type: protonAdduct, count: 1)
        
        XCTAssert(peptide.chargedMass().monoisotopicMass.roundTo(places: 4) == 1538.7744)

        let fragmenter = PeptideFragmenter(peptide: peptide)
        let fragments = fragmenter.fragments

        let bIons = fragments.filter { $0.fragmentType == .bIon }
        XCTAssert(bIons.count == 13)
        
        if let b2 = fragmenter.fragment(at: 2, for: .bIon) {
            XCTAssert(b2.chargedMass().monoisotopicMass.roundTo(places: 4) == 159.0764) // b2
        }
        
        if let b12 = fragmenter.fragment(at: 12, for: .bIon) {
            XCTAssert(b12.chargedMass().monoisotopicMass.roundTo(places: 4) == 1126.5561) // b12
        }
        
        if let b12minH2O = fragmenter.fragment(at: 12, for: .bIonMinusWater) {
            XCTAssert(b12minH2O.chargedMass().monoisotopicMass.roundTo(places: 4) == 1108.5456) // b12 - H2O
        }

        if let b12minNH3 = fragmenter.fragment(at: 12, for: .bIonMinusAmmonia) {
            XCTAssert(b12minNH3.chargedMass().monoisotopicMass.roundTo(places: 4) == 1109.5296) // b12 - NH3
        }

        let zIons = fragments.filter { $0.fragmentType == .zIon }
        XCTAssert(zIons.count == 13)

        let cIons = fragments.filter { $0.fragmentType == .cIon }
        XCTAssert(cIons.count == 13)
        
        if let c1 = fragmenter.fragment(at: 1, for: .cIon) {
            XCTAssert(c1.chargedMass().monoisotopicMass.roundTo(places: 4) == 105.0659) // c1
        }
    }
    
    func testFragmentMass3() {
        var peptide = Peptide(sequence: "SAMPLEVAMAAGQTHR")
        peptide.setAdducts(type: protonAdduct, count: 1)
        
        guard let ox = modificationLibrary.filter({ $0.name.contains("Oxidation") == true }).first else { return }
        
        peptide.addModification(LocalizedModification(ox, at: 8))
        XCTAssert(peptide.chargedMass().monoisotopicMass.roundTo(places: 4) == 1685.8098)
        
        let fragmenter = PeptideFragmenter(peptide: peptide)
        let fragments = fragmenter.fragments

        let aIonsMinusWater = fragments.filter { $0.fragmentType == .aIonMinusWater }
        XCTAssert(aIonsMinusWater.count == 14)

        let aIonsMinusAmmonia = fragments.filter { $0.fragmentType == .aIonMinusAmmonia }
        XCTAssert(aIonsMinusAmmonia.count == 3)
        
        let bIons = fragments.filter { $0.fragmentType == .bIon }
        XCTAssertNil(bIons.filter { $0.index == 1 }.first)
        
        let yIons = fragments.filter { $0.fragmentType == .yIonMinusWater }
        XCTAssertNil(yIons.filter { $0.index == 1 }.first)
        XCTAssertNil(yIons.filter { $0.index == 2 }.first)
        
        if let b8 = fragmenter.fragment(at: 8, for: .bIon) {
            XCTAssert(b8.chargedMass().monoisotopicMass.roundTo(places: 4) == 799.4019) // b8 M-ox
        }
                    
        if let y9 = fragmenter.fragment(at: 9, for: .yIon) {
            XCTAssert(y9.chargedMass().monoisotopicMass.roundTo(places: 4) == 958.4523) // y9 M-ox
        }
        
        let zIons = fragments.filter { $0.fragmentType == .zIon }
        XCTAssertNil(zIons.filter { $0.index == 13 }.first)

        if let z12 = fragmenter.fragment(at: 12, for: .zIon) {
            XCTAssert(z12.chargedMass().monoisotopicMass.roundTo(places: 4) == 1283.6287) // z12 M-ox
        }
    }
    
    func testFragmentMass4() {
        var peptide = Peptide(sequence: "AWRKQNWSTEDWWSTEDWQPRTYSAMPLER")
        peptide.setAdducts(type: protonAdduct, count: 1)
        
        let fragmenter = PeptideFragmenter(peptide: peptide)
        let fragments = fragmenter.fragments

        let bIonsMinusWater = fragments.filter { $0.fragmentType == .bIonMinusWater }
        XCTAssertNil(bIonsMinusWater.filter { $0.index == 1 }.first)
        XCTAssertNil(bIonsMinusWater.filter { $0.index == 2 }.first)
        XCTAssertNil(bIonsMinusWater.filter { $0.index == 3 }.first)
        XCTAssertNil(bIonsMinusWater.filter { $0.index == 4 }.first)
        XCTAssertNil(bIonsMinusWater.filter { $0.index == 5 }.first)
        XCTAssertNil(bIonsMinusWater.filter { $0.index == 6 }.first)
        XCTAssertNil(bIonsMinusWater.filter { $0.index == 7 }.first)

        if let b8minusWater = fragmenter.fragment(at: 8, for: .bIonMinusWater) {
            XCTAssert(b8minusWater.chargedMass().monoisotopicMass.roundTo(places: 4) == 1039.5221) // b8-H20
        }
    }
    
    func testFragmentMass5() {
        var peptide = Peptide(sequence: "SAMPLEVAAAGQTHR")
        peptide.setAdducts(type: protonAdduct, count: 2)
        
        XCTAssert(peptide.pseudomolecularIon().monoisotopicMass.roundTo(places: 4) == 769.8908)

        let fragmenter = PeptideFragmenter(peptide: peptide)
        let fragments = fragmenter.fragments

        let bIons = fragments.filter { $0.fragmentType == .bIon }
        XCTAssert(bIons.count == 14)
        
        if let b2 = fragmenter.fragment(at: 2, for: .bIon) {
            XCTAssert(b2.chargedMass().monoisotopicMass.roundTo(places: 4) == 159.0764) // b2
        }
        
        if let b12 = fragmenter.fragment(at: 12, for: .bIon) {
            XCTAssert(b12.chargedMass().monoisotopicMass.roundTo(places: 4) == 1126.5561) // b12
        }
        
        let bIonsMinH2O = fragments.filter { $0.fragmentType == .bIonMinusWater }
        XCTAssert(bIonsMinH2O.count == 14)
        
        if let b12minH2O = fragmenter.fragment(at: 12, for: .bIonMinusWater) {
            XCTAssert(b12minH2O.chargedMass().monoisotopicMass.roundTo(places: 4) == 1108.5456) // b12 - H2O
        }

        if let b12minNH3 = fragmenter.fragment(at: 12, for: .bIonMinusAmmonia) {
            XCTAssert(b12minNH3.chargedMass().monoisotopicMass.roundTo(places: 4) == 1109.5296) // b12 - NH3
        }

        let zIons = fragments.filter { $0.fragmentType == .zIon }
        XCTAssert(zIons.count == 26)

        let cIons = fragments.filter { $0.fragmentType == .cIon }
        XCTAssert(cIons.count == 14)
        
        if let c1 = fragmenter.fragment(at: 1, for: .cIon) {
            XCTAssert(c1.chargedMass().monoisotopicMass.roundTo(places: 4) == 105.0659) // c1
        }
    }
    
    func testChargedResidues() {
        let fragment = PeptideFragment(sequence: "AWRKQNWSTEDWWSHTEDWQPRTYSAMPLER")
        
        let numOfCharges = fragment.maxNumberOfCharges()
        XCTAssert(numOfCharges == 5)
    }
    
    func testallFragmentCases() {
        let allCases = PeptideFragmentType.allCases
        XCTAssert(allCases.count == 17)
    }
    
    func testBiomolecule2() {
        var peptide1 = Peptide(residues: [alanine, alanine, serine, alanine, serine])
        var peptide2 = Peptide(residues: peptide1.residues + [serine, serine, alanine])

        XCTAssert(peptide1.sequenceLength == 5)
        XCTAssert(peptide2.sequenceLength == 8)

        peptide1.setAdducts(type: protonAdduct, count: 1)
        XCTAssert(peptide1.chargedMass().monoisotopicMass.roundTo(places: 4) == 406.1932)

        peptide2.setAdducts(type: protonAdduct, count: 2)
        XCTAssert(peptide2.chargedMass().monoisotopicMass.roundTo(places: 4) == 326.1508)
        
        var protein = Protein(chains: [peptide1, peptide2])

        XCTAssert(protein.sequence(for: 0) == "AASAS")
        XCTAssert(protein.sequence(for: 1) == "AASASSSA")

        XCTAssert(protein.aminoAcids(for: 0).map { $0.oneLetterCode } == ["A", "A", "S", "A", "S"])
        XCTAssert(protein.aminoAcids(for: 1).map { $0.oneLetterCode } == ["A", "A", "S", "A", "S", "S", "S", "A"])

        protein.setAdducts(type: protonAdduct, count: 1, for: 0)
        protein.setAdducts(type: protonAdduct, count: 0, for: 1)
        let mass1 = protein.chains[0].chargedMass().monoisotopicMass.roundTo(places: 4) // 406.1932
        let mass2 = protein.chains[1].chargedMass().monoisotopicMass.roundTo(places: 4) // 650.2871
        XCTAssert(mass1 == 406.1932)
        XCTAssert(mass2 == 650.2871)
        let mass = protein.chargedMass().monoisotopicMass.roundTo(places: 4) // 1055.4731

        XCTAssert(mass == mass1 + mass2)
    }
}
