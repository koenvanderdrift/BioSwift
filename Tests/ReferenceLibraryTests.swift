//
//  ReferenceLibraryTests.swift
//  BioSwift
//

import Foundation
import Testing

@testable import BioSwift

@Suite struct ReferenceLibraryTests: BioSwiftTestSuite {
    var fixtures = BioSwiftTestFixtures()
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

    @Test func bundledUniProtPTMLibraryResolvesAspartateAndGlutamateAliases() throws {
        let library = ReferenceLibraryDefaults.bundled.uniProtPTMLibrary
        let aspartateModification = try #require(
            library.modification(accession: "PTM-0371"))
        let glutamateModification = try #require(
            library.modification(accession: "PTM-0039"))

        #expect(aspartateModification.specificities.first?.site == "D")
        #expect(glutamateModification.specificities.first?.site == "E")
        #expect(library.modifications(applicableTo: "D").contains(aspartateModification))
        #expect(library.modifications(applicableTo: "E").contains(glutamateModification))
    }

    @Test func bundledUniProtPTMLibraryIncludesLipidAndCarbohydrateFeatures() throws {
        let library = ReferenceLibraryDefaults.bundled.uniProtPTMLibrary
        let lipidModification = try #require(
            library.modification(accession: "PTM-0776"))
        let carbohydrateModification = try #require(
            library.modification(accession: "PTM-0540"))

        #expect(lipidModification.name == "Cholesterol aspartate ester")
        #expect(lipidModification.specificities.first?.site == "D")
        #expect(carbohydrateModification.name == "N-linked (Hex) asparagine")
        #expect(carbohydrateModification.specificities.first?.site == "N")
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
            ID   Hydroxyaspartate
            AC   PTM-TEST-D
            FT   MOD_RES
            TG   Aspartate.
            PP   Anywhere.
            CF   O1
            //
            ID   Hydroxyglutamate
            AC   PTM-TEST-E
            FT   MOD_RES
            TG   Glutamate.
            PP   Anywhere.
            CF   O1
            //
            ID   Lipidated aspartate
            AC   PTM-TEST-LIPID
            FT   LIPID
            TG   Aspartate.
            PP   Anywhere.
            CF   C2 H2
            //
            ID   Glycosylated asparagine
            AC   PTM-TEST-CARBOHYD
            FT   CARBOHYD
            TG   Asparagine.
            PP   Anywhere.
            CF   C6 H10 O5
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
        #expect(library.modifications.count == 5)
        #expect(modification?.monoisotopicMass.rounded(scale: 6) == decimal("15.994915"))
        #expect(library.modification(accession: "PTM-TEST-D")?.specificities.first?.site == "D")
        #expect(library.modification(accession: "PTM-TEST-E")?.specificities.first?.site == "E")
        #expect(library.modification(accession: "PTM-TEST-LIPID")?.specificities.first?.site == "D")
        #expect(library.modification(accession: "PTM-TEST-CARBOHYD")?.specificities.first?.site == "N")
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

}
