import Testing
import BioSwift

@Suite struct ModificationLibraryTests {
    @Test func lookupsPreserveFirstDefinitionsAndUnaccessionedEntries() {
        let first = Modification(accession: "TEST:1", name: "Shared", reactions: [])
        let sameName = Modification(accession: "TEST:2", name: "Shared", reactions: [])
        let sameAccession = Modification(accession: "TEST:1", name: "Later", reactions: [])
        let custom = Modification(name: "Custom", reactions: [])
        let library = ModificationLibrary(
            vocabulary: .unimod, version: "test",
            modifications: [first, sameName, sameAccession, custom]
        )

        #expect(library.count == 4)
        #expect(library.modification(named: "Shared")?.accession == "TEST:1")
        #expect(library.modification(accession: "TEST:1")?.name == "Shared")
        #expect(library.modification(accession: "TEST:2")?.name == "Shared")
        #expect(library.modification(named: "Custom")?.name == "Custom")
        #expect(library.modification(named: "Missing") == nil)
        #expect(library.modification(accession: "Missing") == nil)
    }

    @Test func searchMatchesNamesSynonymsAndResidueSpecificities() {
        let specific = Modification(
            name: "Acétyl", fullName: "Lysine addition", synonyms: ["Alias"],
            reactions: [], specificities: [ModificationSpecificity(site: "K")]
        )
        let wildcard = Modification(
            name: "Wildcard", synonyms: ["Alias"], reactions: [],
            specificities: [ModificationSpecificity(site: "X")]
        )
        let library = ModificationLibrary(
            vocabulary: .psiMod, version: "test", modifications: [specific, wildcard]
        )

        #expect(library.modifications(matching: "ACETYL") == [specific])
        #expect(library.modifications(matching: "lysine") == [specific])
        #expect(library.modifications(matching: "ALIAS") == [specific, wildcard])
        #expect(library.modifications(matching: "alias", applicableTo: "K") == [specific, wildcard])
        #expect(library.modifications(matching: "alias", applicableTo: "M") == [wildcard])
        #expect(library.modifications(applicableTo: "K") == [specific])
        #expect(library.modifications(applicableTo: "M").isEmpty)
        #expect(library.modifications(matching: "missing").isEmpty)
    }

    @Test func metadataAndTaxonomyUseAccessions() throws {
        let annotated = Modification(accession: "TEST:1", name: "Annotated", reactions: [])
        let missing = Modification(accession: "TEST:2", name: "Missing", reactions: [])
        let custom = Modification(name: "Custom", reactions: [])
        let taxon = TaxonomicRange(name: "Mammalia", taxonIdentifier: 40674)
        let reference = ModificationCrossReference(database: "PSI-MOD", identifier: "MOD:00035")
        let library = ModificationLibrary(
            vocabulary: .uniProtPTM, version: "test",
            modifications: [annotated, missing, custom],
            metadataByAccession: [
                "TEST:1": ModificationMetadata(
                    taxonomicRanges: [taxon], keywords: ["Hydroxylation"],
                    cellularLocations: ["Cytoplasm"], crossReferences: [reference]
                )
            ]
        )

        let metadata = try #require(library.metadata(for: annotated))
        #expect(metadata.taxonomicRanges == [taxon])
        #expect(metadata.keywords == ["Hydroxylation"])
        #expect(metadata.cellularLocations == ["Cytoplasm"])
        #expect(metadata.crossReferences == [reference])
        #expect(library.metadata(for: missing) == nil)
        #expect(library.metadata(for: custom) == nil)
        #expect(library.modifications(taxonIdentifier: 40674) == [annotated])
        #expect(library.modifications(taxonIdentifier: 9606).isEmpty)
    }

    @Test func emptyLibrarySupportsAllQueries() {
        let library = ModificationLibrary(vocabulary: .unimod, version: "", modifications: [])

        #expect(library.modification(named: "Missing") == nil)
        #expect(library.modification(accession: "Missing") == nil)
        #expect(library.modifications(matching: "").isEmpty)
        #expect(library.modifications(applicableTo: "K").isEmpty)
        #expect(library.modifications(taxonIdentifier: 9606).isEmpty)
    }
}

