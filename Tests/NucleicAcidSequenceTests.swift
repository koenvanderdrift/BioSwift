import Testing
@testable import BioSwift

@Suite("Nucleic acid sequence transformations")
struct NucleicAcidSequenceTests {
    @Test("DNA generates complement, reverse, and reverse complement sequences")
    func dnaTransformations() {
        let dna = DNA(sequence: "ATCG")

        #expect(dna.complement.sequence() == "TAGC")
        #expect(dna.reverse.sequence() == "GCTA")
        #expect(dna.reverseComplement.sequence() == "CGAT")
    }

    @Test("RNA generates complement, reverse, and reverse complement sequences")
    func rnaTransformations() {
        let rna = RNA(sequence: "AUCG")

        #expect(rna.complement.sequence() == "UAGC")
        #expect(rna.reverse.sequence() == "GCUA")
        #expect(rna.reverseComplement.sequence() == "CGAU")
    }

    @Test("Every chain in a molecule is transformed")
    func multipleChains() {
        let dna = DNA(sequences: ["ATCG", "GATTACA"])

        #expect(dna.reverseComplement.sequence(for: 0) == "CGAT")
        #expect(dna.reverseComplement.sequence(for: 1) == "TGTAATC")
    }
}
