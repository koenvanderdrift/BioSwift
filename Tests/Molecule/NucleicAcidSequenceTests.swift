import Testing
@testable import BioSwift

@Suite("Nucleic acid sequence transformations")
struct NucleicAcidSequenceTests {
    @Test("DNA generates complement, reverse, and reverse complement sequences")
    func dnaTransformations() throws {
        let dna = try DNA(sequence: "ATCG")

        #expect(dna.complement.sequence == "TAGC")
        #expect(dna.reverse.sequence == "GCTA")
        #expect(dna.reverseComplement.sequence == "CGAT")
    }

    @Test("RNA generates complement, reverse, and reverse complement sequences")
    func rnaTransformations() throws {
        let rna = try RNA(sequence: "AUCG")

        #expect(rna.complement.sequence == "UAGC")
        #expect(rna.reverse.sequence == "GCUA")
        #expect(rna.reverseComplement.sequence == "CGAU")
    }

    @Test("Every chain in a molecule is transformed")
    func multipleChains() throws {
        let dna = try DNA(sequences: ["ATCG", "GATTACA"])

        #expect(dna.reverseComplement.sequence(chainIndex: 0) == "CGAT")
        #expect(dna.reverseComplement.sequence(chainIndex: 1) == "TGTAATC")
    }
}
