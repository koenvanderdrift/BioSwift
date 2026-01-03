//
//  BioSwiftTest.swift
//  BioSwift
//
//  Created by Koen van der Drift on 26.12.2025.
//

@testable import BioSwift
import Testing

// https://stackoverflow.com/questions/79856701/swift-testing-load-data-before-the-tests-start/

struct DataLibraryTrait: SuiteTrait, TestScoping {
    func provideScope(for test: Test, testCase: Test.Case?, performing function: @Sendable () async throws -> Void) async throws {
        print("Setting up once and for all...")
        try await dataLibrary.loadUnimod()
        try await function()
        print("Tearing down...")
    }
}

extension SuiteTrait where Self == DataLibraryTrait {
    static var bioSwiftDataLbrary: DataLibraryTrait { .init() }
}

@Suite(.bioSwiftDataLbrary)
struct BioSwiftTests {
    var testProtein = Protein(sequence: "MPSSVSWGILLLAGLCCLVPVSLAEDPQGDAAQKTDTSHHDQDHPTFNKITPNLAEFAFSLYRQLAHQSNSTNIFFSPIVSIATAFAMLSLGTKADTHDEILEGLNFNLTEIPEAQIHEGFQELLRTLNQPDSQLQLTTGNGLFLSEGLKLVDKFLEDVKKLYHSEAFTVNFGDTEEAKKQINDYVEKGTQGKIVDLVKELDRDTVFALVNYIFFKGKWERPFEVKDTEEEDFHVDQVTTVKVPMMKRLGMFNIQHCKKLSSWVLLMKYLGNATAIFFLPDEGKLQHLENELTHDIITKFLENEDRRSASLHLPKLSITGTYDLKSVLGQLGITKVFSNGADLSGVTEEAPLKLSKAVHKAVLTIDEKGTEAAGAMFLEAIPMSIPPEVKFNKPFVFMIEQNTKSPLFMGKVVNPTQK")
    var testPeptide = Peptide(sequence: "DWSSD")
    var alanine = AminoAcid(name: "Alanine", oneLetterCode: "A", threeLetterCode: "Ala", formula: Formula("C3H5NO"))
    var serine = AminoAcid(name: "Serine", oneLetterCode: "S", threeLetterCode: "Ser", formula: Formula("C3H5NO2"))
    
    @Test func sequenceLength() {
        #expect(testProtein.sequenceLength() == 418)
        #expect(testPeptide.sequenceString.count == 5)
    }
    
    @Test func proteinResidueCount() {
        let cysCount = testProtein.countOneResidue(with: "C")
        #expect(cysCount == 3)
        
        let glnCount = testProtein.countOneResidue(with: "Q")
        #expect(glnCount == 18)
    }
    
    @Test func peptideResidueCount() {
        let countedSet = testPeptide.countAllResidues()
        
        if let ser = aminoAcidLibrary.first(where: { $0.identifier == "S" }) {
            let aaCount = countedSet.count(for: ser)
            #expect(aaCount == 2)
        }
    }
    
    @Test func sequenceLengthWithIllegalCharacters() {
        let protein = Protein(sequence: "D___WS83SD")
        #expect(protein.sequenceLength() == 5)
    }
    
    @Test func formulaChemicalString() {
        let formula = Formula("{AgCuRu4(H)2[CO]12}2")
        
        #expect(formula.chemicalString == "{AgCuRu₄(H)₂[CO]₁₂}₂")
        #expect(formula.countFor(element: "C") == 24)
    }
    
    @Test func proteinFormula() {
        #expect(testProtein.formula.countFor(element: "C") == 2112)
    } // C2112H3313N539O629S13
    
    @Test func peptideFormula() {
        let peptide = Peptide(sequence: "DWSSD")
        #expect(peptide.formula.countFor(element: "C") == 25)
    }
    
    @Test func waterAverageMass() { // H2O
        #expect(water.averageMass.roundedString(to: 4) == "18.0153")
    }
    
    @Test func ammoniaAverageMass() { // NH3
        #expect(ammonia.averageMass.roundedString(to: 4) == "17.0305")
    }
    
    @Test func methylAverageMass() { // CH3
        #expect(methyl.averageMass.roundedString(to: 4) == "15.0346") // 15.0345
    }
    
    @Test func formulaAverageMass() { // C4H5NO3 + C11H10N2O + C3H5NO2 + C3H5NO2 + C4H5NO3 + H2O
        let group = FunctionalGroup(name: "", formula: "C4H5NO3" + "C11H10N2O" + "C3H5NO2" + "C3H5NO2" + "C4H5NO3" + "H2O")
        
        #expect(group.averageMass.roundedString(to: 4) == "608.5557")
    } // 608.5546
    
    @Test mutating func peptideMonoisotopicMass() {
        testPeptide.setAdducts(type: protonAdduct, count: 1)
        #expect(testPeptide.pseudomolecularIon().monoisotopicMass.roundedString(to: 4) == "609.2151")
        
        testPeptide.setAdducts(type: protonAdduct, count: 2)
        #expect(testPeptide.pseudomolecularIon().monoisotopicMass.roundedString(to: 4) == "305.1112")
    }
    
    @Test mutating func peptideAverageMass() {
        testPeptide.setAdducts(type: protonAdduct, count: 1)
        #expect(testPeptide.pseudomolecularIon().averageMass.roundedString(to: 4) == "609.5731") // 609.5620
        
        testPeptide.setAdducts(type: protonAdduct, count: 2)
        #expect(testPeptide.pseudomolecularIon().averageMass.roundedString(to: 4) == "305.2903") // 305.2847
    }
    
    @Test mutating func peptideSerinePhosphorylationMonoisotopicMass() {
        if let phos = modificationLibrary.first(where: { $0.name == "Phospho" }) {
            testPeptide.addModification(LocalizedModification(phos, at: 3)) // zero-based
            
            testPeptide.setAdducts(type: protonAdduct, count: 1)
            #expect(testPeptide.pseudomolecularIon().monoisotopicMass.roundedString(to: 4) == "689.1814")
            
            testPeptide.setAdducts(type: protonAdduct, count: 2)
            #expect(testPeptide.pseudomolecularIon().monoisotopicMass.roundedString(to: 4) == "345.0944")
            
            testPeptide.removeModification(at: 3)
            testPeptide.setAdducts(type: protonAdduct, count: 1)
            #expect(testPeptide.pseudomolecularIon().monoisotopicMass.roundedString(to: 4) == "609.2151")
        }
    }
    
    @Test mutating func proteinMonoisotopicMass() {
        testProtein.setAdducts(type: protonAdduct, count: 1)
        #expect(testProtein.pseudomolecularIon().monoisotopicMass.roundedString(to: 4) == "46708.0267")
    } // 46707.0194
    
    @Test mutating func proteinAverageMass() {
        testProtein.setAdducts(type: protonAdduct, count: 1)
        #expect(testProtein.pseudomolecularIon().averageMass.roundedString(to: 4) == "46737.9568")
    } // 46737.0703
    
    @Test mutating func proteinSerinePhosphorylationMonoisotopicMass() {
        if let phos = modificationLibrary.first(where: { $0.name == "Phospho" }) {
            testProtein.addModification(mod: LocalizedModification(phos, at: 3)) // zero-based
            testProtein.setAdducts(type: protonAdduct, count: 1)
            
            #expect(phos.fullName == "Phosphorylation")
            #expect(testProtein.pseudomolecularIon().monoisotopicMass.roundedString(to: 4) == "46787.9930") // 46787.9931
            
            testProtein.setAdducts(type: protonAdduct, count: 2)
            #expect(testProtein.pseudomolecularIon().monoisotopicMass.roundedString(to: 4) == "23394.5002") // 23394.5002
        }
    }
    
    @Test func modificationFullName() {
        if let pnTAG = modificationLibrary.first(where: { $0.name == "PnTAG" }) {
            #expect(pnTAG.fullName == "6-Phosphonohexanoylation")
        }
        
        if let TMTpro = modificationLibrary.first(where: { $0.name == "Label:13C(6)15N(2)+TMTpro" }) {
            #expect(TMTpro.fullName == "TMTpro Tandem Mass Tag 13C(6) 15N(2) Silac label")
        }
    }
    
    @Test func addFormulas() {
        let formula1 = Formula("C12H23O7N5")
        let formula2 = Formula("C2H2O2")
        let formula3 = formula1 + formula2

        print(formula3.formulaString)

        #expect(formula3.countFor(element: "C") == 14)
        #expect(formula3.countFor(element: "N") == 5)
    }

    @Test func subtractFormulas() {
        let formula1 = Formula("C12H23O7N5")
        let formula2 = Formula("C2H2O2")
        let formula3 = formula1 - formula2

        print(formula3.formulaString)

        #expect(formula3.countFor(element: "C") == 10)
        #expect(formula3.countFor(element: "N") == 5)
    }
    
    @Test mutating func proteinAtomCount() {
        testProtein.setAdducts(type: protonAdduct, count: 1)
        #expect(testProtein.formula.countAllElements() == 6606)
    }
    
    @Test func symbolAtIndex() {
        if let chain = testProtein.chains.first {
            let symbol = chain.symbol(at: 14)
            #expect(symbol?.identifier == "L")
        }
    }
    
    @Test mutating func replaceAminoAcid() {
        #expect(testPeptide.sequenceString == "DWSSD")
        
        if let gly = aminoAcidLibrary.first(where: { $0.identifier == "G" }) {
            testPeptide.replaceResidue(at: 0, with: gly)
            #expect(testPeptide.sequenceString == "GWSSD")
        }
    }
    
    @Test mutating func removeAminoAcid() {
        #expect(testPeptide.sequenceString == "DWSSD")
        testPeptide.removeResidue(at: 3)
        #expect(testPeptide.sequenceString == "DWSD")
    }
    
    @Test mutating func insertAminoAcid() {
        #expect(testPeptide.sequenceString == "DWSSD")
        if let gly = aminoAcidLibrary.first(where: { $0.identifier == "G" }) {
            testPeptide.insertResidue(gly, at: 2)
        }
        
        #expect(testPeptide.sequenceString == "DWGSSD")
    }
    
    @Test mutating func insertAminoAcids() {
        #expect(testPeptide.sequenceString == "DWSSD")
        if let gly = aminoAcidLibrary.first(where: { $0.identifier == "G" }), let pro = aminoAcidLibrary.first(where: { $0.identifier == "P" }) {
            testPeptide.insertResidues([gly, pro, pro], at: 2)
        }
        
        #expect(testPeptide.sequenceString == "DWGPPSSD")
    }
    
    @Test func loadFasta() {
        let fasta = try? parseFastaDataFromBundle(from: "ecoli")
        #expect(fasta?.count == 4392)
        
        let record = fasta?.first(where: { $0.accession == "P02919" })
        
        #expect(record?.entryName == "PBPB_ECOLI")
        #expect(record?.proteinName == "Penicillin-binding protein 1B")
        #expect(record?.organism == "Escherichia coli (strain K12)")
    }
    
    @Test func subChain() {
        if let chain = testProtein.chains.first {
            let range1: ChainRange = 3 ... 9 // 0 based
            let subChain1 = chain.subChain(removing: range1)
            #expect(subChain1?.sequenceString == "MPSLLAGLCCLVPVSLAEDPQGDAAQKTDTSHHDQDHPTFNKITPNLAEFAFSLYRQLAHQSNSTNIFFSPIVSIATAFAMLSLGTKADTHDEILEGLNFNLTEIPEAQIHEGFQELLRTLNQPDSQLQLTTGNGLFLSEGLKLVDKFLEDVKKLYHSEAFTVNFGDTEEAKKQINDYVEKGTQGKIVDLVKELDRDTVFALVNYIFFKGKWERPFEVKDTEEEDFHVDQVTTVKVPMMKRLGMFNIQHCKKLSSWVLLMKYLGNATAIFFLPDEGKLQHLENELTHDIITKFLENEDRRSASLHLPKLSITGTYDLKSVLGQLGITKVFSNGADLSGVTEEAPLKLSKAVHKAVLTIDEKGTEAAGAMFLEAIPMSIPPEVKFNKPFVFMIEQNTKSPLFMGKVVNPTQK")
            
            let range2: ChainRange = 0 ... 9 // 0 based
            let subChain2 = chain.subChain(removing: range2)
            #expect(subChain2?.sequenceString == "LLAGLCCLVPVSLAEDPQGDAAQKTDTSHHDQDHPTFNKITPNLAEFAFSLYRQLAHQSNSTNIFFSPIVSIATAFAMLSLGTKADTHDEILEGLNFNLTEIPEAQIHEGFQELLRTLNQPDSQLQLTTGNGLFLSEGLKLVDKFLEDVKKLYHSEAFTVNFGDTEEAKKQINDYVEKGTQGKIVDLVKELDRDTVFALVNYIFFKGKWERPFEVKDTEEEDFHVDQVTTVKVPMMKRLGMFNIQHCKKLSSWVLLMKYLGNATAIFFLPDEGKLQHLENELTHDIITKFLENEDRRSASLHLPKLSITGTYDLKSVLGQLGITKVFSNGADLSGVTEEAPLKLSKAVHKAVLTIDEKGTEAAGAMFLEAIPMSIPPEVKFNKPFVFMIEQNTKSPLFMGKVVNPTQK")
            
            let range3: ChainRange = (11 ... 400).toOneBased // 1 based
            let subChain3 = chain.subChain(removing: range3)
            #expect(subChain3?.sequenceString == "MPSSVSWGILLLTKSPLFMGKVVNPTQK")
        }
    }
    
    @Test func subChainWithModification() {
        var peptide = Peptide(sequence: "SAMPLEVCAAAGQTHR")
        peptide.setAdducts(type: protonAdduct, count: 1)
        #expect(peptide.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 1641.7836) // 1640.7763
        
        if let cysMod = modificationLibrary.first(where: { $0.name == "Carboxymethyl" }) {
            #expect(cysMod.fullName == "Iodoacetic acid derivative")
            peptide.addModification(LocalizedModification(cysMod, at: 7)) // zero-based
            #expect(peptide.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 1699.7891) // 1698.7818
            
            let subChain = peptide.subChain(from: 3, to: 12) // zero-based
            #expect(subChain?.sequenceString == "PLEVCAAAGQ")
            #expect(subChain?.modification(at: 4) == cysMod) // zero-based
            #expect(subChain?.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 1016.4717) // 1015.4644
        }
    }
     
    @Test func emptySequence() {
        let peptide = Peptide(sequence: "")
        #expect(peptide.pseudomolecularIon().monoisotopicMass == zeroMass.monoisotopicMass)
    }
    
    @Test func digest() {
        let digester = ProteinDigester(protein: testProtein)
     
        let missedCleavages = 1
     
        let trypsin = enzymeLibrary.first(where: { $0.name == "Trypsin" })
     
        if let regex = trypsin?.regex() {
            let peptides: [Peptide] = digester.peptides(using: regex, with: missedCleavages)
     
            #expect(peptides[0].sequenceString == "MPSSVSWGILLLAGLCCLVPVSLAEDPQGDAAQK")
            #expect(peptides[1].sequenceString == "TDTSHHDQDHPTFNK")
        }
     
        let aspN = enzymeLibrary.first(where: { $0.name == "Asp-N" })
     
        if let regex = aspN?.regex() {
            let peptides: [Peptide] = digester.peptides(using: regex, with: missedCleavages)
     
            #expect(peptides[0].sequenceString == "MPSSVSWGILLLAGLCCLVPVSLAE")
            #expect(peptides[1].sequenceString == "DPQG")
        }
    }
     
    @Test func lowMassSearch() {
        if let chain = testProtein.chains.first {
            let searchParameters = MassSearchParameters(searchValue: 1,
                                                        tolerance: MassTolerance(type: .ppm, value: 20),
                                                        searchType: .sequential,
                                                        massType: .monoisotopic)
     
            let peptides: [Peptide] = chain.searchMass(params: searchParameters)
            print(peptides.map(\.sequenceString))
     
            #expect(peptides.count == 0)
        }
    }
     
    @Test func massSearch() {
        if let chain = testProtein.chains.first {
            let searchParameters = MassSearchParameters(searchValue: 609.71,
                                                        tolerance: MassTolerance(type: .ppm, value: 20),
                                                        searchType: .sequential,
                                                        massType: .monoisotopic)
     
            let peptides: [Peptide] = chain.searchMass(params: searchParameters)
            print(peptides.map(\.sequenceString))
     
            #expect(peptides.contains(where: { $0.sequenceString == "IFFSP" }))
        }
    }
     
    @Test func massSearchWithModification() {
        if var chain = testProtein.chains.first,
           let phos = modificationLibrary.first(where: { $0.name == "Phospho" })
        {
            chain.addModification(LocalizedModification(phos, at: 76)) // zero-based
     
            let searchParameters = MassSearchParameters(searchValue: 689,
                                                        tolerance: MassTolerance(type: .ppm, value: 20),
                                                        searchType: .sequential,
                                                        massType: .nominal)
     
            let peptides: [Peptide] = chain.searchMass(params: searchParameters)
            print(peptides.map(\.sequenceString))
     
            #expect(peptides.contains(where: { $0.sequenceString == "IFFSP" }))
        }
    }
    
    @Test func fragmentCount() {
        var peptide = Peptide(sequence: "SAMPLER")
        peptide.setAdducts(type: protonAdduct, count: 1)
     
        let fragmenter = PeptideFragmenter(peptide: peptide)
        let fragments = fragmenter.fragments
     
        let precursors = fragments.filter { $0.fragmentType == .precursorIon }
        #expect(precursors.count == 1)
     
        let immoniumIons = fragments.filter { $0.fragmentType == .immoniumIon }
        #expect(immoniumIons.count == 7)
     
        let bIons = fragments.filter { $0.fragmentType == .bIon }
        #expect(bIons.count == 5)
     
        let yIons = fragments.filter { $0.fragmentType == .yIon }
        #expect(yIons.count == 6)
    }
     
    @Test func fragmentMass1() {
        // theoretical masses via https://prospector.ucsf.edu/prospector/cgi-bin/msform.cgi?form=msproduct
     
        var peptide = Peptide(sequence: "SAMPLER")
        peptide.setAdducts(type: protonAdduct, count: 1)
     
        #expect(peptide.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 803.4080)
        #expect(peptide.pseudomolecularIon().monoisotopicMass.roundedDouble(to: 4) == 803.4080)
     
        let fragmenter = PeptideFragmenter(peptide: peptide)
        let fragments = fragmenter.fragments
     
        let precursors = fragments.filter { $0.isPrecursor() }
        #expect(precursors[0].massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 803.4080)
        #expect(precursors[1].massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 785.3974)
        #expect(precursors[2].massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 786.3815)
     
        if let a1 = fragmenter.fragment(at: 1, for: .aIon) {
            #expect(a1.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 131.0815) // a1
        }
     
        if let b2 = fragmenter.fragment(at: 2, for: .bIon) {
            #expect(b2.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 159.0764) // b2
        }
     
        if let b2minH2O = fragmenter.fragment(at: 2, for: .bIonMinusWater) {
            #expect(b2minH2O.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 141.0659) // b2-H2O
        }
     
        if let b3minH2O = fragmenter.fragment(at: 3, for: .bIonMinusWater) {
            #expect(b3minH2O.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 272.1063) // b3-H2O
        }
     
        if let x1 = fragmenter.fragment(at: 1, for: .xIon) {
            #expect(x1.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 201.0982) // x1
        }
     
        if let y1 = fragmenter.fragment(at: 1, for: .yIon) {
            #expect(y1.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 175.1190) // y1
        }
     
        if let y1minNH3 = fragmenter.fragment(at: 1, for: .yIonMinusAmmonia) {
            #expect(y1minNH3.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 158.0924) // y1-NH3 (139.0746, diff = -19.02)
        }
     
        if let y2minH2O = fragmenter.fragment(at: 2, for: .yIonMinusWater) {
            #expect(y2minH2O.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 286.1510) // y2-H2O (267.1332, diff = -19.02
        }
     
        //        #expect(yIons[0].massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 158.0924) // y1-NH3
        //        #expect(yIons[2].chargedMass().monoisotopicMass.roundedDouble(to: 4) == 286.1510) // y2-H2O
    }
     
    @Test func fragmentMass2() {
        var peptide = Peptide(sequence: "SAMPLEVAAAGQTHR")
        peptide.setAdducts(type: protonAdduct, count: 1)
     
        #expect(peptide.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 1538.7744)
     
        let fragmenter = PeptideFragmenter(peptide: peptide)
        let fragments = fragmenter.fragments
     
        let bIons = fragments.filter { $0.fragmentType == .bIon }
        #expect(bIons.count == 13)
     
        if let b2 = fragmenter.fragment(at: 2, for: .bIon) {
            #expect(b2.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 159.0764) // b2
        }
     
        if let b12 = fragmenter.fragment(at: 12, for: .bIon) {
            #expect(b12.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 1126.5561) // b12
        }
     
        if let b12minH2O = fragmenter.fragment(at: 12, for: .bIonMinusWater) {
            #expect(b12minH2O.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 1108.5456) // b12 - H2O
        }
     
        if let b12minNH3 = fragmenter.fragment(at: 12, for: .bIonMinusAmmonia) {
            #expect(b12minNH3.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 1109.5296) // b12 - NH3
        }
     
        let zIons = fragments.filter { $0.fragmentType == .zIon }
        #expect(zIons.count == 13)
     
        let cIons = fragments.filter { $0.fragmentType == .cIon }
        #expect(cIons.count == 13)
     
        if let c1 = fragmenter.fragment(at: 1, for: .cIon) {
            #expect(c1.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 105.0659) // c1
        }
    }
     
    @Test func fragmentMass3() {
        var peptide = Peptide(sequence: "SAMPLEVAMAAGQTHR")
        peptide.setAdducts(type: protonAdduct, count: 1)
     
        if let ox = modificationLibrary.first(where: { $0.name == "Oxidation" }) {
            #expect(ox.fullName == "Oxidation or Hydroxylation")
            peptide.addModification(LocalizedModification(ox, at: 8))
            #expect(peptide.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 1685.8098)
     
            let fragmenter = PeptideFragmenter(peptide: peptide)
            let fragments = fragmenter.fragments
     
            let aIonsMinusWater = fragments.filter { $0.fragmentType == .aIonMinusWater }
            #expect(aIonsMinusWater.count == 14)
     
            let aIonsMinusAmmonia = fragments.filter { $0.fragmentType == .aIonMinusAmmonia }
            #expect(aIonsMinusAmmonia.count == 3)
     
            let bIons = fragments.filter { $0.fragmentType == .bIon }
            #expect(bIons.first(where: { $0.index == 1 }) == nil)

            let yIons = fragments.filter { $0.fragmentType == .yIonMinusWater }
            #expect(yIons.filter { $0.index == 1 }.first == nil)
            #expect(yIons.filter { $0.index == 2 }.first == nil)
     
            if let b8 = fragmenter.fragment(at: 8, for: .bIon) {
                #expect(b8.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 799.4019) // b8 M-ox
            }
     
            if let y9 = fragmenter.fragment(at: 9, for: .yIon) {
                #expect(y9.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 958.4523) // y9 M-ox
            }
     
            if let x9 = fragmenter.fragment(at: 9, for: .xIon) {
                #expect(x9.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 984.4316) // x9 M-ox
            }
     
            let zIons = fragments.filter { $0.fragmentType == .zIon }
            #expect(zIons.filter { $0.index == 13 }.first == nil)
     
            if let z12 = fragmenter.fragment(at: 12, for: .zIon) {
                #expect(z12.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 1283.6287) // z12 M-ox
            }
        }
    }
     
    @Test func fragmentMass4() {
        var peptide = Peptide(sequence: "AWRKQNWSTEDWWSTEDWQPRTYSAMPLER")
        peptide.setAdducts(type: protonAdduct, count: 1)
     
        let fragmenter = PeptideFragmenter(peptide: peptide)
        let fragments = fragmenter.fragments

        let bIonsMinusWater = fragments.filter { $0.fragmentType == .bIonMinusWater }
        #expect(bIonsMinusWater.filter { $0.index == 1 }.first == nil)
        #expect(bIonsMinusWater.filter { $0.index == 2 }.first == nil)
        #expect(bIonsMinusWater.filter { $0.index == 3 }.first == nil)
        #expect(bIonsMinusWater.filter { $0.index == 4 }.first == nil)
        #expect(bIonsMinusWater.filter { $0.index == 5 }.first == nil)
        #expect(bIonsMinusWater.filter { $0.index == 6 }.first == nil)
        #expect(bIonsMinusWater.filter { $0.index == 7 }.first == nil)
        #expect(bIonsMinusWater.filter { $0.index == 8 }.first != nil)

        if let b8MinusWater = fragmenter.fragment(at: 8, for: .bIonMinusWater) {
            #expect(b8MinusWater.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 1039.5221) // b8-H20
        }
    }
     
    @Test func fragmentMass5() {
        var peptide = Peptide(sequence: "SAMPLEVAAAGQTHR")
        peptide.setAdducts(type: protonAdduct, count: 2)
     
        #expect(peptide.pseudomolecularIon().monoisotopicMass.roundedDouble(to: 4) == 769.8908)
     
        let fragmenter = PeptideFragmenter(peptide: peptide)
        let fragments = fragmenter.fragments
     
        let bIons = fragments.filter { $0.fragmentType == .bIon }
        #expect(bIons.count == 14)
     
        if let b2 = fragmenter.fragment(at: 2, for: .bIon) {
            #expect(b2.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 159.0764) // b2
        }
     
        if let b12 = fragmenter.fragment(at: 12, for: .bIon) {
            #expect(b12.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 1126.5561) // b12
        }
     
        let bIonsMinusWater = fragments.filter { $0.fragmentType == .bIonMinusWater }
        #expect(bIonsMinusWater.count == 14)
     
        if let b12MinusWater = fragmenter.fragment(at: 12, for: .bIonMinusWater) {
            #expect(b12MinusWater.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 1108.5456) // b12 - H2O
        }
     
        if let b12MinusAmmonia = fragmenter.fragment(at: 12, for: .bIonMinusAmmonia) {
            #expect(b12MinusAmmonia.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 1109.5296) // b12 - NH3
        }
     
        let zIons = fragments.filter { $0.fragmentType == .zIon }
        #expect(zIons.count == 26)
     
        let cIons = fragments.filter { $0.fragmentType == .cIon }
        #expect(cIons.count == 14)
     
        if let c1 = fragmenter.fragment(at: 1, for: .cIon) {
            #expect(c1.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 105.0659) // c1
        }
    }
     
    @Test func chargedResidues() {
        let fragment = PeptideFragment(sequence: "AWRKQNWSTEDWWSHTEDWQPRTYSAMPLER")
     
        let numOfCharges = fragment.maxNumberOfCharges()
        #expect(numOfCharges == 5)
    }
     
    @Test func allFragmentCases() {
        let allCases = PeptideFragmentType.allCases
        #expect(allCases.count == 17)
    }
     
    @Test func biomolecule() {
        var peptide1 = Peptide(residues: [alanine, alanine, serine, alanine, serine])
        print(peptide1.sequenceString)
        #expect(peptide1.sequenceLength == 5)
     
        peptide1.setAdducts(type: protonAdduct, count: 1)
        #expect(peptide1.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 406.1932)
     
        var peptide2 = Peptide(residues: peptide1.residues + [serine, serine, alanine])
        print(peptide2.sequenceString)
        #expect(peptide2.sequenceLength == 8)
     
        peptide2.setAdducts(type: protonAdduct, count: 2)
        #expect(peptide2.massOverCharge().monoisotopicMass.roundedDouble(to: 4) == 326.1508)
     
        var protein = Protein(chains: [peptide1, peptide2])
     
        #expect(protein.sequence(for: 0) == "AASAS")
        #expect(protein.sequence(for: 1) == "AASASSSA")
     
        #expect(protein.aminoAcids(for: 0).map { $0.oneLetterCode } == ["A", "A", "S", "A", "S"])
        #expect(protein.aminoAcids(for: 1).map { $0.oneLetterCode } == ["A", "A", "S", "A", "S", "S", "S", "A"])
     
        protein.setAdducts(type: protonAdduct, count: 1, for: 0)
        protein.setAdducts(type: protonAdduct, count: 0, for: 1)
     
        let peptide3 = protein.chains[0]
        let peptide4 = protein.chains[1]
        let mass0 = peptide3.massOverCharge().monoisotopicMass.roundedDouble(to: 4) // 406.1932
        #expect(mass0 == 406.1932)
     
        let mass1 = peptide4.massOverCharge().monoisotopicMass.roundedDouble(to: 4) // 326.1508
        #expect(mass1 == 326.1508)
     
        let mass = protein.massOverCharge().monoisotopicMass.roundedDouble(to: 4) // 1055.4731
        #expect(mass == mass0 + mass1)
    }
}
