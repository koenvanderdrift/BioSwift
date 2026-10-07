import Testing

@testable import BioSwift

@Suite("BioMolecule structural editing")
struct BioMoleculeEditingTests {
    @Test("Range removal deletes and remaps intra-chain cross-links")
    func intraChainRemoval() throws {
        var protein = try Protein(sequence: "ACDEFG")
        let before = try protein.addCrossLink(
            modification: disulfideBond,
            between: 0,
            and: 1
        )
        let touchingRemovedResidue = try protein.addCrossLink(
            modification: disulfideBond,
            between: 2,
            and: 5
        )
        let after = try protein.addCrossLink(
            modification: disulfideBond,
            between: 4,
            and: 5
        )

        let edited = try protein.removingResidues(in: 2..<4)

        #expect(protein.sequence == "ACDEFG")
        #expect(protein.crossLinks.count == 3)
        #expect(edited.sequence == "ACFG")
        #expect(edited.crossLinks.count == 2)
        #expect(edited.crossLinks.contains { link in
            link.id == before.id
                && link.firstSite.residueIndex == 0
                && link.secondSite.residueIndex == 1
        })
        #expect(edited.crossLinks.contains { link in
            link.id == after.id
                && link.firstSite.residueIndex == 2
                && link.secondSite.residueIndex == 3
        })
        #expect(edited.crossLinks.contains { $0.id == touchingRemovedResidue.id } == false)
    }

    @Test("Range removal deletes and remaps inter-chain cross-links")
    func interChainRemoval() throws {
        var protein = Protein(chains: [
            try ProteinChain(sequence: "ACDEFG", name: "alpha"),
            try ProteinChain(sequence: "GHIK", name: "beta"),
        ])
        let removed = try protein.addCrossLink(
            modification: disulfideBond,
            between: 2,
            inChain: 0,
            and: 1,
            inChain: 1
        )
        let retained = try protein.addCrossLink(
            modification: disulfideBond,
            between: 5,
            inChain: 0,
            and: 2,
            inChain: 1
        )
        let alphaID = protein.chains[0].id
        let betaID = protein.chains[1].id

        let edited = try protein.removingResidues(in: 1..<3, chainIndex: 0)

        #expect(edited.sequence(chainIndex: 0) == "AEFG")
        #expect(edited.sequence(chainIndex: 1) == "GHIK")
        #expect(edited.chains[0].id == alphaID)
        #expect(edited.chains[1].id == betaID)
        #expect(edited.crossLinks.count == 1)
        let link = try #require(edited.crossLinks.first)
        #expect(link.id == retained.id)
        #expect(link.firstSite == CrossLinkSite(chainID: alphaID, residueIndex: 3))
        #expect(link.secondSite == CrossLinkSite(chainID: betaID, residueIndex: 2))
        #expect(edited.crossLinks.contains { $0.id == removed.id } == false)
    }

    @Test("Insertion shifts affected cross-link endpoints")
    func insertion() throws {
        var protein = Protein(chains: [
            try ProteinChain(sequence: "ACDE"),
            try ProteinChain(sequence: "GHIK"),
        ])
        let internalLink = try protein.addCrossLink(
            modification: disulfideBond,
            between: 1,
            inChain: 0,
            and: 3,
            inChain: 0
        )
        let interChainLink = try protein.addCrossLink(
            modification: disulfideBond,
            between: 2,
            inChain: 0,
            and: 1,
            inChain: 1
        )
        let glycine = try #require(
            try AminoAcidReferenceDefaults.loadBundled().aminoAcid(identifier: "G")
        )

        let edited = try protein.insertingResidues(
            [glycine, glycine],
            at: 2,
            chainIndex: 0
        )

        let shiftedInternal = try #require(edited.crossLinks.first { $0.id == internalLink.id })
        let shiftedInterChain = try #require(edited.crossLinks.first { $0.id == interChainLink.id })
        #expect(shiftedInternal.firstSite.residueIndex == 1)
        #expect(shiftedInternal.secondSite.residueIndex == 5)
        #expect(shiftedInterChain.firstSite.residueIndex == 4)
        #expect(shiftedInterChain.secondSite.residueIndex == 1)
        #expect(shiftedInternal.id == internalLink.id)
        #expect(shiftedInterChain.id == interChainLink.id)
        #expect(protein.sequence(chainIndex: 0) == "ACDE")
        #expect(edited.sequence(chainIndex: 0) == "ACGGDE")
    }

    @Test("Single removal and replacement use chain-index conveniences")
    func singleRemovalAndReplacement() throws {
        let protein = Protein(chains: [
            try ProteinChain(sequence: "ACDE"),
            try ProteinChain(sequence: "FGHI"),
        ])
        let glycine = try #require(
            try AminoAcidReferenceDefaults.loadBundled().aminoAcid(identifier: "G")
        )

        let removed = try protein.removingResidue(at: 1, chainIndex: 1)
        let replaced = try protein.replacingResidue(
            at: 0,
            with: glycine,
            chainIndex: 0
        )

        #expect(removed.sequence(chainIndex: 0) == "ACDE")
        #expect(removed.sequence(chainIndex: 1) == "FHI")
        #expect(replaced.sequence(chainIndex: 0) == "GCDE")
        #expect(replaced.sequence(chainIndex: 1) == "FGHI")
        #expect(protein.sequence(chainIndex: 0) == "ACDE")
        #expect(protein.sequence(chainIndex: 1) == "FGHI")
    }

    @Test("Conveniences support nucleic-acid molecules")
    func nucleicAcids() throws {
        let dna = try DNA(sequences: ["GATTACA", "CCGG"])
        let adenine = try #require(Nucleotide.standard(code: "A", type: .dna))

        let inserted = try dna.insertingResidue(adenine, at: 2, chainIndex: 1)
        let removed = try dna.removingResidues(in: 1..<3, chainIndex: 0)

        #expect(inserted.sequence(chainIndex: 0) == "GATTACA")
        #expect(inserted.sequence(chainIndex: 1) == "CCAGG")
        #expect(removed.sequence(chainIndex: 0) == "GTACA")
        #expect(removed.sequence(chainIndex: 1) == "CCGG")
    }

    @Test("Invalid chain indices throw")
    func invalidChainIndex() throws {
        let protein = try Protein(sequence: "ACDE")

        #expect(throws: CrossLinkError.invalidChainIndex(1)) {
            try protein.removingResidues(in: 0..<1, chainIndex: 1)
        }
    }
}
