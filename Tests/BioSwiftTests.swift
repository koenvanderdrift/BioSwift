//
//  BioSwiftTests.swift
//  BioSwift
//
//  Created by Koen van der Drift on 26.12.2025.
//

@testable import BioSwift
import Foundation
import Testing

// https://stackoverflow.com/questions/79856701/swift-testing-load-data-before-the-tests-start/

// struct DataLibraryTrait: SuiteTrait, TestScoping {
//    func provideScope(for _: Test, testCase _: Test.Case?, performing function: @Sendable () async throws -> Void) async throws {
//        print("start set up")
//
//        let _ = DataLibraryDefaults.bundled
//        let data = try loadData(
//            from: "unimod",
//            withExtension: "xml",
//            in: .module
//        )
//
//        try _ = UnimodXMLParser().parse(data: data)
//        try await function()
//        print("tests completed")
//    }
// }
//
// extension SuiteTrait where Self == DataLibraryTrait {
//    static var bioSwiftDataLbrary: DataLibraryTrait {
//        .init()
//    }
// }
//
// @Suite(.bioSwiftDataLbrary)
struct BioSwiftTests {
    var testProtein =
        Protein(
            sequence: "MPSSVSWGILLLAGLCCLVPVSLAEDPQGDAAQKTDTSHHDQDHPTFNKITPNLAEFAFSLYRQLAHQSNSTNIFFSPIVSIATAFAMLSLGTKADTHDEILEGLNFNLTEIPEAQIHEGFQELLRTLNQPDSQLQLTTGNGLFLSEGLKLVDKFLEDVKKLYHSEAFTVNFGDTEEAKKQINDYVEKGTQGKIVDLVKELDRDTVFALVNYIFFKGKWERPFEVKDTEEEDFHVDQVTTVKVPMMKRLGMFNIQHCKKLSSWVLLMKYLGNATAIFFLPDEGKLQHLENELTHDIITKFLENEDRRSASLHLPKLSITGTYDLKSVLGQLGITKVFSNGADLSGVTEEAPLKLSKAVHKAVLTIDEKGTEAAGAMFLEAIPMSIPPEVKFNKPFVFMIEQNTKSPLFMGKVVNPTQK")
    var testPeptide = Peptide(sequence: "DWSSD")
    var alanine = AminoAcid(name: "Alanine", oneLetterCode: "A", threeLetterCode: "Ala", formula: Formula("C3H5NO"))
    var serine = AminoAcid(name: "Serine", oneLetterCode: "S", threeLetterCode: "Ser", formula: Formula("C3H5NO2"))

    @Test
    func bundledDataLibrariesLoadProperly() throws {
        let libraries = try DataLibraryDefaults.loadBundled()

        #expect(!libraries.elements.isEmpty)
        #expect(!libraries.modifications.isEmpty)
        #expect(!libraries.aminoAcids.isEmpty)
        #expect(!libraries.enzymes.isEmpty)
        #expect(!libraries.hydropathyValues.isEmpty)
    }

    @Test
    func bundledDefaultsAreAvailable() {
        let libraries = DataLibraryDefaults.bundled

        #expect(!libraries.elements.isEmpty)
        #expect(!libraries.modifications.isEmpty)
        #expect(!libraries.aminoAcids.isEmpty)
        #expect(!libraries.enzymes.isEmpty)
        #expect(!libraries.hydropathyValues.isEmpty)
    }

    @Test
    func xmlResourceExistsAndLoads() throws {
        let data = try loadData(
            from: "unimod",
            withExtension: "xml",
            in: .module)

        #expect(!data.isEmpty)
    }

    @Test
    func xmlDataLibrariesLoadProperly() throws {
        let xmlLibraries = try XMLDataLibraryLoader.load()

        #expect(!xmlLibraries.aminoAcids.isEmpty)
        #expect(!xmlLibraries.modifications.isEmpty)
    }

    @Test
    func jsonDataLibrariesLoadProperly() throws {
        let jsonLibraries = try JSONDataLibraryLoader.loadOtherLibraries()

        #expect(!jsonLibraries.enzymes.isEmpty)
        #expect(!jsonLibraries.hydropathyValues.isEmpty)
    }

    @Test
    func xmlDataLibrariesLoadDebug() throws {
        let xmlLibraries = try XMLDataLibraryLoader.load()

        print("aminoAcids:", xmlLibraries.aminoAcids.count)
        print("modifications:", xmlLibraries.modifications.count)

        #expect(!xmlLibraries.aminoAcids.isEmpty)
        #expect(!xmlLibraries.modifications.isEmpty)
    }

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
        #expect(peptide.formula.countFor(element: "P") == 0)
    }

    @Test func modifiedPeptideFormula() {
        var peptide = Peptide(sequence: "DWSSD")
        if let ser = modificationLibrary.first(where: { $0.name == "Phospho" }) {
            peptide.addModification(LocalizedModification(ser, at: 3))
            #expect(peptide.formula.countFor(element: "P") == 1)
        }
    }

    @Test func waterAverageMass() { // H2O
        #expect(water.averageMass.rounded(scale: 4) == decimal("18.0153"))
    }

    @Test func ammoniaAverageMass() { // NH3
        #expect(ammonia.averageMass.rounded(scale: 4) == decimal("17.0305"))
    }

    @Test func methylAverageMass() { // CH3
        #expect(methyl.averageMass.rounded(scale: 4) == decimal("15.0345")) // 15.0346
    }

    @Test func formulaAverageMass() { // C4H5NO3 + C11H10N2O + C3H5NO2 + C3H5NO2 + C4H5NO3 + H2O
        let group = FunctionalGroup(name: "", formula: "C4H5NO3" + "C11H10N2O" + "C3H5NO2" + "C3H5NO2" + "C4H5NO3" + "H2O")

        #expect(group.averageMass.rounded(scale: 3) == decimal("608.555"))
    } // 608.5556

    @Test mutating func peptideMonoisotopicMass() {
        testPeptide.setAdducts(type: protonAdduct, count: 1)
        #expect(testPeptide.monoisotopicMass.rounded(scale: 4) == decimal("609.2151"))

        testPeptide.setAdducts(type: protonAdduct, count: 2)
        #expect(testPeptide.monoisotopicMass.rounded(scale: 4) == decimal("305.1112"))
    }

    @Test mutating func peptideAverageMass() {
        testPeptide.setAdducts(type: protonAdduct, count: 1)
        #expect(testPeptide.averageMass.rounded(scale: 4) == decimal("609.5731")) // 609.5630

        testPeptide.setAdducts(type: protonAdduct, count: 2)
        #expect(testPeptide.averageMass.rounded(scale: 4) == decimal("305.2903")) // 305.2852
    }

    @Test mutating func peptideSerinePhosphorylationMonoisotopicMass() {
        if let phos = modificationLibrary.first(where: { $0.name == "Phospho" }) {
            testPeptide.addModification(LocalizedModification(phos, at: 3))

            testPeptide.setAdducts(type: protonAdduct, count: 1)
            #expect(testPeptide.monoisotopicMass.rounded(scale: 4) == decimal("689.1814"))

            testPeptide.setAdducts(type: protonAdduct, count: 2)
            #expect(testPeptide.monoisotopicMass.rounded(scale: 4) == decimal("345.0944"))

            testPeptide.removeModification(at: 3)
            testPeptide.setAdducts(type: protonAdduct, count: 1)
            #expect(testPeptide.monoisotopicMass.rounded(scale: 4) == decimal("609.2151"))
        }
    }

    @Test mutating func peptideReplaceModificationMonoisotopicMass() {
        if let phos = modificationLibrary.first(where: { $0.name == "Phospho" }),
           let methylmalonylation = modificationLibrary.first(where: { $0.name == "Methylmalonylation" })
        {
            testPeptide.addModification(LocalizedModification(phos, at: 3))

            testPeptide.setAdducts(type: protonAdduct, count: 1)
            #expect(testPeptide.monoisotopicMass.rounded(scale: 4) == decimal("689.1814"))

            testPeptide.setAdducts(type: protonAdduct, count: 2)
            #expect(testPeptide.monoisotopicMass.rounded(scale: 4) == decimal("345.0944"))

            testPeptide.addModification(LocalizedModification(methylmalonylation, at: 3))
            testPeptide.setAdducts(type: protonAdduct, count: 1)
            #expect(testPeptide.monoisotopicMass.rounded(scale: 4) == decimal("709.2311"))
        }
    }

    @Test mutating func proteinMonoisotopicMass() {
        testProtein.setAdducts(type: protonAdduct, count: 1)
        #expect(testProtein.monoisotopicMass.rounded(scale: 1) == decimal("46708.0267").rounded(scale: 1))
    }

    @Test mutating func proteinNTermMetLossMonoisotopicMass() {
        if let metLoss = testProtein.nTermModifications().first(where: { $0.name == "Met-loss" }) {
            testProtein.setAdducts(type: protonAdduct, count: 1)

            testProtein.addModification(mod: metLoss, at: testProtein.nTermLocation())
            #expect(testProtein.monoisotopicMass.rounded(scale: 1) == (decimal("46708.0267") - decimal("131.040485)")).rounded(scale: 1))

            testProtein.removeModification(at: testProtein.nTermLocation())
            #expect(testProtein.monoisotopicMass.rounded(scale: 1) == decimal("46708.0267").rounded(scale: 1))
        }
    }

    @Test mutating func proteinCTermLysLossMonoisotopicMass() {
        if let lysLoss = testProtein.cTermModifications().first(where: { $0.name == "Lys-loss" }) {
            testProtein.setAdducts(type: protonAdduct, count: 1)

            testProtein.addModification(mod: lysLoss, at: testProtein.cTermLocation())
            #expect(testProtein.monoisotopicMass.rounded(scale: 1) == (decimal("46708.0267") - decimal("128.094963)")).rounded(scale: 1))

            testProtein.removeModification(at: testProtein.cTermLocation())
            #expect(testProtein.monoisotopicMass.rounded(scale: 4) == decimal("46708.0267"))
        }
    }

    @Test mutating func proteinAverageMass() {
        testProtein.setAdducts(type: protonAdduct, count: 1)
        #expect(testProtein.averageMass.rounded(scale: 1) == decimal("46737.9568").rounded(scale: 1))
    } // 46737.0703

    @Test mutating func proteinSerinePhosphorylationMonoisotopicMass() {
        if let phos = modificationLibrary.first(where: { $0.name == "Phospho" }) {
            testProtein.addModification(mod: phos, at: 3)
            testProtein.setAdducts(type: protonAdduct, count: 1)
            #expect(phos.fullName == "Phosphorylation")
            #expect(testProtein.monoisotopicMass.rounded(scale: 1) == decimal("46787.9931").rounded(scale: 1)) // 46787.9930

            testProtein.setAdducts(type: protonAdduct, count: 2)
            #expect(testProtein.monoisotopicMass.rounded(scale: 1) == decimal("23394.5002").rounded(scale: 1))
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

    @Test mutating func modifyResidues() {
        if let cam = modificationLibrary.first(where: { $0.name == "Carbamidomethyl" }) {
            testProtein.modifyResidues(for: "C", with: cam)

            #expect(testProtein.countOneResidue(with: "C") == 3)
        }
    }

    @Test func addFormulas() {
        let formula1 = Formula("C12H23O7N5")
        let formula2 = Formula("C2H2O2")
        let formula3 = formula1 + formula2

        print(formula3.string)

        #expect(formula3.countFor(element: "C") == 14)
        #expect(formula3.countFor(element: "N") == 5)
    }

    @Test func subtractFormulas() {
        let formula1 = Formula("C12H23O7N5")
        let formula2 = Formula("C2H2O2")
        let formula3 = formula1 - formula2

        print(formula3.string)

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
        if let gly = aminoAcidLibrary.first(where: { $0.identifier == "G" }),
           let pro = aminoAcidLibrary.first(where: { $0.identifier == "P" })
        {
            testPeptide.insertResidues([gly, pro, pro], at: 2)
        }

        #expect(testPeptide.sequenceString == "DWGPPSSD")
    }

    @Test func parseFasta() async {
        do {
            let fastaRecords = try await FastaParser().parseBundleFile("ecoli")
            #expect(fastaRecords.count == 4392)

            if let record = fastaRecords.first(where: { $0.accession == "P02919" }) {
                #expect(record.shortName == "PBPB_ECOLI")
                #expect(record.fullName == "Penicillin-binding protein 1B")
                #expect(record.organism == "Escherichia coli (strain K12)")
                #expect(record
                    .sequence ==
                    "MAGNDREPIGRKGKPTRPVKQKVSRRRYEDDDDYDDYDDYEDEEPMPRKGKGKGKGRKPRGKRGWLWLLLKLAIVFAVLIAIYGVYLDQKIRSRIDGKVWQLPAAVYGRMVNLEPDMTISKNEMVKLLEATQYRQVSKMTRPGEFTVQANSIEMIRRPFDFPDSKEGQVRARLTFDGDHLATIVNMENNRQFGFFRLDPRLITMISSPNGEQRLFVPRSGFPDLLVDTLLATEDRHFYEHDGISLYSIGRAVLANLTAGRTVQGASTLTQQLVKNLFLSSERSYWRKANEAYMALIMDARYSKDRILELYMNEVYLGQSGDNEIRGFPLASLYYFGRPVEELSLDQQALLVGMVKGASIYNPWRNPKLALERRNLVLRLLQQQQIIDQELYDMLSARPLGVQPRGGVISPQPAFMQLVRQELQAKLGDKVKDLSGVKIFTTFDSVAQDAAEKAAVEGIPALKKQRKLSDLETAIVVVDRFSGEVRAMVGGSEPQFAGYNRAMQARRSIGSLAKPATYLTALSQPKIYRLNTWIADAPIALRQPNGQVWSPQNDDRRYSESGRVMLVDALTRSMNVPTVNLGMALGLPAVTETWIKLGVPKDQLHPVPAMLLGALNLTPIEVAQAFQTIASGGNRAPLSALRSVIAEDGKVLYQSFPQAERAVPAQAAYLTLWTMQQVVQRGTGRQLGAKYPNLHLAGKTGTTNNNVDTWFAGIDGSTVTITWVGRDNNQPTKLYGASGAMSIYQRYLANQTPTPLNLVPPEDIADMGVDYDGNFVCSGGMRILPVWTSDPQSLCQQSEMQQQPSGNPFDQSSQPQQQPQQQPAQQEQKDSDGVAGWIKDMFGSN")
            }
        } catch {
            debugPrint(error.localizedDescription)
        }
    }

    @Test func subChain() {
        if let chain = testProtein.chains.first {
            let range1: Range<Int> = 2 ..< 9
            let subChain1 = chain.subChain(range: range1)
            #expect(subChain1.sequenceString == "SSVSWGI")

            let range2: Range<Int> = 0 ..< 10
            let subChain2 = chain.removing(range2)
            #expect(subChain2
                .sequenceString ==
                "LLAGLCCLVPVSLAEDPQGDAAQKTDTSHHDQDHPTFNKITPNLAEFAFSLYRQLAHQSNSTNIFFSPIVSIATAFAMLSLGTKADTHDEILEGLNFNLTEIPEAQIHEGFQELLRTLNQPDSQLQLTTGNGLFLSEGLKLVDKFLEDVKKLYHSEAFTVNFGDTEEAKKQINDYVEKGTQGKIVDLVKELDRDTVFALVNYIFFKGKWERPFEVKDTEEEDFHVDQVTTVKVPMMKRLGMFNIQHCKKLSSWVLLMKYLGNATAIFFLPDEGKLQHLENELTHDIITKFLENEDRRSASLHLPKLSITGTYDLKSVLGQLGITKVFSNGADLSGVTEEAPLKLSKAVHKAVLTIDEKGTEAAGAMFLEAIPMSIPPEVKFNKPFVFMIEQNTKSPLFMGKVVNPTQK")

            let range3: Range<Int> = (10 ..< 400)
            let subChain3 = chain.removing(range3)
            #expect(subChain3.sequenceString == "MPSSVSWGILQNTKSPLFMGKVVNPTQK")
        }
    }

    @Test func subChainWithModification() {
        var peptide = Peptide(sequence: "SAMPLEVCAAAGQTHR")
        peptide.setAdducts(type: protonAdduct, count: 1)
        #expect(peptide.monoisotopicMass.rounded(scale: 4) == decimal("1641.7836"))

        if let cysMod = modificationLibrary.first(where: { $0.name == "Carboxymethyl" }) {
            #expect(cysMod.fullName == "Iodoacetic acid derivative")
            peptide.addModification(LocalizedModification(cysMod, at: 8))
            #expect(peptide.monoisotopicMass.rounded(scale: 4) == decimal("1699.7891"))

            let range = (2 ..< 12)
            let subChain = peptide.subChain(range: range)
            #expect(subChain.sequenceString == "MPLEVCAAAG")
            #expect(subChain.modification(at: 6) == cysMod)
            #expect(subChain.monoisotopicMass.rounded(scale: 4) == decimal("1019.4536"))
        }
    }

    @Test func emptySequence() {
        let peptide = Peptide(sequence: "")
        #expect(peptide.masses == zeroMass)
    }

    @Test func emptySelection() {
        #expect(testProtein.selectionMass(zeroRange) == zeroMass)
    }

    @Test func digest() {
        let digester = ProteinDigester(protein: testProtein)

        let missedCleavages = 0

        let trypsin = enzymeLibrary.first(where: { $0.name == "Trypsin" })

        if let enzyme = trypsin {
            let peptides: [Peptide] = digester.peptides(using: enzyme, with: missedCleavages)

            #expect(peptides[0].sequenceString == "MPSSVSWGILLLAGLCCLVPVSLAEDPQGDAAQK")
            #expect(peptides[1].sequenceString == "TDTSHHDQDHPTFNK")
        }

        let aspN = enzymeLibrary.first(where: { $0.name == "Asp-N" })

        if let enzyme = aspN {
            let peptides: [Peptide] = digester.peptides(using: enzyme, with: missedCleavages)

            #expect(peptides[0].sequenceString == "MPSSVSWGILLLAGLCCLVPVSLAE")
            #expect(peptides[1].sequenceString == "DPQG")
        }
    }

    @Test func digestUnspecified() {
        let unspecified = enzymeLibrary.first(where: { $0.name == "Unspecified" })
        #expect(unspecified?.name == "Unspecified")
    }

    @Test func digestMasses() {
        let digester = ProteinDigester(protein: testProtein)

        let missedCleavages = 1

        let trypsin = enzymeLibrary.first(where: { $0.name == "Trypsin" })

        if let enzyme = trypsin {
            let peptides: [Peptide] = digester.peptides(using: enzyme, with: missedCleavages)
                .charge(with: 1 ... 1)
            #expect(peptides[0].monoisotopicMass.rounded(scale: 4) == decimal("3468.7575")) // 3467.7503
            #expect(peptides[2].monoisotopicMass.rounded(scale: 4) == decimal("1779.7681")) // 1778.7608
        }
    }

    @Test func lowMassSearch() {
        if let chain = testProtein.chains.first {
            let searchParameters = MassSearchParameters(searchValue: 1,
                                                        tolerance: MassTolerance(type: .ppm, value: 20),
                                                        searchType: .sequential,
                                                        massType: .monoisotopic,
                                                        charge: 0)

            let peptides: [Peptide] = chain.searchMass(params: searchParameters)
            print(peptides.map(\.sequenceString))

            #expect(peptides.isEmpty)
        }
    }

    @Test func massSearch() {
        if let chain = testProtein.chains.first {
            let searchParameters = MassSearchParameters(searchValue: 609.71,
                                                        tolerance: MassTolerance(type: .ppm, value: 20),
                                                        searchType: .sequential,
                                                        massType: .average,
                                                        charge: 0)

            let peptides: [Peptide] = chain.searchMass(params: searchParameters)

            #expect(peptides.contains(where: { $0.sequenceString == "IFFSP" }))
            #expect(!peptides.contains(where: { $0.sequenceString == "NIFFS" }))

            let ranges = chain.searchMass(using: searchParameters)
            let sequenceStrings = ranges.map { chain.sequenceString[$0] }

            #expect(sequenceStrings.contains(where: { $0 == "IFFSP" }))
            #expect(!sequenceStrings.contains(where: { $0 == "NIFFS" }))
        }
    }

    @Test func massSearchWithModification() {
        if var chain = testProtein.chains.first,
           let phos = modificationLibrary.first(where: { $0.name == "Phospho" })
        {
            chain.addModification(LocalizedModification(phos, at: 76))

            let searchParameters = MassSearchParameters(searchValue: 689.28,
                                                        tolerance: MassTolerance(type: .ppm, value: 20),
                                                        searchType: .sequential,
                                                        massType: .monoisotopic,
                                                        charge: 0)

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

        #expect(peptide.monoisotopicMass.rounded(scale: 4) == decimal("803.4080"))
        #expect(peptide.monoisotopicMass.rounded(scale: 4) == decimal("803.4080"))

        let fragmenter = PeptideFragmenter(peptide: peptide)
        let fragments = fragmenter.fragments

        let precursors = fragments.filter { $0.isPrecursor() }
        #expect(precursors[0].monoisotopicMass.rounded(scale: 4) == decimal("803.4080"))
        #expect(precursors[1].monoisotopicMass.rounded(scale: 4) == decimal("785.3974"))
        #expect(precursors[2].monoisotopicMass.rounded(scale: 4) == decimal("786.3815"))

        if let a1 = fragmenter.fragment(at: 1, for: .aIon) {
            #expect(a1.monoisotopicMass.rounded(scale: 4) == decimal("131.0815")) // a1
        }

        if let b2 = fragmenter.fragment(at: 2, for: .bIon) {
            #expect(b2.monoisotopicMass.rounded(scale: 4) == decimal("159.0764")) // b2
        }

        if let b2minH2O = fragmenter.fragment(at: 2, for: .bIonMinusWater) {
            #expect(b2minH2O.monoisotopicMass.rounded(scale: 4) == decimal("141.0659")) // b2-H2O
        }

        if let b3minH2O = fragmenter.fragment(at: 3, for: .bIonMinusWater) {
            #expect(b3minH2O.monoisotopicMass.rounded(scale: 4) == decimal("272.1063")) // b3-H2O
        }

        if let x1 = fragmenter.fragment(at: 1, for: .xIon) {
            #expect(x1.monoisotopicMass.rounded(scale: 4) == decimal("201.0982")) // x1
        }

        if let y1 = fragmenter.fragment(at: 1, for: .yIon) {
            #expect(y1.monoisotopicMass.rounded(scale: 4) == decimal("175.1190")) // y1
        }

        if let y1minNH3 = fragmenter.fragment(at: 1, for: .yIonMinusAmmonia) {
            #expect(y1minNH3.monoisotopicMass.rounded(scale: 4) == decimal("158.0924")) // y1-NH3
        }

        if let y2minH2O = fragmenter.fragment(at: 2, for: .yIonMinusWater) {
            #expect(y2minH2O.monoisotopicMass.rounded(scale: 4) == decimal("286.1510")) // y2-H2O
        }
    }

    @Test func fragmentMass2() {
        var peptide = Peptide(sequence: "SAMPLEVAAAGQTHR")
        peptide.setAdducts(type: protonAdduct, count: 1)

        #expect(peptide.monoisotopicMass.rounded(scale: 4) == decimal("1538.7744"))

        let fragmenter = PeptideFragmenter(peptide: peptide)
        let fragments = fragmenter.fragments

        let bIons = fragments.filter { $0.fragmentType == .bIon }
        #expect(bIons.count == 13)

        if let b2 = fragmenter.fragment(at: 2, for: .bIon) {
            #expect(b2.monoisotopicMass.rounded(scale: 4) == decimal("159.0764")) // b2
        }

        if let b12 = fragmenter.fragment(at: 12, for: .bIon) {
            #expect(b12.monoisotopicMass.rounded(scale: 4) == decimal("1126.5561")) // b12
        }

        if let b12minH2O = fragmenter.fragment(at: 12, for: .bIonMinusWater) {
            #expect(b12minH2O.monoisotopicMass.rounded(scale: 4) == decimal("1108.5456")) // b12 - H2O
        }

        if let b12minNH3 = fragmenter.fragment(at: 12, for: .bIonMinusAmmonia) {
            #expect(b12minNH3.monoisotopicMass.rounded(scale: 4) == decimal("1109.5296")) // b12 - NH3
        }

        let zIons = fragments.filter { $0.fragmentType == .zIon }
        #expect(zIons.count == 13)

        let cIons = fragments.filter { $0.fragmentType == .cIon }
        #expect(cIons.count == 13)

        if let c1 = fragmenter.fragment(at: 1, for: .cIon) {
            #expect(c1.monoisotopicMass.rounded(scale: 4) == decimal("105.0659")) // c1
        }
    }

    @Test func fragmentMass3() {
        var peptide = Peptide(sequence: "SAMPLEVAMAAGQTHR")
        peptide.setAdducts(type: protonAdduct, count: 1)

        if let ox = modificationLibrary.first(where: { $0.name == "Oxidation" }) {
            #expect(ox.fullName == "Oxidation or Hydroxylation")
            peptide.addModification(LocalizedModification(ox, at: 8))
            #expect(peptide.monoisotopicMass.rounded(scale: 4) == decimal("1685.8098"))

            let fragmenter = PeptideFragmenter(peptide: peptide)
            let fragments = fragmenter.fragments

            let aIonsMinusWater = fragments.filter { $0.fragmentType == .aIonMinusWater }
            #expect(aIonsMinusWater.count == 14)

            let aIonsMinusAmmonia = fragments.filter { $0.fragmentType == .aIonMinusAmmonia }
            #expect(aIonsMinusAmmonia.count == 3)

            let bIons = fragments.filter { $0.fragmentType == .bIon }
            #expect(!bIons.contains(where: { $0.index == 1 }))

            let yIons = fragments.filter { $0.fragmentType == .yIonMinusWater }
            #expect(!yIons.contains(where: { $0.index == 1 }))
            #expect(!yIons.contains(where: { $0.index == 2 }))

            if let b8 = fragmenter.fragment(at: 8, for: .bIon) {
                #expect(b8.monoisotopicMass.rounded(scale: 4) == decimal("799.4019")) // b8 M-ox
            }

            if let y9 = fragmenter.fragment(at: 9, for: .yIon) {
                #expect(y9.monoisotopicMass.rounded(scale: 4) == decimal("958.4523")) // y9 M-ox
            }

            if let x9 = fragmenter.fragment(at: 9, for: .xIon) {
                #expect(x9.monoisotopicMass.rounded(scale: 4) == decimal("984.4316")) // x9 M-ox
            }

            let zIons = fragments.filter { $0.fragmentType == .zIon }
            #expect(!zIons.contains(where: { $0.index == 13 }))

            if let z12 = fragmenter.fragment(at: 12, for: .zIon) {
                #expect(z12.monoisotopicMass.rounded(scale: 4) == decimal("1283.6287")) // z12 M-ox
            }
        }
    }

    @Test func fragmentMass4() {
        var peptide = Peptide(sequence: "AWRKQNWSTEDWWSTEDWQPRTYSAMPLER")
        peptide.setAdducts(type: protonAdduct, count: 1)

        let fragmenter = PeptideFragmenter(peptide: peptide)
        let fragments = fragmenter.fragments

        let bIonsMinusWater = fragments.filter { $0.fragmentType == .bIonMinusWater }
        #expect(!bIonsMinusWater.contains(where: { $0.index == 1 }))
        #expect(!bIonsMinusWater.contains(where: { $0.index == 2 }))
        #expect(!bIonsMinusWater.contains(where: { $0.index == 3 }))
        #expect(!bIonsMinusWater.contains(where: { $0.index == 4 }))
        #expect(!bIonsMinusWater.contains(where: { $0.index == 5 }))
        #expect(!bIonsMinusWater.contains(where: { $0.index == 6 }))
        #expect(!bIonsMinusWater.contains(where: { $0.index == 7 }))
        #expect(bIonsMinusWater.contains(where: { $0.index == 8 }))

        if let b8MinusWater = fragmenter.fragment(at: 8, for: .bIonMinusWater) {
            #expect(b8MinusWater.monoisotopicMass.rounded(scale: 4) == decimal("1039.5221")) // b8-H20
        }
    }

    @Test func fragmentMass5() {
        var peptide = Peptide(sequence: "SAMPLEVAAAGQTHR")
        peptide.setAdducts(type: protonAdduct, count: 2)

        #expect(peptide.monoisotopicMass.rounded(scale: 4) == decimal("769.8908"))

        let fragmenter = PeptideFragmenter(peptide: peptide)
        let fragments = fragmenter.fragments

        let bIons = fragments.filter { $0.fragmentType == .bIon }
        #expect(bIons.count == 14)

        if let b2 = fragmenter.fragment(at: 2, for: .bIon) {
            #expect(b2.monoisotopicMass.rounded(scale: 4) == decimal("159.0764")) // b2
        }

        if let b12 = fragmenter.fragment(at: 12, for: .bIon) {
            #expect(b12.monoisotopicMass.rounded(scale: 4) == decimal("1126.5561")) // b12
        }

        let bIonsMinusWater = fragments.filter { $0.fragmentType == .bIonMinusWater }
        #expect(bIonsMinusWater.count == 14)

        if let b12MinusWater = fragmenter.fragment(at: 12, for: .bIonMinusWater) {
            #expect(b12MinusWater.monoisotopicMass.rounded(scale: 4) == decimal("1108.5456")) // b12 - H2O
        }

        if let b12MinusAmmonia = fragmenter.fragment(at: 12, for: .bIonMinusAmmonia) {
            #expect(b12MinusAmmonia.monoisotopicMass.rounded(scale: 4) == decimal("1109.5296")) // b12 - NH3
        }

        let zIons = fragments.filter { $0.fragmentType == .zIon }
        #expect(zIons.count == 26)

        let cIons = fragments.filter { $0.fragmentType == .cIon }
        #expect(cIons.count == 14)

        if let c1 = fragmenter.fragment(at: 1, for: .cIon) {
            #expect(c1.monoisotopicMass.rounded(scale: 4) == decimal("105.0659")) // c1
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
        #expect(peptide1.sequenceLength == 5)

        peptide1.setAdducts(type: protonAdduct, count: 1)
        #expect(peptide1.monoisotopicMass.rounded(scale: 4) == decimal("406.1932"))
        var peptide2 = Peptide(residues: peptide1.residues + [serine, serine, alanine])
        #expect(peptide2.sequenceLength == 8)

        peptide2.setAdducts(type: protonAdduct, count: 2)
        #expect(peptide2.monoisotopicMass.rounded(scale: 4) == decimal("326.1508"))

        var protein = Protein(chains: [peptide1, peptide2])

        #expect(protein.sequence(for: 0) == "AASAS")
        #expect(protein.sequence(for: 1) == "AASASSSA")

        #expect(protein.aminoAcids(for: 0).map { $0.oneLetterCode } == ["A", "A", "S", "A", "S"])
        #expect(protein.aminoAcids(for: 1).map { $0.oneLetterCode } == ["A", "A", "S", "A", "S", "S", "S", "A"])

        protein.setAdducts(type: protonAdduct, count: 1, for: 0)
        let peptide3 = protein.chains[0]
        let mass3 = peptide3.monoisotopicMass
        #expect(mass3.rounded(scale: 4) == decimal("406.1932"))

        protein.setAdducts(type: protonAdduct, count: 0, for: 1)
        let peptide4 = protein.chains[1]
        let mass4 = peptide4.monoisotopicMass
        #expect(mass4.rounded(scale: 4) == decimal("326.1508"))

        protein.chains[0] = peptide3
        protein.chains[1] = peptide4

        let mass = protein.monoisotopicMass
        #expect(mass == mass3 + mass4)
        #expect(mass.rounded(scale: 4) == (mass3 + mass4).rounded(scale: 4))
    }

    @Test func checkRegex() {
        let data = """
        BEGIN PEPTIDE
        ABCDEF
        END PEPTIDE
        BEGIN PEPTIDE
        GHIJKL
        END PEPTIDE
        """

        let beginRanges = data.ranges(of: "BEGIN PEPTIDE")
        let endRanges = data.ranges(of: "END PEPTIDE")

        #expect(beginRanges.count == 2)
        #expect(endRanges.count == 2)

        let text = """
        BEGIN SEQUENCE
        MKWVTFISLL
        END SEQUENCE
        """

        let sequence = text.substring(
            between: "BEGIN SEQUENCE",
            and: "END SEQUENCE")?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        #expect(sequence == "MKWVTFISLL")
    }

    @Test func findSubStrings() {
        let text = """
        BEGIN PEPTIDE
        PEPTIDEK
        END PEPTIDE
        BEGIN PEPTIDE
        MKWVTF
        END PEPTIDE
        """

        let peptides = text
            .substrings(between: "BEGIN PEPTIDE", and: "END PEPTIDE")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        #expect(peptides == ["PEPTIDEK", "MKWVTF"])
    }

    @Test
    func findsSingleLetterRanges() {
        let sequence = "AAAA"

        #expect(sequence.sequenceRanges(of: "A") == [0 ..< 1, 1 ..< 2, 2 ..< 3, 3 ..< 4])
    }

    @Test
    func findsNonOverlappingSequenceRanges() {
        let sequence = "AAAA"

        #expect(sequence.sequenceRanges(of: "AA") == [0 ..< 2, 2 ..< 4])
    }

    @Test
    func findsOverlappingSequenceRanges() {
        let sequence = "AAAA"

        #expect(
            sequence.sequenceRanges(of: "AA", allowingOverlaps: true)
                == [0 ..< 2, 1 ..< 3, 2 ..< 4])
    }

    @Test("Finds all non-overlapping matching ranges")
    func stringMatchingRanges() {
        let text = "ABC DEF ABC"

        let result = text.ranges(matching: "ABC")

        #expect(result == [
            0 ..< 3,
            8 ..< 11,
        ])
    }

    @Test("Empty search string returns no ranges")
    func emptySearchStringReturnsNoRanges() {
        let text = "ABC DEF ABC"

        #expect(text.ranges(matching: "").isEmpty)
    }

    @Test("Missing search string returns no ranges")
    func missingSearchStringReturnsNoRanges() {
        let text = "ABC DEF ABC"

        #expect(text.ranges(matching: "XYZ").isEmpty)
    }

    @Test("Single-character matches return one-length ranges")
    func singleCharacterMatchingRanges() {
        let text = "ABACA"

        let result = text.ranges(matching: "A")

        #expect(result == [
            0 ..< 1,
            2 ..< 3,
            4 ..< 5,
        ])
    }

    @Test
    func convertsSequenceCoordinatesToOneBasedRanges() {
        let sequence = "MKWVTFISLL"

        #expect(sequence.sequenceRanges(of: "VTF") == [3 ..< 6])
    }

    @Test
    func emptySubstringProducesNoRanges() {
        let sequence = "PEPTIDE"

        #expect(sequence.sequenceRanges(of: "").isEmpty)
    }

    @Test
    func identifiesAnyProhibitedCharacter() {
        let allowedCharacters = CharacterSet(charactersIn: "ACDEFGHIKLMNPQRSTVWY")

        #expect(!"PEPTIDE".containsCharacterOutside(allowedCharacters))
        #expect("PEPT1DE".containsCharacterOutside(allowedCharacters))
    }

    @Test
    func malformedXMLThrowsParseError() throws {
        let malformedXML = """
        <root>
            <item>Broken</root>
        """

        let data = Data(malformedXML.utf8)

        #expect(throws: Error.self) {
            try UnimodXMLParser().parse(
                data: data)
        }
    }

    @Test
    func malformedXMLThrowsParseError2() throws {
        let malformedXML = """
        <root>
            <item>Broken</root>
        """

        let data = Data(malformedXML.utf8)

        let error = try #require(
            #expect(throws: Error.self) {
                try UnimodXMLParser().parse(data: data)
            })

        let nsError = error as NSError

        #expect(nsError.domain == XMLParser.errorDomain)
        #expect(!nsError.localizedDescription.isEmpty)
    }

    @Test
    func malformedXMLThrowsXMLParserError() throws {
        let malformedXML = Data(
            "<root><broken></root>".utf8)

        let parser = UnimodXMLParser()

        let error = try #require(
            #expect(throws: Error.self) {
                try parser.parse(data: malformedXML)
            })

        let nsError = error as NSError

        #expect(nsError.domain == XMLParser.errorDomain)
        #expect(!nsError.localizedDescription.isEmpty)

        #if DEBUG
            debugPrint(
                "Received expected XML parse error:",
                nsError.localizedDescription)
        #endif
    }

    @Test
    func malformedXMLThrowsXMLParserError2() throws {
        let malformedXML = Data(
            "<root><broken></root>".utf8)

        let parser = UnimodXMLParser()

        let error = #expect(throws: Error.self) {
            try parser.parse(data: malformedXML)
        }

        let nsError = try #require(error as NSError?)

        #expect(nsError.domain == XMLParser.errorDomain)
        #expect(!nsError.localizedDescription.isEmpty)
    }

    @Test("ClosedRange to Range")
    func closedRangeToRange() {
        let input: ClosedRange<Int> = 3 ... 7

        let result = range(from: input)

        #expect(result == 3 ..< 8)
    }

    @Test("Range to ClosedRange")
    func rangeToClosedRange() {
        let input: Range<Int> = 3 ..< 8

        let result = closedRange(from: input)

        #expect(result == 3 ... 7)
    }
}

@Test("Convert UIRange to zero-based Range")
func uiRangeToRange() {
    let uiRange = UIRange(1 ... 4)

    let result = uiRange.zeroBasedRange

    #expect(result == 0 ..< 4)
}

@Test("Convert zero-based Range to UIRange")
func rangeToUIRange() {
    let range: Range<Int> = 0 ..< 4

    let result = range.uiRange

    #expect(result == UIRange(1 ... 4))
}

@Test("Round-trip Range through UIRange")
func rangeUIRangeRoundTrip() {
    let original: Range<Int> = 25 ..< 33

    let uiRange = original.uiRange
    let convertedBack = uiRange?.zeroBasedRange

    #expect(uiRange == UIRange(26 ... 33))
    #expect(convertedBack == original)
}

@Test("Empty Range cannot convert to UIRange")
func emptyRangeToUIRange() {
    let emptyRange: Range<Int> = 0 ..< 0

    #expect(emptyRange.uiRange == nil)
}

@Test("UIRange rejects a zero-based ClosedRange")
func invalidUIRange() {
    let result = UIRange(validating: 0 ... 4)

    #expect(result == nil)
}
