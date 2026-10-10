import Testing

import BioSwift

@Suite("Free cysteine modification")
struct FreeCysteineModificationTests {
    private let derivatization = Modification(
        name: "Test cysteine derivatization",
        reactions: [.add(.functionalGroup(hydrogen))]
    )

    @Test("Modifies only unmodified, unlinked cysteines")
    func modifiesOnlyFreeCysteines() throws {
        var protein = try Protein(sequence: "CACCC")
        try protein.addModification(hydrogenModification, at: 2)
        try protein.addCrossLink(
            modification: disulfideBond,
            between: 3,
            and: 4
        )

        protein.modifyFreeCysteines(with: derivatization)

        #expect(protein.aminoAcid(at: 0)?.modification == derivatization)
        #expect(protein.aminoAcid(at: 1)?.modification == nil)
        #expect(protein.aminoAcid(at: 2)?.modification == hydrogenModification)
        #expect(protein.aminoAcid(at: 3)?.modification == nil)
        #expect(protein.aminoAcid(at: 4)?.modification == nil)
    }

    @Test("Recognizes free cysteines across multiple chains")
    func multipleChains() throws {
        var protein = Protein(chains: [
            try ProteinChain(sequence: "CC", name: "alpha"),
            try ProteinChain(sequence: "CAC", name: "beta"),
        ])
        try protein.addCrossLink(
            modification: disulfideBond,
            between: 1,
            inChain: 0,
            and: 0,
            inChain: 1
        )

        protein.modifyFreeCysteines(with: derivatization)

        #expect(protein.aminoAcid(at: 0, chainIndex: 0)?.modification == derivatization)
        #expect(protein.aminoAcid(at: 1, chainIndex: 0)?.modification == nil)
        #expect(protein.aminoAcid(at: 0, chainIndex: 1)?.modification == nil)
        #expect(protein.aminoAcid(at: 1, chainIndex: 1)?.modification == nil)
        #expect(protein.aminoAcid(at: 2, chainIndex: 1)?.modification == derivatization)
    }

    @Test("Copy-returning operation leaves the source unchanged")
    func copySemantics() throws {
        let source = try Protein(sequence: "AC")
        let modified = source.modifyingFreeCysteines(with: derivatization)

        #expect(source.aminoAcid(at: 1)?.modification == nil)
        #expect(modified.aminoAcid(at: 1)?.modification == derivatization)
        #expect(modified.formula == source.formula + derivatization.formula)
    }

    @Test("Protein without cysteine is unchanged")
    func noCysteine() throws {
        var protein = try Protein(sequence: "AGT")
        let original = protein

        protein.modifyFreeCysteines(with: derivatization)

        #expect(protein == original)
    }
}
