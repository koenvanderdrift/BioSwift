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
        let elements = try ReferenceLibrary.elements
        let aminoAcids = try ReferenceLibrary.aminoAcids
        let enzymes = try ReferenceLibrary.enzymes
        let scales = try ReferenceLibrary.hydrophobicityScales

        #expect(elements.element(symbol: "C")?.symbol == "C")
        #expect(aminoAcids.count == 20)
        #expect(aminoAcids.filterSequence("ac def") == "ACDEF")
        #expect(!enzymes.isEmpty)
        #expect(!scales.isEmpty)
        #expect(try ReferenceLibrary.unimod.vocabulary == .unimod)
        #expect(try ReferenceLibrary.psiMod.modification(accession: "MOD:00007") != nil)
        #expect(try !ReferenceLibrary.uniProtPTM.isEmpty)
    }

    @Test func bundledResultsExposeLoadingFailures() throws {
        let elements = try ReferenceLibraryDefaults.bundledResult.get().elements
        let libraries = try ReferenceLibraryDefaults.bundledResult.get()

        #expect(!elements.isEmpty)
        #expect(!libraries.elements.isEmpty)
    }

    @Test func bundledCollectionsProvideLookupsThroughOneEntryPoint() throws {
        let libraries = try ReferenceLibraryDefaults.loadBundled()

        #expect(libraries.elementReferences.element(symbol: "C")?.symbol == "C")
        #expect(libraries.aminoAcidReferences.aminoAcid(identifier: "G")?.oneLetterCode == "G")
        let enzyme = try #require(libraries.enzymes.first)
        #expect(libraries.enzymeReferences.enzyme(named: enzyme.name)?.name == enzyme.name)
        let scale = try #require(libraries.hydrophobicityScales.first)
        #expect(libraries.hydrophobicityReferences.hydrophobicityScale(named: scale.name)?.name == scale.name)
        #expect(libraries.elementReferences.count == libraries.elements.count)
        #expect(libraries.aminoAcidReferences.count == libraries.aminoAcids.count)
        #expect(libraries.enzymeReferences.count == libraries.enzymes.count)
        #expect(libraries.hydrophobicityReferences.count == libraries.hydrophobicityScales.count)
    }

    @Test func bundledDefaultsAreAvailable() throws {
        let libraries = try ReferenceLibraryDefaults.loadBundled()

        #expect(!libraries.elements.isEmpty)
        #expect(!libraries.unimodLibrary.isEmpty)
        #expect(!libraries.aminoAcids.isEmpty)
        #expect(!libraries.enzymes.isEmpty)
        #expect(!libraries.hydrophobicityScales.isEmpty)
    }

    @Test func bundledHydrophobicityReferencesProvideNumericValues() throws {
        let pKaValues = try ReferenceLibraryDefaults.loadBundled().hydrophobicityReferences.numericHydrophobicityValues(named: "pKa")

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
        let text = try loadText(from: "uniprot-ptm-list", withExtension: "txt", in: .module)

        #expect(text.contains("Release:     2026_03"))
    }

    @Test func psiModReferenceLibraryLoadsSeparatelyFromUnimod() throws {
        let libraries = try ReferenceLibraryDefaults.loadBundled()

        #expect(libraries.psiModLibrary.version == "1.038.0")
        #expect(!libraries.psiModLibrary.isEmpty)
        #expect(libraries.psiModLibrary.allSatisfy { $0.accession != nil })
        #expect(libraries.psiModLibrary.modification(accession: "MOD:00007") != nil)
    }

    @Test func modificationLibrariesHaveAnExchangeableAPI() throws {
        let libraries = try ReferenceLibraryDefaults.loadBundled()

        func validate(_ library: ModificationLibrary, vocabulary: ModificationVocabulary) throws {
            #expect(library.vocabulary == vocabulary)
            #expect(!library.isEmpty)
            #expect(!library.modifications(applicableTo: "M").isEmpty)

            let modification = try #require(library.first)
            let accession = try #require(modification.accession)
            #expect(library.modification(accession: accession)?.name == modification.name)
            #expect(library.modification(named: modification.name)?.name == modification.name)
            #expect(library.modifications(matching: modification.name).contains(modification))
        }

        try validate(libraries.unimodLibrary, vocabulary: .unimod)
        try validate(libraries.psiModLibrary, vocabulary: .psiMod)
        try validate(libraries.uniProtPTMLibrary, vocabulary: .uniProtPTM)
        #expect(libraries.unimodLibrary.modification(accession: "UNIMOD:1") != nil)
    }

    @Test func uniProtPTMLibraryLoadsMetadata() throws {
        let library = try ReferenceLibraryDefaults.loadBundled().uniProtPTMLibrary
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
        let library = try ReferenceLibraryDefaults.loadBundled().uniProtPTMLibrary
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
        let library = try ReferenceLibraryDefaults.loadBundled().uniProtPTMLibrary
        let lipidModification = try #require(
            library.modification(accession: "PTM-0776"))
        let carbohydrateModification = try #require(
            library.modification(accession: "PTM-0540"))

        #expect(lipidModification.name == "Cholesterol aspartate ester")
        #expect(lipidModification.specificities.first?.site == "D")
        #expect(carbohydrateModification.name == "N-linked (Hex) asparagine")
        #expect(carbohydrateModification.specificities.first?.site == "N")
    }

    @Test(arguments: ["\n", "\r\n", "\r"])
    func uniProtPTMParserReadsRecordsAfterHeader(lineEnding: String) throws {
        let text = """
            Release:     test_release
              ID         Identifier (FT description)
              AC         Accession (PTM-xxxx)
              FT         Feature key
              TG         Target
              //         Terminator

            ID   First modification
            AC   PTM-FIRST
            FT   MOD_RES
            TG   Asparagine.
            CF   O1
            //
            ID   Second modification
            AC   PTM-SECOND
            FT   MOD_RES
            TG   Serine.
            CF   H2
            //
            AC   PTM-OUTSIDE
            ID   Unfinished modification
            AC   PTM-UNFINISHED
            FT   MOD_RES
            TG   Serine.
            CF   O1
            """
            .replacingOccurrences(of: "\n", with: lineEnding)
        let references = try ReferenceLibraryDefaults.loadBundled()
        let library = try UniProtPTMReferenceLibraryLoader.parse(
            text, elements: references.elementReferences,
            aminoAcids: references.aminoAcidReferences
        )

        #expect(library.version == "test_release")
        #expect(library.map(\.accession) == ["PTM-FIRST", "PTM-SECOND"])
        #expect(library.modification(accession: "PTM-FIRST")?.name == "First modification")
        #expect(library.modification(accession: "PTM-SECOND")?.name == "Second modification")
    }

    @Test func uniProtPTMParserPreservesRepeatedFieldsRejectsUnsupportedRecordsAndIgnoresProvidedMasses() throws {
        let text = """
            Release:     test_release of 01-Jan-2026

            ID   Hydroxyasparagine
            AC   PTM-TEST1
            FT   MOD_RES
            TG   Asparagine.
            PA   Side chain.
            PA   Additional source constraint.
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

        let library = try UniProtPTMReferenceLibraryLoader.parse(
            text,
            elements: try ReferenceLibraryDefaults.loadBundled().elementReferences,
            aminoAcids: try ReferenceLibraryDefaults.loadBundled().aminoAcidReferences
        )
        let modification = library.modification(accession: "PTM-TEST1")
        let metadata = modification.flatMap(library.metadata)

        #expect(library.version == "test_release")
        #expect(library.count == 6)
        #expect(library.modification(accession: "PTM-TEST2") != nil)
        #expect(library.modification(accession: "PTM-TEST3") == nil)
        #expect(modification?.monoisotopicMass.rounded(scale: 6) == decimal("15.994915"))
        #expect(library.modification(accession: "PTM-TEST-D")?.specificities.first?.site == "D")
        #expect(library.modification(accession: "PTM-TEST-E")?.specificities.first?.site == "E")
        #expect(library.modification(accession: "PTM-TEST-LIPID")?.specificities.first?.site == "D")
        #expect(library.modification(accession: "PTM-TEST-CARBOHYD")?.specificities.first?.site == "N")
        #expect(metadata?.taxonomicRanges.count == 2)
        #expect(metadata?.crossReferences.count == 2)
        #expect(metadata?.keywords == ["Hydroxylation"])
        let specificity = try #require(modification?.specificities.first)
        #expect(specificity.attachmentPositions == ["Side chain.", "Additional source constraint."])
        let decoded = try JSONDecoder().decode(
            ModificationSpecificity.self, from: JSONEncoder().encode(specificity)
        )
        #expect(decoded.attachmentPositions == specificity.attachmentPositions)
        #expect(decoded.site == specificity.site)
        #expect(decoded.position == specificity.position)
        #expect(decoded.classification == specificity.classification)
        #expect(library.modification(accession: "PTM-TEST-D")?.specificities.first?.attachmentPositions == [])
        #expect(AminoAcidModificationValidator.validate(
            try #require(modification), in: .init(residue: "N")
        ) != .allowed)
    }

    @Test(arguments: ["", "CF   ", "CF   Qq1", "CF   O", "CF   H0"])
    func uniProtPTMRetainsRecordsWithoutUsableCorrectionFormulas(formulaLine: String) throws {
        let text = """
            ID   Unknown chemistry
            AC   PTM-UNKNOWN
            FT   MOD_RES
            TG   Lysine.
            PP   N-terminal.
            PA   Amino acid backbone.
            KW   Test classification.
            TR   Mammalia; taxId:40674 (Mammalia).
            DR   PSI-MOD; MOD:00035.
            \(formulaLine)
            //
            ID   Cross-link with single target
            AC   PTM-CROSSLINK
            FT   CROSSLNK
            TG   Lysine.
            \(formulaLine)
            //
            """
        let references = try ReferenceLibraryDefaults.loadBundled()
        let library = try UniProtPTMReferenceLibraryLoader.parse(
            text, elements: references.elementReferences,
            aminoAcids: references.aminoAcidReferences
        )
        #expect(library.count == 1)
        #expect(library.modification(accession: "PTM-CROSSLINK") == nil)
        let modification = try #require(library.modification(accession: "PTM-UNKNOWN"))
        #expect(modification.accession == "PTM-UNKNOWN")
        #expect(modification.name == "Unknown chemistry")
        #expect(modification.reactions.count == 1)
        if case .undefined = modification.reactions.first {
        } else {
            Issue.record("Expected an undefined reaction")
        }
        let specificity = try #require(modification.specificities.first)
        #expect(modification.specificities.count == 1)
        #expect(specificity.site == "K")
        #expect(specificity.position == "N-term")
        #expect(specificity.classification == "Test classification")
        #expect(specificity.attachmentPositions == ["Amino acid backbone."])
        let metadata = try #require(library.metadata(for: modification))
        #expect(metadata.keywords == ["Test classification"])
        #expect(metadata.taxonomicRanges.first?.taxonIdentifier == 40674)
        #expect(metadata.crossReferences.first?.identifier == "MOD:00035")
    }

    @Test func psiModPreservesTerminalRestrictions() throws {
        let cases: [(String?, String)] = [
            ("N-term", "Any N-term"), ("C-term", "Any C-term"),
            ("none", "Anywhere"), ("Unrecognized restriction", "Unrecognized restriction"),
            (nil, "Unknown")
        ]
        for (source, expected) in cases {
            var text = """
                [Term]
                id: MOD:10001
                name: Test modification
                xref: DiffFormula: "O 1"
                xref: Origin: "K"
                """
            if let source {
                text += "\nxref: TermSpec: \"\(source)\""
            }
            let library = try PSIModReferenceLibraryLoader.parse(
                text, elements: ReferenceLibrary.elements
            )
            let modification = try #require(library.first)
            #expect(modification.specificities.first?.position == expected)
            let result = AminoAcidModificationValidator.validate(modification, in: .init(residue: "K"))
            if source == "none" {
                #expect(result == .allowed)
            } else {
                #expect(result != .allowed)
            }
        }
    }

    @Test func psiModParserRejectsUnsupportedTerms() throws {
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

        let result = try PSIModReferenceLibraryLoader.parse(
            text,
            elements: try ReferenceLibraryDefaults.loadBundled().elementReferences
        )

        #expect(result.version == "test")
        #expect(result.map(\.accession) == [
            "MOD:10001", "MOD:10003", "MOD:10004", "MOD:10007", "MOD:10008"
        ])
        for modification in result.dropFirst() {
            #expect(modification.reactions.count == 1)
            guard case .undefined = modification.reactions.first else {
                Issue.record("Expected an undefined reaction")
                continue
            }
        }
    }

    @Test(arguments: ["", "none", " ", "Qq 1", "O", "H nope", "H 0", "O 1 Qq 1"])
    func psiModRetainsUnknownChemistryAndMetadata(formula: String) throws {
        let text = """
            [Term]
            id: MOD:20001
            name: Full modification name
            synonym: "Preferred name" EXACT PSI-MOD-label []
            synonym: "Alternative name" EXACT []
            xref: DiffFormula: "\(formula)"
            xref: Origin: "K"
            xref: TermSpec: "N-term"
            xref: Source: "natural"

            [Term]
            id: MOD:20002
            name: Cross-link
            xref: Origin: "C, C"

            [Term]
            id: MOD:20003
            name: Obsolete
            is_obsolete: true
            xref: Origin: "K"

            [Term]
            id: MOD:20004
            name: Unknown origin
            xref: Origin: "MOD:00047"
            """
        let library = try PSIModReferenceLibraryLoader.parse(
            text, elements: ReferenceLibrary.elements
        )
        #expect(library.count == 1)
        let modification = try #require(library.first)
        #expect(modification.accession == "MOD:20001")
        #expect(modification.name == "Preferred name")
        #expect(modification.fullName == "Full modification name")
        #expect(modification.synonyms.contains("Alternative name"))
        #expect(modification.reactions.count == 1)
        guard case .undefined = modification.reactions.first else {
            Issue.record("Expected an undefined reaction")
            return
        }
        let specificity = try #require(modification.specificities.first)
        #expect(specificity.site == "K")
        #expect(specificity.position == "Any N-term")
        #expect(specificity.classification == "natural")
    }

    @Test(arguments: [
        "",
        "<umod:delta/>",
        "<umod:delta><umod:element symbol=\"H\" number=\"0\"/></umod:delta>",
        "<umod:delta><umod:element symbol=\"Qq\" number=\"1\"/></umod:delta>",
        "<umod:delta><umod:element symbol=\"O\" number=\"1\"/><umod:element symbol=\"H\" number=\"bad\"/></umod:delta>",
        "<umod:delta><umod:element symbol=\"H\"/></umod:delta>",
        "<umod:delta><umod:element number=\"1\"/></umod:delta>"
    ])
    func unimodRetainsUnknownChemistryAndResetsRecordState(composition: String) throws {
        let xml = """
            <umod:unimod xmlns:umod="http://www.unimod.org/xmlns/schema/unimod_2">
                <umod:modifications>
                    <umod:mod title="Test modification" full_name="Full modification name" record_id="20001">
                        <umod:specificity site="K" position="Any N-term" classification="Post-translational"/>
                        \(composition)
                    </umod:mod>
                    <umod:mod title="Valid modification" record_id="20002">
                        <umod:specificity site="M" position="Anywhere" classification="Post-translational"/>
                        <umod:delta><umod:element symbol="O" number="1"/></umod:delta>
                        <umod:NeutralLoss><umod:element symbol="H" number="bad"/></umod:NeutralLoss>
                    </umod:mod>
                    <umod:mod title="Xlink:test" record_id="20003">
                        \(composition)
                    </umod:mod>
                </umod:modifications>
            </umod:unimod>
            """
        let result = try UnimodReferenceLibraryLoader.parse(data: Data(xml.utf8))
        #expect(result.modifications.count == 2)
        let modification = try #require(result.modifications.first)
        #expect(modification.accession == "UNIMOD:20001")
        #expect(modification.name == "Test modification")
        #expect(modification.fullName == "Full modification name")
        #expect(modification.reactions.count == 1)
        guard case .undefined = modification.reactions.first else {
            Issue.record("Expected an undefined reaction")
            return
        }
        let specificity = try #require(modification.specificities.first)
        #expect(specificity.site == "K")
        #expect(specificity.position == "Any N-term")
        #expect(specificity.classification == "Post-translational")
        #expect(result.modifications.last?.accession == "UNIMOD:20002")
        #expect(result.modifications.last?.monoisotopicMass.rounded(scale: 6) == decimal("15.994915"))
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

        BioSwiftDiagnostics.log("aminoAcids: \(unimodLibraries.aminoAcids.count)")
        BioSwiftDiagnostics.log("modifications: \(unimodLibraries.modifications.count)")

        #expect(!unimodLibraries.aminoAcids.isEmpty)
        #expect(!unimodLibraries.modifications.isEmpty)
    }

}
