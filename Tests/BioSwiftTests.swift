//
//  BioSwiftTests.swift
//  BioSwift
//
//  Created by Koen van der Drift on 26.12.2025.
//  Copyright © 2025 - 2026 Koen van der Drift. All rights reserved.
//

import Foundation
import Testing

@testable import BioSwift

struct BioSwiftTests {
    var testProtein = Protein(
        sequence:
            "MPSSVSWGILLLAGLCCLVPVSLAEDPQGDAAQKTDTSHHDQDHPTFNKITPNLAEFAFSLYRQLAHQSNSTNIFFSPIVSIATAFAMLSLGTKADTHDEILEGLNFNLTEIPEAQIHEGFQELLRTLNQPDSQLQLTTGNGLFLSEGLKLVDKFLEDVKKLYHSEAFTVNFGDTEEAKKQINDYVEKGTQGKIVDLVKELDRDTVFALVNYIFFKGKWERPFEVKDTEEEDFHVDQVTTVKVPMMKRLGMFNIQHCKKLSSWVLLMKYLGNATAIFFLPDEGKLQHLENELTHDIITKFLENEDRRSASLHLPKLSITGTYDLKSVLGQLGITKVFSNGADLSGVTEEAPLKLSKAVHKAVLTIDEKGTEAAGAMFLEAIPMSIPPEVKFNKPFVFMIEQNTKSPLFMGKVVNPTQK"
    )
    var testPeptide = Peptide(sequence: "DWSSD")
    var alanine = AminoAcid(
        name: "Alanine", oneLetterCode: "A", threeLetterCode: "Ala", formula: Formula("C3H5NO"))
    var serine = AminoAcid(
        name: "Serine", oneLetterCode: "S", threeLetterCode: "Ser", formula: Formula("C3H5NO2"))

    private func modifications(
        unimodName: String,
        psiModAccession: String,
        uniProtPTMAccession: String? = nil
    ) throws -> [Modification] {
        let libraries = ReferenceLibraryDefaults.bundled
        let unimodModification = try #require(
            libraries.unimodLibrary.modification(named: unimodName))
        let psiModModification = try #require(
            libraries.psiModLibrary.modification(accession: psiModAccession))
        var result = [unimodModification, psiModModification]

        if let uniProtPTMAccession {
            result.append(try #require(
                libraries.uniProtPTMLibrary.modification(accession: uniProtPTMAccession)))
        }

        return result
    }

    @Test func bundledReferenceLibrariesLoadProperly() throws {
        let libraries = try ReferenceLibraryDefaults.loadBundled()

        #expect(!libraries.elements.isEmpty)
        #expect(!libraries.unimodLibrary.modifications.isEmpty)
        #expect(!libraries.aminoAcids.isEmpty)
        #expect(!libraries.enzymes.isEmpty)
        #expect(!libraries.hydrophobicityScales.isEmpty)
    }

    @Test func bundledDefaultsAreAvailable() {
        let libraries = ReferenceLibraryDefaults.bundled

        #expect(!libraries.elements.isEmpty)
        #expect(!libraries.unimodLibrary.modifications.isEmpty)
        #expect(!libraries.aminoAcids.isEmpty)
        #expect(!libraries.enzymes.isEmpty)
        #expect(!libraries.hydrophobicityScales.isEmpty)
    }

    @Test func bundledHydrophobicityReferencesCacheNumericValues() {
        let pKaValues = HydrophobicityReferenceDefaults.bundled.numericHydrophobicityValues(named: "pKa")

        #expect(pKaValues["CTerminal"] != nil)
        #expect(pKaValues["NTerminal"] != nil)
    }

    @Test func xmlResourceExistsAndLoads() throws {
        let data = try loadData(from: "unimod", withExtension: "xml", in: .module)

        #expect(!data.isEmpty)
    }

    @Test func psiModResourceExistsAndHasExpectedVersion() throws {
        let data = try loadData(from: "PSI-MOD", withExtension: "obo", in: .module)
        let contents = try #require(String(data: data, encoding: .utf8))

        #expect(contents.contains("ontology: mod"))
        #expect(contents.contains("data-version: 1.038.0"))
    }

    @Test func uniProtPTMResourceExistsAndHasExpectedVersion() throws {
        let text = try loadText(from: "ptmlist", withExtension: "txt", in: .module)

        #expect(text.contains("Release:     2026_03"))
    }

    @Test func psiModReferenceLibraryLoadsSeparatelyFromUnimod() throws {
        let libraries = try ReferenceLibraryDefaults.loadBundled()

        #expect(libraries.psiModLibrary.version == "1.038.0")
        #expect(!libraries.psiModLibrary.modifications.isEmpty)
        #expect(libraries.psiModLibrary.modifications.allSatisfy { $0.accession != nil })
        #expect(libraries.psiModLibrary.modification(accession: "MOD:00007") != nil)
    }

    @Test func modificationLibrariesHaveAnExchangeableAPI() throws {
        let libraries = try ReferenceLibraryDefaults.loadBundled()

        func validate(_ library: ModificationLibrary) {
            #expect(!library.modifications.isEmpty)
            #expect(!library.modifications(applicableTo: "M").isEmpty)
        }

        validate(libraries.unimodLibrary)
        validate(libraries.psiModLibrary)
        validate(libraries.uniProtPTMLibrary)
        #expect(libraries.unimodLibrary.modification(accession: "UNIMOD:1") != nil)
    }

    @Test func uniProtPTMLibraryLoadsMetadata() throws {
        let library = ReferenceLibraryDefaults.bundled.uniProtPTMLibrary
        let modification = try #require(library.modification(accession: "PTM-0369"))
        let metadata = try #require(library.metadata(for: modification))

        #expect(library.version == "2026_03")
        #expect(modification.specificities.first?.site == "N")
        #expect(metadata.taxonomicRanges.contains {
            $0.taxonIdentifier == 40674 && $0.name == "Eukaryota"
        })
        #expect(metadata.crossReferences.contains {
            $0.database == "PSI-MOD" && $0.identifier == "MOD:00035"
        })
        #expect(library.modifications(taxonIdentifier: 40674).contains(modification))
    }

    @Test func uniProtPTMParserPreservesRepeatedFieldsRejectsUnsupportedRecordsAndIgnoresProvidedMasses() {
        let text = """
            Release:     test_release of 01-Jan-2026

            ID   Hydroxyasparagine
            AC   PTM-TEST1
            FT   MOD_RES
            TG   Asparagine.
            PP   Anywhere.
            CF   O1
            MM   999.999999
            TR   Eukaryota; taxId:2759 (Eukaryota).
            TR   Mammalia; taxId:40674 (Mammalia).
            KW   Hydroxylation.
            DR   PSI-MOD; MOD:00035.
            DR   Unimod; 35.
            //
            ID   Unsupported element
            AC   PTM-TEST2
            FT   MOD_RES
            TG   Asparagine.
            CF   Qq1
            //
            ID   Cross-link
            AC   PTM-TEST3
            FT   CROSSLNK
            TG   Asparagine-Glycine.
            CF   H-3 N-1
            //
            """

        let library = UniProtPTMReferenceLibraryLoader.parse(
            text,
            elements: ElementReferenceDefaults.bundled,
            aminoAcids: AminoAcidReferenceDefaults.bundled
        )
        let modification = library.modification(accession: "PTM-TEST1")
        let metadata = modification.flatMap(library.metadata)

        #expect(library.version == "test_release")
        #expect(library.modifications.count == 1)
        #expect(modification?.monoisotopicMass.rounded(scale: 6) == decimal("15.994915"))
        #expect(metadata?.taxonomicRanges.count == 2)
        #expect(metadata?.crossReferences.count == 2)
        #expect(metadata?.keywords == ["Hydroxylation"])
    }

    @Test func psiModParserRejectsUnsupportedTerms() {
        let text = """
            format-version: 1.2
            data-version: test

            [Term]
            id: MOD:10001
            name: accepted modification
            xref: DiffFormula: "H 2 O 1"
            xref: Origin: "S"
            xref: Source: "natural"
            xref: TermSpec: "none"

            [Term]
            id: MOD:10002
            name: obsolete modification
            is_obsolete: true
            xref: DiffFormula: "H 1"
            xref: Origin: "S"

            [Term]
            id: MOD:10003
            name: missing formula
            xref: Origin: "S"

            [Term]
            id: MOD:10004
            name: abstract modification
            xref: DiffFormula: "none"
            xref: Origin: "S"

            [Term]
            id: MOD:10005
            name: cross-link
            xref: DiffFormula: "H -2"
            xref: Origin: "C, C"

            [Term]
            id: MOD:10006
            name: ontology origin
            xref: DiffFormula: "H 1"
            xref: Origin: "MOD:00047"

            [Term]
            id: MOD:10007
            name: isotope label
            xref: DiffFormula: "(13)C 1 C -1"
            xref: Origin: "K"

            [Term]
            id: MOD:10008
            name: unknown element
            xref: DiffFormula: "Qq 1"
            xref: Origin: "M"
            """

        let result = PSIModReferenceLibraryLoader.parse(
            text,
            elements: ElementReferenceDefaults.bundled
        )

        #expect(result.version == "test")
        #expect(result.modifications.count == 1)
        #expect(result.modifications.first?.accession == "MOD:10001")
    }

    @Test func xmlReferenceLibrariesLoadProperly() throws {
        let unimodLibraries = try UnimodReferenceLibraryLoader.load()

        #expect(!unimodLibraries.aminoAcids.isEmpty)
        #expect(!unimodLibraries.modifications.isEmpty)
    }

    @Test func jsonReferenceLibrariesLoadProperly() throws {
        let jsonLibraries = try JSONReferenceLibraryLoader.loadOtherLibraries()

        #expect(!jsonLibraries.enzymes.isEmpty)
        #expect(!jsonLibraries.hydrophobicityScales.isEmpty)
    }

    @Test func unimodReferenceLibrariesLoadDebug() throws {
        let unimodLibraries = try UnimodReferenceLibraryLoader.load()

        debugPrint("aminoAcids:", unimodLibraries.aminoAcids.count)
        debugPrint("modifications:", unimodLibraries.modifications.count)

        #expect(!unimodLibraries.aminoAcids.isEmpty)
        #expect(!unimodLibraries.modifications.isEmpty)
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

    @Test func proteinFormula() {
        #expect(testProtein.formula.countFor(element: "C") == 2112)
    }  // C2112H3313N539O629S13

    @Test func proteinFormulaMatchesExplicitResidueFormulaSum() throws {
        let chain = try #require(testProtein.chains.first)
        var explicitFormula = zeroFormula

        for residue in chain.residues {
            explicitFormula += residue.formula

            if let modification = residue.modification {
                explicitFormula += modification.formula
            }
        }

        explicitFormula += chain.nTerminal.formula + chain.cTerminal.formula

        #expect(chain.formula == explicitFormula)
    }

    @Test func peptideFormula() {
        let peptide = Peptide(sequence: "DWSSD")
        #expect(peptide.formula.countFor(element: "C") == 25)
        #expect(peptide.formula.countFor(element: "P") == 0)
    }

    @Test func modifiedPeptideFormula() throws {
        for modification in try modifications(
            unimodName: "Phospho", psiModAccession: "MOD:00046",
            uniProtPTMAccession: "PTM-0253") {
            var peptide = Peptide(sequence: "DWSSD")
            peptide.addModification(modification, at: 3)
            #expect(peptide.formula.countFor(element: "P") == 1)
        }
    }

    @Test func waterAverageMass() {  // H2O
        #expect(water.averageMass.rounded(scale: 4) == decimal("18.0153"))
    }

    @Test func ammoniaAverageMass() {  // NH3
        #expect(ammonia.averageMass.rounded(scale: 4) == decimal("17.0305"))
    }

    @Test func methylAverageMass() {  // CH3
        #expect(methyl.averageMass.rounded(scale: 4) == decimal("15.0345"))  // 15.0346
    }

    @Test func formulaAverageMass() {  // C4H5NO3 + C11H10N2O + C3H5NO2 + C3H5NO2 + C4H5NO3 + H2O
        let group = FunctionalGroup(
            name: "", formula: "C4H5NO3" + "C11H10N2O" + "C3H5NO2" + "C3H5NO2" + "C4H5NO3" + "H2O")

        #expect(group.averageMass.rounded(scale: 3) == decimal("608.555"))
    }  // 608.5556

    @Test func completeSequenceMassMatchesExplicitResidueSum() {
        let peptide = Peptide(sequence: "SAMPLER")
        let explicitMasses = peptide.residues.reduce(zeroMass) {
            $0 + $1.masses
        } + peptide.terminalMasses()

        #expect(peptide.calculateMasses() == explicitMasses)
    }

    @Test func modifiedCompleteSequenceMassMatchesExplicitResidueSum() throws {
        for modification in try modifications(
            unimodName: "Phospho", psiModAccession: "MOD:00046",
            uniProtPTMAccession: "PTM-0253") {
            var peptide = Peptide(sequence: "DWSSD")
            peptide.addModification(modification, at: 3)
            let explicitMasses = peptide.residues.reduce(zeroMass) {
                $0 + $1.masses
            } + peptide.terminalMasses()

            #expect(peptide.calculateMasses() == explicitMasses)
        }
    }

    @Test func chainMassesForIndividualResidues() {
        var peptide = Peptide(sequence: "SAMPLER")
        debugPrint(peptide.monoisotopicMass)

        #expect(peptide.monoisotopicMass.rounded(scale: 5) == decimal("802.40072"))
        #expect(
            peptide.masses.moverz(for: 1).monoisotopicMass.rounded(scale: 4) == decimal("803.4080"))

        peptide.setAdducts(type: protonAdduct, count: 2)
        #expect(peptide.monoisotopicMass.rounded(scale: 4) == decimal("402.2076"))

        var sum = water.masses

        for aa in peptide.residues {
            sum += aa.masses
        }
        debugPrint(sum.monoisotopicMass)

        #expect(sum.monoisotopicMass.rounded(scale: 5) == decimal("802.40072"))
        #expect(sum.moverz(for: 2).monoisotopicMass.rounded(scale: 4) == decimal("402.2076"))

        sum = water.masses

        for aa in peptide.residues[1..<7] {
            sum += aa.masses
        }
        debugPrint(sum.monoisotopicMass)

        #expect(sum.monoisotopicMass.rounded(scale: 5) == decimal("715.36870"))
        #expect(sum.moverz(for: 2).monoisotopicMass.rounded(scale: 4) == decimal("358.6916"))

        // https://www.chemcalc.org/peptides?digestion=%5Bobject%20Object%5D&filter=%5Bobject%20Object%5D&fragmentation=a%3Dfalse%26b%3Dfalse%26c%3Dfalse%26i%3Dfalse%26n%3Dfalse%26x%3Dfalse%26y%3Dfalse%26ya%3Dfalse%26yb%3Dfalse%26z%3Dfalse&ionizations=H%2B.%28H%2B%292.%28H%2B%293&protonation=false&sequence=SAMPLER%0A%0A
    }

    @Test mutating func peptideMonoisotopicMass() {
        testPeptide.setAdducts(type: protonAdduct, count: 1)
        #expect(testPeptide.monoisotopicMass.rounded(scale: 4) == decimal("609.2151"))

        testPeptide.setAdducts(type: protonAdduct, count: 2)
        #expect(testPeptide.monoisotopicMass.rounded(scale: 4) == decimal("305.1112"))
    }

    @Test mutating func peptideAverageMass() {
        testPeptide.setAdducts(type: protonAdduct, count: 1)
        #expect(testPeptide.averageMass.rounded(scale: 4) == decimal("609.5731"))  // 609.5630

        testPeptide.setAdducts(type: protonAdduct, count: 2)
        #expect(testPeptide.averageMass.rounded(scale: 4) == decimal("305.2903"))  // 305.2852
    }

    @Test func peptideSerinePhosphorylationMonoisotopicMass() throws {
        for modification in try modifications(
            unimodName: "Phospho", psiModAccession: "MOD:00046",
            uniProtPTMAccession: "PTM-0253") {
            var peptide = testPeptide
            peptide.addModification(modification, at: 3)

            peptide.setAdducts(type: protonAdduct, count: 1)
            #expect(peptide.monoisotopicMass.rounded(scale: 4) == decimal("689.1814"))

            peptide.setAdducts(type: protonAdduct, count: 2)
            #expect(peptide.monoisotopicMass.rounded(scale: 4) == decimal("345.0944"))

            peptide.removeModification(at: 3)
            peptide.setAdducts(type: protonAdduct, count: 1)
            #expect(peptide.monoisotopicMass.rounded(scale: 4) == decimal("609.2151"))
        }
    }

    @Test func peptideReplaceModificationMonoisotopicMass() throws {
        let phosphorylations = try modifications(
            unimodName: "Phospho", psiModAccession: "MOD:00046",
            uniProtPTMAccession: "PTM-0253")
        let oxidations = try modifications(unimodName: "Oxidation", psiModAccession: "MOD:00425")

        for (phosphorylation, oxidation) in zip(phosphorylations, oxidations) {
            var peptide = testPeptide
            peptide.addModification(phosphorylation, at: 3)

            peptide.setAdducts(type: protonAdduct, count: 1)
            #expect(peptide.monoisotopicMass.rounded(scale: 4) == decimal("689.1814"))

            peptide.setAdducts(type: protonAdduct, count: 2)
            #expect(peptide.monoisotopicMass.rounded(scale: 4) == decimal("345.0944"))

            peptide.addModification(oxidation, at: 3)
            #expect(peptide.modification(at: 3) == oxidation)
            peptide.setAdducts(type: protonAdduct, count: 1)
            #expect(peptide.monoisotopicMass.rounded(scale: 4) == decimal("625.2100"))
        }
    }

    @Test mutating func proteinMonoisotopicMass() {
        testProtein.setAdducts(type: protonAdduct, count: 1)
        #expect(
            testProtein.monoisotopicMass.rounded(scale: 1)
                == decimal("46708.0267").rounded(scale: 1))
    }

    @Test mutating func proteinNTermMetLossMonoisotopicMass() {
        if let metLoss = testProtein.nTermModifications().first(where: {
            $0.name == "Met-loss"
        }),
            let nTermLocation = testProtein.nTermLocation()
        {
            testProtein.setAdducts(type: protonAdduct, count: 1)

            testProtein.addModification(mod: metLoss, at: nTermLocation)
            #expect(
                testProtein.monoisotopicMass.rounded(scale: 1)
                    == (decimal("46708.0267") - decimal("131.040485)")).rounded(scale: 1))

            testProtein.removeModification(at: nTermLocation)
            #expect(
                testProtein.monoisotopicMass.rounded(scale: 1)
                    == decimal("46708.0267").rounded(scale: 1))
        }
    }

    @Test mutating func proteinCTermLysLossMonoisotopicMass() {
        if let lysLoss = testProtein.cTermModifications().first(where: {
            $0.name == "Lys-loss"
        }),
            let cTermLocation = testProtein.cTermLocation()
        {
            testProtein.setAdducts(type: protonAdduct, count: 1)

            testProtein.addModification(mod: lysLoss, at: cTermLocation)
            #expect(testProtein.chains[0].residues.last?.modification == lysLoss)
            #expect(
                testProtein.monoisotopicMass.formatted(fractionDigits: 1)
                    == (decimal("46708.0267") - decimal("128.094963)")).formatted(fractionDigits: 1))

            testProtein.removeModification(at: cTermLocation)
            #expect(
                testProtein.monoisotopicMass.formatted(fractionDigits: 4)
                    == decimal("46708.0267").formatted(fractionDigits: 4))
        }
    }

    @Test mutating func proteinAverageMass() {
        testProtein.setAdducts(type: protonAdduct, count: 1)
        #expect(
            testProtein.averageMass.formatted(fractionDigits: 1) == decimal("46737.9568").formatted(fractionDigits: 1))
    }  // 46737.0703

    @Test func proteinSerinePhosphorylationMonoisotopicMass() throws {
        for modification in try modifications(
            unimodName: "Phospho", psiModAccession: "MOD:00046",
            uniProtPTMAccession: "PTM-0253") {
            var protein = testProtein
            protein.addModification(mod: modification, at: 3)
            protein.setAdducts(type: protonAdduct, count: 1)
            #expect(
                protein.monoisotopicMass.formatted(fractionDigits: 1)
                    == decimal("46787.9931").formatted(fractionDigits: 1))  // 46787.9930

            protein.setAdducts(type: protonAdduct, count: 2)
            #expect(
                protein.monoisotopicMass.formatted(fractionDigits: 1)
                    == decimal("23394.5002").formatted(fractionDigits: 1))
        }
    }

    @Test func unimodModificationFullName() {
        let unimodModifications = ReferenceLibraryDefaults.bundled.unimodLibrary.modifications

        if let pnTAG = unimodModifications.first(where: { $0.name == "PnTAG" }) {
            #expect(pnTAG.fullName == "6-Phosphonohexanoylation")
        }

        if let TMTpro = unimodModifications.first(where: { $0.name == "Label:13C(6)15N(2)+TMTpro" }) {
            #expect(TMTpro.fullName == "TMTpro Tandem Mass Tag 13C(6) 15N(2) Silac label")
        }
    }

    @Test func modifyResidues() throws {
        for modification in try modifications(unimodName: "Carbamidomethyl", psiModAccession: "MOD:01060") {
            var protein = testProtein
            protein.modifyResidues(for: "C", with: modification)

            #expect(protein.countOneResidue(with: "C") == 3)
        }
    }

    @Test func addFormulas() {
        let formula1 = Formula("C12H23O7N5")
        let formula2 = Formula("C2H2O2")
        let formula3 = formula1 + formula2

        debugPrint(formula3.string)

        #expect(formula3.countFor(element: "C") == 14)
        #expect(formula3.countFor(element: "N") == 5)
    }

    @Test func subtractFormulas() {
        let formula1 = Formula("C12H23O7N5")
        let formula2 = Formula("C2H2O2")
        let formula3 = formula1 - formula2

        debugPrint(formula3.string)

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

    @Test func proteinAminoAcidAndTermLocationsAreOptional() {
        #expect(testProtein.aminoAcid(at: 0)?.identifier == "M")
        #expect(testProtein.aminoAcid(at: -1) == nil)
        #expect(testProtein.aminoAcid(at: 0, for: 10) == nil)
        #expect(testProtein.nTermLocation() == 0)
        #expect(testProtein.nTermLocation(for: 10) == nil)
        #expect(Protein(sequence: "").nTermLocation() == nil)
        #expect(testProtein.cTermLocation() == 417)
        #expect(testProtein.cTermLocation(for: 10) == nil)
        #expect(Protein(sequence: "").cTermLocation() == nil)
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
        if let gly = aminoAcidLibrary.first(where: {
            $0.identifier == "G"
        }),
            let pro = aminoAcidLibrary.first(where: {
                $0.identifier == "P"
            })
        {
            testPeptide.insertResidues([gly, pro, pro], at: 2)
        }

        #expect(testPeptide.sequenceString == "DWGPPSSD")
    }

    @Test func parseFasta() async throws {
        let fastaRecords = try await FastaParser().parseBundleFile("ecoli")
        #expect(fastaRecords.count == 4392)

        let record = try #require(fastaRecords.first(where: { $0.accession == "P02919" }))
        #expect(record.shortName == "PBPB_ECOLI")
        #expect(record.fullName == "Penicillin-binding protein 1B")
        #expect(record.organism == "Escherichia coli (strain K12)")
        #expect(
            record.sequence
                == "MAGNDREPIGRKGKPTRPVKQKVSRRRYEDDDDYDDYDDYEDEEPMPRKGKGKGKGRKPRGKRGWLWLLLKLAIVFAVLIAIYGVYLDQKIRSRIDGKVWQLPAAVYGRMVNLEPDMTISKNEMVKLLEATQYRQVSKMTRPGEFTVQANSIEMIRRPFDFPDSKEGQVRARLTFDGDHLATIVNMENNRQFGFFRLDPRLITMISSPNGEQRLFVPRSGFPDLLVDTLLATEDRHFYEHDGISLYSIGRAVLANLTAGRTVQGASTLTQQLVKNLFLSSERSYWRKANEAYMALIMDARYSKDRILELYMNEVYLGQSGDNEIRGFPLASLYYFGRPVEELSLDQQALLVGMVKGASIYNPWRNPKLALERRNLVLRLLQQQQIIDQELYDMLSARPLGVQPRGGVISPQPAFMQLVRQELQAKLGDKVKDLSGVKIFTTFDSVAQDAAEKAAVEGIPALKKQRKLSDLETAIVVVDRFSGEVRAMVGGSEPQFAGYNRAMQARRSIGSLAKPATYLTALSQPKIYRLNTWIADAPIALRQPNGQVWSPQNDDRRYSESGRVMLVDALTRSMNVPTVNLGMALGLPAVTETWIKLGVPKDQLHPVPAMLLGALNLTPIEVAQAFQTIASGGNRAPLSALRSVIAEDGKVLYQSFPQAERAVPAQAAYLTLWTMQQVVQRGTGRQLGAKYPNLHLAGKTGTTNNNVDTWFAGIDGSTVTITWVGRDNNQPTKLYGASGAMSIYQRYLANQTPTPLNLVPPEDIADMGVDYDGNFVCSGGMRILPVWTSDPQSLCQQSEMQQQPSGNPFDQSSQPQQQPQQQPAQQEQKDSDGVAGWIKDMFGSN"
        )
    }

    @Test func subChain() {
        if let chain = testProtein.chains.first {
            let range1: Range<Int> = 2..<9
            let subChain1 = chain.subChain(range: range1)
            #expect(subChain1.sequenceString == "SSVSWGI")

            let range2: Range<Int> = 0..<10
            let subChain2 = chain.removing(range2)
            #expect(
                subChain2.sequenceString
                    == "LLAGLCCLVPVSLAEDPQGDAAQKTDTSHHDQDHPTFNKITPNLAEFAFSLYRQLAHQSNSTNIFFSPIVSIATAFAMLSLGTKADTHDEILEGLNFNLTEIPEAQIHEGFQELLRTLNQPDSQLQLTTGNGLFLSEGLKLVDKFLEDVKKLYHSEAFTVNFGDTEEAKKQINDYVEKGTQGKIVDLVKELDRDTVFALVNYIFFKGKWERPFEVKDTEEEDFHVDQVTTVKVPMMKRLGMFNIQHCKKLSSWVLLMKYLGNATAIFFLPDEGKLQHLENELTHDIITKFLENEDRRSASLHLPKLSITGTYDLKSVLGQLGITKVFSNGADLSGVTEEAPLKLSKAVHKAVLTIDEKGTEAAGAMFLEAIPMSIPPEVKFNKPFVFMIEQNTKSPLFMGKVVNPTQK"
            )

            let range3: Range<Int> = (10..<400)
            let subChain3 = chain.removing(range3)
            #expect(subChain3.sequenceString == "MPSSVSWGILQNTKSPLFMGKVVNPTQK")
        }
    }

    @Test func subSequence() {
        if let chain = testProtein.chains.first {
            #expect(chain.subSequence(range: 0..<1) == "M")
            #expect(chain.subSequence(range: 2..<9) == "SSVSWGI")
            #expect(chain.subSequence(range: -1..<2) == "")
            #expect(chain.subSequence(range: 0..<500) == "")
        }
    }

    @Test func subChainWithModification() throws {
        let carboxymethylModifications = try modifications(
            unimodName: "Carboxymethyl",
            psiModAccession: "MOD:01061"
        )

        #expect(carboxymethylModifications.first?.fullName == "Iodoacetic acid derivative")

        for cysMod in carboxymethylModifications {
            var peptide = Peptide(sequence: "SAMPLEVCAAAGQTHR")
            peptide.setAdducts(type: protonAdduct, count: 1)
            #expect(peptide.monoisotopicMass.rounded(scale: 4) == decimal("1641.7836"))

            peptide.addModification(cysMod, at: 8)
            #expect(peptide.monoisotopicMass.rounded(scale: 4) == decimal("1699.7891"))

            let range = (2..<12)
            var subChain = peptide.subChain(range: range)
            subChain.adducts = peptide.adducts
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

    @Test func selectionMassRangeMatchesSubChain() throws {
        let chain = try #require(testProtein.chains.first)
        let range = 10..<200

        #expect(testProtein.selectionMass(range) == chain.subChain(range: range).pseudomolecularIon())
    }

    @Test mutating func chargedSelectionMassRangeMatchesSubChain() throws {
        let chain = try #require(testProtein.chains.first)
        let range = 10..<200
        testProtein.setAdducts(type: protonAdduct, count: 2)
        var subChain = chain.subChain(range: range)
        subChain.setAdducts(type: protonAdduct, count: testProtein.charge)

        #expect(testProtein.selectionMass(range) == subChain.pseudomolecularIon())
    }

    @Test func isoelectricPointRangeMatchesSubChain() throws {
        let chain = try #require(testProtein.chains.first)
        let range = 10..<200

        #expect(testProtein.isoelectricPoint(range: range) == chain.subChain(range: range).isoelectricPoint())
    }

    @Test func isoelectricPointInvalidRangeReturnsZero() {
        #expect(testProtein.isoelectricPoint(range: -1..<2) == 0.0)
        #expect(Peptide(sequence: "").isoelectricPoint() == 0.0)
    }

    @Test func digest() {
        let digester = ProteinDigester(protein: testProtein)

        let missedCleavages = 0

        let trypsin = enzymeLibrary.first(where: {
            $0.name == "Trypsin"
        })

        if let enzyme = trypsin {
            let peptides: [Peptide] = digester.peptides(using: enzyme, with: missedCleavages)

            #expect(peptides[0].sequenceString == "MPSSVSWGILLLAGLCCLVPVSLAEDPQGDAAQK")
            #expect(peptides[1].sequenceString == "TDTSHHDQDHPTFNK")
            #expect(peptides.map(\.sequenceString).contains("WERPFEVK"))
            #expect(!peptides.map(\.sequenceString).contains("WER"))
        }

        let lysC = enzymeLibrary.first(where: {
            $0.name == "Lys-C"
        })

        if let enzyme = lysC {
            let peptides: [Peptide] = digester.peptides(using: enzyme, with: missedCleavages)

            #expect(peptides[0].sequenceString == "MPSSVSWGILLLAGLCCLVPVSLAEDPQGDAAQK")
            #expect(peptides[1].sequenceString == "TDTSHHDQDHPTFNK")
            #expect(peptides.map(\.sequenceString).contains("FNKPFVFMIEQNTK"))
            #expect(!peptides.map(\.sequenceString).contains("FNK"))
        }

        let aspN = enzymeLibrary.first(where: {
            $0.name == "Asp-N"
        })

        if let enzyme = aspN {
            let peptides: [Peptide] = digester.peptides(using: enzyme, with: missedCleavages)

            #expect(peptides[0].sequenceString == "MPSSVSWGILLLAGLCCLVPVSLAE")
            #expect(peptides[1].sequenceString == "DPQG")
        }

        let pepsin1 = enzymeLibrary.first(where: {
            $0.name == "Pepsin (pH = 1.3)"
        })

        if let enzyme = pepsin1 {
            let peptides: [Peptide] = digester.peptides(using: enzyme, with: missedCleavages)

            #expect(peptides[0].sequenceString == "MPSSVSWGIL")
            #expect(peptides[1].sequenceString == "L")
            #expect(peptides[2].sequenceString == "L")
            #expect(!peptides.map(\.sequenceString).contains("AEDPQGDAAQKTDTSHHDQDHPTF"))
            #expect(peptides.map(\.sequenceString).contains("NKITPNL"))
            #expect(peptides.map(\.sequenceString).contains("MGKVVNPTQK"))
        }

        let pepsin2 = enzymeLibrary.first(where: {
            $0.name == "Pepsin (pH > 2)"
        })

        if let enzyme = pepsin2 {
            let peptides: [Peptide] = digester.peptides(using: enzyme, with: missedCleavages)

            #expect(peptides[0].sequenceString == "MPSSVS")
            #expect(peptides[1].sequenceString == "W")
            #expect(peptides[2].sequenceString == "GI")
            #expect(peptides.map(\.sequenceString).contains("AEDPQGDAAQKTDTSHHDQDHPTF"))
            #expect(peptides.map(\.sequenceString).contains("NKITPNL"))
            #expect(peptides.map(\.sequenceString).contains("MGKVVNPTQK"))
        }
    }

    @Test func digestUnspecified() {
        let unspecified = enzymeLibrary.first(where: {
            $0.name == "Unspecified"
        })
        #expect(unspecified?.name == "Unspecified")
    }

    @Test func digestMasses() {
        let digester = ProteinDigester(protein: testProtein)

        let missedCleavages = 1

        let trypsin = enzymeLibrary.first(where: {
            $0.name == "Trypsin"
        })

        if let enzyme = trypsin {
            let peptides: [Peptide] = digester.peptides(using: enzyme, with: missedCleavages)
                .charge(with: 1...1)
            #expect(peptides[0].monoisotopicMass.rounded(scale: 4) == decimal("3468.7575"))  // 3467.7503
            #expect(peptides[2].monoisotopicMass.rounded(scale: 4) == decimal("1779.7681"))  // 1778.7608
        }
    }

    @Test func lowMassSearch() {
        if let chain = testProtein.chains.first {
            let searchParameters = MassSearchParameters(
                searchValue: 1, tolerance: MassTolerance(type: .ppm, value: 10),
                searchType: .sequential, massType: .monoisotopic, charge: 0)

            let ranges: [Range<Int>] = chain.searchMass(params: searchParameters)

            #expect(ranges.isEmpty)
        }
    }

    @Test func moverzSearch() {
        if let chain = testProtein.chains.first {
            let searchParameters = MassSearchParameters(
                searchValue: 890.3877, tolerance: MassTolerance(type: .ppm, value: 10),
                searchType: .sequential, massType: .monoisotopic, charge: 2)

            let ranges = measure("Sliding Window") {
                let ranges: [Range<Int>] = chain.searchMass(params: searchParameters)
                return ranges
            }

            debugPrint(ranges)
            let sequenceStrings = ranges.map {
                chain.sequenceString[$0]
            }

            #expect(sequenceStrings.contains(where: {
                $0 == "TDTSHHDQDHPTFNK"
            }))
            #expect(!sequenceStrings.contains(where: {
                $0 == "NIFFS"
            }))
        }
    }

    @Test func moverzLongSearch() {
        let longTest = Protein(
            sequence: """

                MIPARFAGVLLALALILPGTLCAEGTRGRSSTARCSLFGSDFVNTFDGSMYSFAGYCSYLLAGGCQKRSFSIIGDFQNGKRVSLSVYLGEFFDIHLFVNGTVTQGDQRVSMPYASKGLYLETEAGYYKLSGEAYGFVARIDGSGNFQVLLSDRYFNKTCGLCGNFNIFAEDDFMTQEGTLTSDPYDFANSWALSSGEQWCERASPPSSSCNISSGEMQKGLWEQCQLLKSTSVFARCHPLVDPEPFVALCEKTLCECAGGLECACPALLEYARTCAQEGMVLYGWTDHSACSPVCPAGMEYRQCVSPCARTCQSLHINEMCQERCVDGCSCPEGQLLDEGLCVESTECPCVHSGKRYPPGTSLSRDCNTCICRNSQWICSNEECPGECLVTGQSHFKSFDNRYFTFSGICQYLLARDCQDHSFSIVIETVQCADDRDAVCTRSVTVRLPGLHNSLVKLKHGAGVAMDGQDVQLPLLKGDLRIQHTVTASVRLSYGEDLQMDWDGRGRLLVKLSPVYAGKTCGLCGNYNGNQGDDFLTPSGLAEPRVEDFGNAWKLHGDCQDLQKQHSDPCALNPRMTRFSEEACAVLTSPTFEACHRAVSPLPYLRNCRYDVCSCSDGRECLCGALASYAAACAGRGVRVAWREPGRCELNCPKGQVYLQCGTPCNLTCRSLSYPDEECNEACLEGCFCPPGLYMDERGDCVPKAQCPCYYDGEIFQPEDIFSDHHTMCYCEDGFMHCTMSGVPGSLLPDAVLSSPLSHRSKRSLSCRPPMVKLVCPADNLRAEGLECTKTCQNYDLECMSMGCVSGCLCPPGMVRHENRCVALERCPCFHQGKEYAPGETVKIGCNTCVCQDRKWNCTDHVCDATCSTIGMAHYLTFDGLKYLFPGECQYVLVQDYCGSNPGTFRILVGNKGCSHPSVKCKKRVTILVEGGEIELFDGEVNVKRPMKDETHFEVVESGRYIILLLGKALSVVWDRHLSISVVLKQTYQEKVCGLCGNFDGIQNNDLTSSNLQVEEDPVDFGNSWKVSSQCADTRKVPLDSSPATCHNNIMKQTMVDSSCRILTSDVFQDCNKLVDPEPYLDVCIYDTCSCESIGDCACFCDTIAAYAHVCAQHGKVVTWRTATLCPQSCEERNLRENGYECEWRYNSCAPACQVTCQHPEPLACPVQCVEGCHAHCPPGKILDELLQTCVDPEDCPVCEVAGRRFASGKKVTLNPSDPEHCQICHCDVVNLTCEACQEPGGLVVPPTDAPVSPTTLYVEDISEPPLHDFYCSRLLDLVFLLDGSSRLSEAEFEVLKAFVVDMMERLRISQKWVRVAVVEYHDGSHAYIGLKDRKRPSELRRIASQVKYAGSQVASTSEVLKYTLFQIFSKIDRPEASRITLLLMASQEPQRMSRNFVRYVQGLKKKKVIVIPVGIGPHANLKQIRLIEKQAPENKAFVLSSVDELEQQRDEIVSYLCDLAPEAPPPTLPPDMAQVTVGPGLLGVSTLGPKRNSMVLDVAFVLEGSDKIGEADFNRSKEFMEEVIQRMDVGQDSIHVTVLQYSYMVTVEYPFSEAQSKGDILQRVREIRYQGGNRTNTGLALRYLSDHSFLVSQGDREQAPNLVYMVTGNPASDEIKRLPGDIQVVPIGVGPNANVQELERIGWPNAPILIQDFETLPREAPDLVLQRCCSGEGLQIPTLSPAPDCSQPLDVILLLDGSSSFPASYFDEMKSFAKAFISKANIGPRLTQVSVLQYGSITTIDVPWNVVPEKAHLLSLVDVMQREGGPSQIGDALGFAVRYLTSEMHGARPGASKAVVILVTDVSVDSVDAAADAARSNRVTVFPIGIGDRYDAAQLRILAGPAGDSNVVKLQRIEDLPTMVTLGNSFLHKLCSGFVRICMDEDGNEKRPGDVWTLPDQCHTVTCQPDGQTLLKSHRVNCDRGLRPSCPNSQSPVKVEETCGCRWTCPCVCTGSSTRHIVTFDGQNFKLTGSCSYVLFQNKEQDLEVILHNGACSPGARQGCMKSIEVKHSALSVELHSDMEVTVNGRLVSVPYVGGNMEVNVYGAIMHEVRFNHLGHIFTFTPQNNEFQLQLSPKTFASKTYGLCGICDENGANDFMLRDGTVTTDWKTLVQEWTVQRPGQTCQPILEEQCLVPDSSHCQVLLLPLFAECHKVLAPATFYAICQQDSCHQEQVCEVIASYAHLCRTNGVCVDWRTPDFCAMSCPPSLVYNHCEHGCPRHCDGNVSSCGDHPSEGCFCPPDKVMLEGSCVPEEACTQCIGEDGVQHQFLEAWVPDHQPCQICTCLSGRKVNCTTQPCPTAKAPTCGLCEVARLRQNADQCCPEYECVCDPVSCDLPPVPHCERGLQPTLTNPGECRPNFTCACRKEECKRVSPPSCPPHRLPTLRKTQCCDEYECACNCVNSTVSCPLGYLASTATNDCGCTTTTCLPDKVCVHRSTIYPVGQFWEEGCDVCTCTDMEDAVMGLRVAQCSQKPCEDSCRSGFTYVLHEGECCGRCLPSACEVVTGSPRGDSQSSWKSVGSQWASPENPCLINECVRVKEEVFIQQRNVSCPQLEVPVCPSGFQLSCKTSACCPSCRCERMEACMLNGTVIGPGKTVMIDVCTTCRCMVQVGVISGFKLECRKTTCNPCPLGYKEENNTGECCGRCLPTACTIQLRGGQIMTLKRDETLQDGCDTHFCKVNERGEYFWEKRVTGCPPFDEHKCLAEGGKIMKIPGTCCDTCEEPECNDITARLQYVKVGSCKSEVEVDIHYCQGKCASKAMYSIDINDVQDQCSCCSPTRTEPMQVALHCTNGSVVYHEVLNAMECKCSPRKCSK
                """)

        if let chain = longTest.chains.first {
            let searchParameters = MassSearchParameters(
                searchValue: 10355.6744, tolerance: MassTolerance(type: .ppm, value: 10),
                searchType: .sequential, massType: .monoisotopic, charge: 1)

            let ranges = measure("Sliding Window") {
                let ranges: [Range<Int>] = chain.searchMass(params: searchParameters)
                return ranges
            }

            debugPrint(ranges)
            let sequenceStrings = ranges.map {
                chain.sequenceString[$0]
            }

            #expect(
                sequenceStrings.contains(where: {
                    $0
                        == "LKKKKVIVIPVGIGPHANLKQIRLIEKQAPENKAFVLSSVDELEQQRDEIVSYLCDLAPEAPPPTLPPDMAQVTVGPGLLGVSTLGPKRNSMVLDV"
                }))
            #expect(!sequenceStrings.contains(where: {
                $0 == "NIFFS"
            }))
        }
    }

    @Test func massSearchWithModification() throws {
        for modification in try modifications(
            unimodName: "Phospho", psiModAccession: "MOD:00046",
            uniProtPTMAccession: "PTM-0253") {
            var chain = try #require(testProtein.chains.first)
            chain.addModification(modification, at: 76)

            let searchParameters = MassSearchParameters(
                searchValue: 689.28, tolerance: MassTolerance(type: .ppm, value: 10),
                searchType: .sequential, massType: .monoisotopic, charge: 0)

            let ranges: [Range<Int>] = chain.searchMass(params: searchParameters)
            let sequenceStrings = ranges.map {
                chain.sequenceString[$0]
            }

            #expect(sequenceStrings.contains(where: {
                $0 == "IFFSP"
            }))
        }
    }

    @Test func averageMassSearch() {
        if let chain = testProtein.chains.first {
            let searchParameters = MassSearchParameters(
                searchValue: 609.71, tolerance: MassTolerance(type: .ppm, value: 10),
                searchType: .sequential, massType: .average, charge: 0)

            let ranges: [Range<Int>] = chain.searchMass(params: searchParameters)
            let sequenceStrings = ranges.map {
                chain.sequenceString[$0]
            }

            #expect(sequenceStrings.contains(where: {
                $0 == "IFFSP"
            }))
            #expect(!sequenceStrings.contains(where: {
                $0 == "NIFFS"
            }))
        }
    }

    @Test func moverzSearchBruteForce() {
        if let chain = testProtein.chains.first {
            let searchParameters = MassSearchParameters(
                searchValue: 890.3877, tolerance: MassTolerance(type: .ppm, value: 10),
                searchType: .sequential, massType: .monoisotopic, charge: 2)

            let peptides: [Peptide] = chain.searchMassBruteForce(params: searchParameters)

            #expect(peptides.contains(where: {
                $0.sequenceString == "TDTSHHDQDHPTFNK"
            }))
            #expect(!peptides.contains(where: {
                $0.sequenceString == "NIFFS"
            }))
        }
    }

    @Test func compareSearchImplementations() {
        if let chain = testProtein.chains.first {
            let searchParameters = MassSearchParameters(
                searchValue: 890.3877, tolerance: MassTolerance(type: .ppm, value: 10),
                searchType: .sequential, massType: .monoisotopic, charge: 2)

            let result1 = measure("Original Brute Force method") {
                let peptides: [Peptide] = chain.searchMassBruteForce(params: searchParameters)
                return peptides.map(\.range)
            }

            let result2 = measure("Sliding Window") {
                let ranges: [Range<Int>] = chain.searchMass(params: searchParameters)
                return ranges
            }

            debugPrint(result1)
            debugPrint(result2)

            #expect(result1 == result2)
        }
    }

    @Test func checkMassDifferences() {
        let peptide = Peptide(sequence: "SAMPLER")
        let first = peptide.subChain(range: 0..<1)
        let truncated = peptide.subChain(range: 1..<7)

        #expect(first.sequenceString == "S")
        #expect(truncated.sequenceString == "AMPLER")

        let peptideMass = peptide.monoisotopicMass
        let truncatedMass = truncated.monoisotopicMass
        let firstMass = first.monoisotopicMass

        #expect(truncatedMass == peptideMass - firstMass + water.monoisotopicMass)
    }

    @Test func fragmentCount() {
        var peptide = Peptide(sequence: "SAMPLER")
        peptide.setAdducts(type: protonAdduct, count: 1)

        let fragmenter = PeptideFragmenter(peptide: peptide)
        let fragments = fragmenter.fragments

        let precursors = fragments.filter {
            $0.fragmentType == .precursorIon
        }
        #expect(precursors.count == 1)

        let immoniumIons = fragments.filter {
            $0.fragmentType == .immoniumIon
        }
        #expect(immoniumIons.count == 7)

        let bIons = fragments.filter {
            $0.fragmentType == .bIon
        }
        #expect(bIons.count == 5)

        let yIons = fragments.filter {
            $0.fragmentType == .yIon
        }
        #expect(yIons.count == 6)
    }

    @Test func fragmenterHandlesShortPeptides() {
        var emptyPeptide = Peptide(sequence: "")
        emptyPeptide.setAdducts(type: protonAdduct, count: 1)

        let emptyFragmenter = PeptideFragmenter(peptide: emptyPeptide)
        #expect(emptyFragmenter.fragments.filter {
            $0.isNterminal() || $0.isCterminal()
        }.isEmpty)
        #expect(emptyFragmenter.fragment(at: 1, for: .cIon) == nil)

        var singleResiduePeptide = Peptide(sequence: "A")
        singleResiduePeptide.setAdducts(type: protonAdduct, count: 1)

        let singleResidueFragmenter = PeptideFragmenter(peptide: singleResiduePeptide)
        #expect(singleResidueFragmenter.fragments.filter {
            $0.isCterminal()
        }.isEmpty)
        #expect(singleResidueFragmenter.fragment(at: 1, for: .cIon) != nil)
    }

    @Test func fragmentMass1() {
        // theoretical masses via https://prospector.ucsf.edu/prospector/cgi-bin/msform.cgi?form=msproduct

        var peptide = Peptide(sequence: "SAMPLER")
        peptide.setAdducts(type: protonAdduct, count: 1)

        #expect(peptide.monoisotopicMass.rounded(scale: 4) == decimal("803.4080"))
        #expect(peptide.monoisotopicMass.rounded(scale: 4) == decimal("803.4080"))

        let fragmenter = PeptideFragmenter(peptide: peptide)
        let fragments = fragmenter.fragments

        let precursors = fragments.filter {
            $0.isPrecursor()
        }
        #expect(precursors[0].monoisotopicMass.rounded(scale: 4) == decimal("803.4080"))
        #expect(precursors[1].monoisotopicMass.rounded(scale: 4) == decimal("785.3974"))
        #expect(precursors[2].monoisotopicMass.rounded(scale: 4) == decimal("786.3815"))

        if let a1 = fragmenter.fragment(at: 1, for: .aIon) {
            #expect(a1.monoisotopicMass.rounded(scale: 4) == decimal("131.0815"))  // a1
        }

        if let b2 = fragmenter.fragment(at: 2, for: .bIon) {
            #expect(b2.monoisotopicMass.rounded(scale: 4) == decimal("159.0764"))  // b2
        }

        if let b2minH2O = fragmenter.fragment(at: 2, for: .bIonMinusWater) {
            #expect(b2minH2O.monoisotopicMass.rounded(scale: 4) == decimal("141.0659"))  // b2-H2O
        }

        if let b3minH2O = fragmenter.fragment(at: 3, for: .bIonMinusWater) {
            #expect(b3minH2O.monoisotopicMass.rounded(scale: 4) == decimal("272.1063"))  // b3-H2O
        }

        if let x1 = fragmenter.fragment(at: 1, for: .xIon) {
            #expect(x1.monoisotopicMass.rounded(scale: 4) == decimal("201.0982"))  // x1
        }

        if let y1 = fragmenter.fragment(at: 1, for: .yIon) {
            #expect(y1.monoisotopicMass.rounded(scale: 4) == decimal("175.1190"))  // y1
        }

        if let y1minNH3 = fragmenter.fragment(at: 1, for: .yIonMinusAmmonia) {
            #expect(y1minNH3.monoisotopicMass.rounded(scale: 4) == decimal("158.0924"))  // y1-NH3
        }

        if let y2minH2O = fragmenter.fragment(at: 2, for: .yIonMinusWater) {
            #expect(y2minH2O.monoisotopicMass.rounded(scale: 4) == decimal("286.1510"))  // y2-H2O
        }
    }

    @Test func fragmentMass2() {
        var peptide = Peptide(sequence: "SAMPLEVAAAGQTHR")
        peptide.setAdducts(type: protonAdduct, count: 1)

        #expect(peptide.monoisotopicMass.rounded(scale: 4) == decimal("1538.7744"))

        let fragmenter = PeptideFragmenter(peptide: peptide)
        let fragments = fragmenter.fragments

        let bIons = fragments.filter {
            $0.fragmentType == .bIon
        }
        #expect(bIons.count == 13)

        if let b2 = fragmenter.fragment(at: 2, for: .bIon) {
            #expect(b2.monoisotopicMass.rounded(scale: 4) == decimal("159.0764"))  // b2
        }

        if let b12 = fragmenter.fragment(at: 12, for: .bIon) {
            #expect(b12.monoisotopicMass.rounded(scale: 4) == decimal("1126.5561"))  // b12
        }

        if let b12minH2O = fragmenter.fragment(at: 12, for: .bIonMinusWater) {
            #expect(b12minH2O.monoisotopicMass.rounded(scale: 4) == decimal("1108.5456"))  // b12 - H2O
        }

        if let b12minNH3 = fragmenter.fragment(at: 12, for: .bIonMinusAmmonia) {
            #expect(b12minNH3.monoisotopicMass.rounded(scale: 4) == decimal("1109.5296"))  // b12 - NH3
        }

        let zIons = fragments.filter {
            $0.fragmentType == .zIon
        }
        #expect(zIons.count == 13)

        let cIons = fragments.filter {
            $0.fragmentType == .cIon
        }
        #expect(cIons.count == 13)

        if let c1 = fragmenter.fragment(at: 1, for: .cIon) {
            #expect(c1.monoisotopicMass.rounded(scale: 4) == decimal("105.0659"))  // c1
        }
    }

    @Test func fragmentMass3() throws {
        for modification in try modifications(
            unimodName: "Oxidation", psiModAccession: "MOD:00719",
            uniProtPTMAccession: "PTM-0469") {
            var peptide = Peptide(sequence: "SAMPLEVAMAAGQTHR")
            peptide.setAdducts(type: protonAdduct, count: 1)
            peptide.addModification(modification, at: 8)
            #expect(peptide.monoisotopicMass.rounded(scale: 4) == decimal("1685.8098"))

            let fragmenter = PeptideFragmenter(peptide: peptide)
            let fragments = fragmenter.fragments

            let aIonsMinusWater = fragments.filter {
                $0.fragmentType == .aIonMinusWater
            }
            #expect(aIonsMinusWater.count == 14)

            let aIonsMinusAmmonia = fragments.filter {
                $0.fragmentType == .aIonMinusAmmonia
            }
            #expect(aIonsMinusAmmonia.count == 3)

            let bIons = fragments.filter {
                $0.fragmentType == .bIon
            }
            #expect(!bIons.contains(where: {
                $0.index == 1
            }))

            let yIons = fragments.filter {
                $0.fragmentType == .yIonMinusWater
            }
            #expect(!yIons.contains(where: {
                $0.index == 1
            }))
            #expect(!yIons.contains(where: {
                $0.index == 2
            }))

            if let b8 = fragmenter.fragment(at: 8, for: .bIon) {
                #expect(b8.monoisotopicMass.rounded(scale: 4) == decimal("799.4019"))  // b8 M-ox
            }

            if let y9 = fragmenter.fragment(at: 9, for: .yIon) {
                #expect(y9.monoisotopicMass.rounded(scale: 4) == decimal("958.4523"))  // y9 M-ox
            }

            if let x9 = fragmenter.fragment(at: 9, for: .xIon) {
                #expect(x9.monoisotopicMass.rounded(scale: 4) == decimal("984.4316"))  // x9 M-ox
            }

            let zIons = fragments.filter {
                $0.fragmentType == .zIon
            }
            #expect(!zIons.contains(where: {
                $0.index == 13
            }))

            if let z12 = fragmenter.fragment(at: 12, for: .zIon) {
                #expect(z12.monoisotopicMass.rounded(scale: 4) == decimal("1283.6287"))  // z12 M-ox
            }
        }
    }

    @Test func fragmentMass4() {
        var peptide = Peptide(sequence: "AWRKQNWSTEDWWSTEDWQPRTYSAMPLER")
        peptide.setAdducts(type: protonAdduct, count: 1)

        let fragmenter = PeptideFragmenter(peptide: peptide)
        let fragments = fragmenter.fragments

        let bIonsMinusWater = fragments.filter {
            $0.fragmentType == .bIonMinusWater
        }
        #expect(!bIonsMinusWater.contains(where: {
            $0.index == 1
        }))
        #expect(!bIonsMinusWater.contains(where: {
            $0.index == 2
        }))
        #expect(!bIonsMinusWater.contains(where: {
            $0.index == 3
        }))
        #expect(!bIonsMinusWater.contains(where: {
            $0.index == 4
        }))
        #expect(!bIonsMinusWater.contains(where: {
            $0.index == 5
        }))
        #expect(!bIonsMinusWater.contains(where: {
            $0.index == 6
        }))
        #expect(!bIonsMinusWater.contains(where: {
            $0.index == 7
        }))
        #expect(bIonsMinusWater.contains(where: {
            $0.index == 8
        }))

        if let b8MinusWater = fragmenter.fragment(at: 8, for: .bIonMinusWater) {
            #expect(b8MinusWater.monoisotopicMass.rounded(scale: 4) == decimal("1039.5221"))  // b8-H20
        }
    }

    @Test func fragmentMass5() {
        var peptide = Peptide(sequence: "SAMPLEVAAAGQTHR")
        peptide.setAdducts(type: protonAdduct, count: 2)

        #expect(peptide.monoisotopicMass.rounded(scale: 4) == decimal("769.8908"))

        let fragmenter = PeptideFragmenter(peptide: peptide)
        let fragments = fragmenter.fragments

        let bIons = fragments.filter {
            $0.fragmentType == .bIon
        }
        #expect(bIons.count == 14)

        if let b2 = fragmenter.fragment(at: 2, for: .bIon) {
            #expect(b2.monoisotopicMass.rounded(scale: 4) == decimal("159.0764"))  // b2
        }

        if let b12 = fragmenter.fragment(at: 12, for: .bIon) {
            #expect(b12.monoisotopicMass.rounded(scale: 4) == decimal("1126.5561"))  // b12
        }

        let bIonsMinusWater = fragments.filter {
            $0.fragmentType == .bIonMinusWater
        }
        #expect(bIonsMinusWater.count == 14)

        if let b12MinusWater = fragmenter.fragment(at: 12, for: .bIonMinusWater) {
            #expect(b12MinusWater.monoisotopicMass.rounded(scale: 4) == decimal("1108.5456"))  // b12 - H2O
        }

        if let b12MinusAmmonia = fragmenter.fragment(at: 12, for: .bIonMinusAmmonia) {
            #expect(b12MinusAmmonia.monoisotopicMass.rounded(scale: 4) == decimal("1109.5296"))  // b12 - NH3
        }

        let zIons = fragments.filter {
            $0.fragmentType == .zIon
        }
        #expect(zIons.count == 26)

        let cIons = fragments.filter {
            $0.fragmentType == .cIon
        }
        #expect(cIons.count == 14)

        if let c1 = fragmenter.fragment(at: 1, for: .cIon) {
            #expect(c1.monoisotopicMass.rounded(scale: 4) == decimal("105.0659"))  // c1
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

        #expect(protein.aminoAcids(for: 0).map {
            $0.oneLetterCode
        } == ["A", "A", "S", "A", "S"])
        #expect(
            protein.aminoAcids(for: 1).map {
                $0.oneLetterCode
            } == [
                "A", "A", "S", "A", "S", "S", "S", "A",
            ])

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

    @Test func crossLinkWithinOneChainContributesItsModificationOnce() throws {
        var protein = Protein(sequence: "ACDC")
        let unlinkedFormula = protein.formula
        let unlinkedMasses = protein.neutralMasses()

        let crossLink = try protein.addCrossLink(
            modification: disulfideBond,
            between: 1,
            and: 3)

        #expect(protein.crossLinks == [crossLink])
        #expect(protein.formula.countFor(element: "H") == unlinkedFormula.countFor(element: "H") - 2)
        #expect(protein.neutralMasses() == unlinkedMasses + disulfideBond.masses)
    }

    @Test func crossLinkCanConnectDifferentProteinChainsAndRoundTripThroughCodable() throws {
        var protein = Protein(chains: [Peptide(sequence: "AC"), Peptide(sequence: "CA")])

        let crossLink = try protein.addCrossLink(
            modification: disulfideBond,
            between: 1,
            inChain: 0,
            and: 0,
            inChain: 1)

        #expect(crossLink.firstSite.chainID == protein.chains[0].id)
        #expect(crossLink.secondSite.chainID == protein.chains[1].id)
        #expect(protein.crossLinks(at: crossLink.firstSite) == [crossLink])

        let encoded = try JSONEncoder().encode(protein)
        let decoded = try JSONDecoder().decode(Protein.self, from: encoded)
        #expect(decoded == protein)
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

        let sequence = text.substring(between: "BEGIN SEQUENCE", and: "END SEQUENCE")?
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

        let peptides = text.substrings(between: "BEGIN PEPTIDE", and: "END PEPTIDE").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        #expect(peptides == ["PEPTIDEK", "MKWVTF"])
    }

    @Test func findsSingleLetterRanges() {
        let sequence = "AAAA"

        #expect(sequence.sequenceRanges(of: "A") == [0..<1, 1..<2, 2..<3, 3..<4])
    }

    @Test func findsNonOverlappingSequenceRanges() {
        let sequence = "AAAA"

        #expect(sequence.sequenceRanges(of: "AA") == [0..<2, 2..<4])
    }

    @Test func findsOverlappingSequenceRanges() {
        let sequence = "AAAA"

        #expect(sequence.sequenceRanges(of: "AA", allowingOverlaps: true) == [0..<2, 1..<3, 2..<4])
    }

    @Test("Finds all non-overlapping matching ranges") func stringMatchingRanges() {
        let text = "ABC DEF ABC"

        let result = text.ranges(matching: "ABC")

        #expect(result == [0..<3, 8..<11])
    }

    @Test("Empty search string returns no ranges") func emptySearchStringReturnsNoRanges() {
        let text = "ABC DEF ABC"

        #expect(text.ranges(matching: "").isEmpty)
    }

    @Test("Missing search string returns no ranges") func missingSearchStringReturnsNoRanges() {
        let text = "ABC DEF ABC"

        #expect(text.ranges(matching: "XYZ").isEmpty)
    }

    @Test("Single-character matches return one-length ranges") func singleCharacterMatchingRanges() {
        let text = "ABACA"

        let result = text.ranges(matching: "A")

        #expect(result == [0..<1, 2..<3, 4..<5])
    }

    @Test func convertsSequenceCoordinatesToOneBasedRanges() {
        let sequence = "MKWVTFISLL"

        #expect(sequence.sequenceRanges(of: "VTF") == [3..<6])
    }

    @Test func emptySubstringProducesNoRanges() {
        let sequence = "PEPTIDE"

        #expect(sequence.sequenceRanges(of: "").isEmpty)
    }

    @Test func identifiesAnyProhibitedCharacter() {
        let allowedCharacters = CharacterSet(charactersIn: "ACDEFGHIKLMNPQRSTVWY")

        #expect(!"PEPTIDE".containsCharacterOutside(allowedCharacters))
        #expect("PEPT1DE".containsCharacterOutside(allowedCharacters))
    }

    @Test func malformedXMLThrowsParseError() throws {
        let malformedXML = """
            <root>
                <item>Broken</root>
            """

        let data = Data(malformedXML.utf8)

        #expect(throws: Error.self) {
            try UnimodXMLParser().parse(data: data)
        }
    }

    @Test func malformedXMLThrowsParseError2() throws {
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

    @Test func malformedXMLThrowsXMLParserError() throws {
        let malformedXML = Data("<root><broken></root>".utf8)

        let parser = UnimodXMLParser()

        let error = try #require(
            #expect(throws: Error.self) {
                try parser.parse(data: malformedXML)
            })

        let nsError = error as NSError

        #expect(nsError.domain == XMLParser.errorDomain)
        #expect(!nsError.localizedDescription.isEmpty)

        #if DEBUG
            debugPrint("Received expected XML parse error:", nsError.localizedDescription)
        #endif
    }

    @Test func malformedXMLThrowsXMLParserError2() throws {
        let malformedXML = Data("<root><broken></root>".utf8)

        let parser = UnimodXMLParser()

        let error = #expect(throws: Error.self) {
            try parser.parse(data: malformedXML)
        }

        let nsError = try #require(error as NSError?)

        #expect(nsError.domain == XMLParser.errorDomain)
        #expect(!nsError.localizedDescription.isEmpty)
    }

    @Test("Convert BiologicalRange to zero-based Range") func biologicalRangeToRange() {
        let biologicalRange = BiologicalRange(1...4)

        let result = biologicalRange.zeroBasedRange

        #expect(result == 0..<4)
    }

    @Test("Convert zero-based Range to BiologicalRange") func rangeToBiologicalRange() {
        let range: Range<Int> = 0..<4

        let result = range.biologicalRange

        #expect(result == BiologicalRange(1...4))
    }

    @Test("Round-trip Range through BiologicalRange") func rangeBiologicalRangeRoundTrip() {
        let original: Range<Int> = 25..<33

        let biologicalRange = original.biologicalRange
        let convertedBack = biologicalRange?.zeroBasedRange

        #expect(biologicalRange == BiologicalRange(26...33))
        #expect(convertedBack == original)
    }

    @Test("Empty Range cannot convert to BiologicalRange") func emptyRangeToBiologicalRange() {
        let emptyRange: Range<Int> = 0..<0

        #expect(emptyRange.biologicalRange == nil)
    }

    @Test("BiologicalRange rejects a zero-based ClosedRange") func invalidBiologicalRange() {
        let result = BiologicalRange(validating: 0...4)

        #expect(result == nil)
    }

    @Test func propertySetContainsExpectedValues() {
        let properties: Set<AminoAcidProperty> = [.polar, .aromatic]

        #expect(properties.contains(.polar))
        #expect(properties.contains(.aromatic))
        #expect(!properties.contains(.nonpolar))
        #expect(properties.count == 2)
    }

    @Test func duplicatePropertiesAreIgnored() {
        let properties: Set<AminoAcidProperty> = [.polar, .polar, .aromatic]

        #expect(properties == [.polar, .aromatic])
        #expect(properties.count == 2)
    }

    @Test func twoWordHasCorrectDisplayName() {
        let property = AminoAcidProperty.chargedPositive

        #expect(property.displayName == "Charged Positive")
    }
}
