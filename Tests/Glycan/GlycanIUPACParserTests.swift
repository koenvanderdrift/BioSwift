import Testing

@testable import BioSwift

@Suite struct GlycanIUPACParserTests {
    private let parser = GlycanIUPACParser()

    private static let uniProtPTMLibrary = Result {
        let elements = try ElementReferenceDefaults.loadBundled()
        let unimod = try UnimodReferenceLibraryLoader.load(elements: elements)
        return try UniProtPTMReferenceLibraryLoader.load(
            elements: elements,
            aminoAcids: AminoAcidReferences(aminoAcids: unimod.aminoAcids)
        )
    }

    @Test func parsesUniProtPTM0746ComplexNGlycan() throws {
        let (notation, modification) = try uniProtGlycan(accession: "PTM-0746")
        let glycan = try parser.parse(notation, name: "PTM-0746 glycan")

        #expect(glycan.monosaccharideCount == 8)
        #expect(glycan.nodes.filter { $0.branches.count == 2 }.count == 1)
        #expect(glycan.formula == modification.formula + water.formula)
        #expect(embeddedGlycan(in: modification)?.root == glycan.root)
        #expect(glycan.iupacCondensed == "Gal(b1-4)GlcNAc(b1-2)Man(a1-3)[GlcNAc(b1-2)Man(a1-6)]Man(b1-4)GlcNAc(b1-4)GlcNAc")
    }

    @Test func parsesUniProtPTM0756BisectedSialylatedNGlycan() throws {
        let (notation, modification) = try uniProtGlycan(accession: "PTM-0756")
        let glycan = try parser.parse(notation, name: "PTM-0756 glycan")

        #expect(glycan.monosaccharideCount == 10)
        #expect(glycan.nodes.contains { $0.branches.count == 3 })
        #expect(glycan.composition[.nAcetylneuraminicAcid.form(anomer: .alpha, ring: .pyranose)] == 1)
        #expect(glycan.formula == modification.formula + water.formula)
        #expect(embeddedGlycan(in: modification)?.root == glycan.root)
    }

    @Test func parsesUniProtPTM0760CoreFucosylatedNGlycan() throws {
        let (notation, modification) = try uniProtGlycan(accession: "PTM-0760")
        let glycan = try parser.parse(notation, name: "PTM-0760 glycan")

        #expect(glycan.monosaccharideCount == 8)
        #expect(glycan.composition[.fucose.form(anomer: .alpha, ring: .pyranose)] == 1)
        #expect(glycan.formula == modification.formula + water.formula)
        #expect(embeddedGlycan(in: modification)?.root == glycan.root)
        #expect(glycan.root.branches.count == 2)
    }

    private func embeddedGlycan(in modification: Modification) -> Glycan? {
        for reaction in modification.reactions {
            if case let .add(.glycan(glycan)) = reaction {
                return glycan
            }
        }
        return nil
    }

    private func uniProtGlycan(accession: String) throws -> (String, Modification) {
        let library = try Self.uniProtPTMLibrary.get()
        let modification = try #require(library.modification(accession: accession))
        let open = try #require(modification.name.firstIndex(of: "("))
        var depth = 0
        var close: String.Index?

        for index in modification.name.indices[open...] {
            switch modification.name[index] {
            case "(": depth += 1
            case ")":
                depth -= 1
                if depth == 0 {
                    close = index
                }
            default: break
            }
            if close != nil { break }
        }

        let closeIndex = try #require(close)
        let notationStart = modification.name.index(after: open)
        return (String(modification.name[notationStart..<closeIndex]), modification)
    }
}
