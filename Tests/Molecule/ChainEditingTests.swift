import Foundation
import Testing

@testable import BioSwift

@Suite("Chain structural editing")
struct ChainEditingTests {
    @Test("Non-mutating removal supports leading, middle, and trailing ranges")
    func removalPositions() throws {
        let chain = ProteinChain(sequence: "ACDEFGH", name: "alpha")

        #expect(try chain.removingResidues(in: 0..<2).sequenceString == "DEFGH")
        #expect(try chain.removingResidues(in: 2..<5).sequenceString == "ACGH")
        #expect(try chain.removingResidues(in: 5..<7).sequenceString == "ACDEF")
        #expect(chain.sequenceString == "ACDEFGH")
    }

    @Test("Empty removal is an exact no-op")
    func emptyRemoval() throws {
        let id = UUID()
        var chain = ProteinChain(sequence: "ACDE", name: "alpha", id: id)
        chain.range = 4..<8
        chain.parentLength = 12
        chain.adducts = [protonAdduct]

        let result = try chain.removingResidues(in: 2..<2)

        #expect(result.id == id)
        #expect(result.sequenceString == chain.sequenceString)
        #expect(result.range == 4..<8)
        #expect(result.parentLength == 12)
        #expect(result.adducts == [protonAdduct])
    }

    @Test("Invalid indices and ranges throw typed errors")
    func invalidLocations() {
        let chain = ProteinChain(sequence: "ACDE")

        #expect(throws: ChainEditingError.indexOutOfBounds(index: -1, residueCount: 4)) {
            try chain.removingResidue(at: -1)
        }
        #expect(throws: ChainEditingError.indexOutOfBounds(index: 4, residueCount: 4)) {
            try chain.replacingResidue(at: 4, with: chain.residues[0])
        }
        #expect(throws: ChainEditingError.rangeOutOfBounds(range: -1..<2, residueCount: 4)) {
            try chain.removingResidues(in: -1..<2)
        }
        #expect(throws: ChainEditingError.rangeOutOfBounds(range: 2..<5, residueCount: 4)) {
            try chain.removingResidues(in: 2..<5)
        }
    }

    @Test("Removal preserves identity, molecular state, and retained modifications")
    func removalPreservesState() throws {
        let id = UUID()
        var chain = ProteinChain(sequence: "ACDEFG", name: "alpha", id: id)
        chain.range = 10..<16
        chain.parentLength = 20
        chain.adducts = [protonAdduct, sodiumAdduct]
        chain.nTerminal = lossOfAmmonia
        chain.cTerminal = lossOfWater
        chain.residues[1].modification = lossOfWater
        chain.residues[4].modification = lossOfAmmonia

        let result = try chain.removingResidues(in: 1..<3)

        #expect(chain.sequenceString == "ACDEFG")
        #expect(chain.residues[1].modification == lossOfWater)
        #expect(result.sequenceString == "AEFG")
        #expect(result.id == id)
        #expect(result.name == "alpha")
        #expect(result.adducts == [protonAdduct, sodiumAdduct])
        #expect(result.nTerminal == lossOfAmmonia)
        #expect(result.cTerminal == lossOfWater)
        #expect(result.range == 0..<4)
        #expect(result.parentLength == 4)
        #expect(result.residues[2].modification == lossOfAmmonia)
        #expect(result.residues.allSatisfy { $0.modification != lossOfWater })
    }

    @Test("Insertion and replacement have mutating and non-mutating forms")
    func insertionAndReplacement() throws {
        let original = ProteinChain(sequence: "ACD", name: "alpha")
        let glycine = try #require(
            AminoAcidReferenceDefaults.bundled.aminoAcid(identifier: "G")
        )

        let inserted = try original.insertingResidue(glycine, at: 1)
        let insertedMany = try original.insertingResidues([glycine, glycine], at: 3)
        let replaced = try original.replacingResidue(at: 1, with: glycine)

        #expect(original.sequenceString == "ACD")
        #expect(inserted.sequenceString == "AGCD")
        #expect(insertedMany.sequenceString == "ACDGG")
        #expect(replaced.sequenceString == "AGD")
        #expect(inserted.id == original.id)
        #expect(inserted.range == 0..<4)
        #expect(inserted.parentLength == 4)

        var mutable = original
        try mutable.insertResidue(glycine, at: 1)
        try mutable.replaceResidue(at: 0, with: glycine)
        try mutable.removeResidue(at: 2)
        #expect(mutable.sequenceString == "GGD")
        #expect(mutable.range == 0..<3)
        #expect(mutable.parentLength == 3)
    }

    @Test("Existential edits reject incompatible residue types")
    func incompatibleResidueType() throws {
        let chain = ProteinChain(sequence: "ACD")
        let nucleotide = try #require(Nucleotide.standard(code: "A", type: .dna))
        let residue: any Residue = nucleotide

        #expect(throws: ChainEditingError.incompatibleResidueType) {
            try chain.insertingResidue(residue, at: 0)
        }
    }

    @Test("DNA and RNA chains retain their concrete element types and state")
    func nucleicAcidChains() throws {
        let dna = DNAChain(sequence: "GATTACA", name: "coding")
        let rna = RNAChain(sequence: "GAUUACA", name: "messenger")
        var chargedDNA = dna
        var chargedRNA = rna
        chargedDNA.adducts = [sodiumAdduct]
        chargedRNA.adducts = [protonAdduct]
        chargedDNA.residues[4].modification = lossOfWater
        chargedRNA.residues[4].modification = lossOfAmmonia

        let editedDNA: DNAChain = try chargedDNA.removingResidues(in: 1..<3)
        let editedRNA: RNAChain = try chargedRNA.removingResidues(in: 1..<3)

        #expect(editedDNA.sequenceString == "GTACA")
        #expect(editedRNA.sequenceString == "GUACA")
        #expect(editedDNA.id == dna.id)
        #expect(editedRNA.id == rna.id)
        #expect(editedDNA.name == "coding")
        #expect(editedRNA.name == "messenger")
        #expect(editedDNA.adducts == [sodiumAdduct])
        #expect(editedRNA.adducts == [protonAdduct])
        #expect(editedDNA.residues[2].modification == lossOfWater)
        #expect(editedRNA.residues[2].modification == lossOfAmmonia)
        #expect(editedDNA.range == 0..<5)
        #expect(editedRNA.parentLength == 5)
    }
}

@Suite("Range removal mapping")
struct RangeRemovalMappingTests {
    @Test("Positions map before, within, and after the removed range")
    func positions() {
        let mapping = RangeRemovalMapping(removedRange: 2..<5)

        #expect(mapping.map(0) == 0)
        #expect(mapping.map(1) == 1)
        #expect(mapping.map(2) == nil)
        #expect(mapping.map(4) == nil)
        #expect(mapping.map(5) == 2)
        #expect(mapping.map(8) == 5)
    }

    @Test("An empty removed range is an identity mapping")
    func emptyRange() {
        let mapping = RangeRemovalMapping(removedRange: 3..<3)

        #expect(mapping.map(0) == 0)
        #expect(mapping.map(3) == 3)
        #expect(mapping.map(8) == 8)
    }
}

@Suite("Chain molecular-state editing")
struct ChainMolecularStateEditingTests {
    @Test("Adduct copy operations preserve the source and chain identity")
    func adducts() {
        let chain = DNAChain(sequence: "GATTACA", name: "coding")

        let specified = chain.withAdducts([sodiumAdduct, protonAdduct])
        let repeated = chain.withAdducts(type: protonAdduct, count: 2)

        #expect(chain.adducts.isEmpty)
        #expect(specified.adducts == [sodiumAdduct, protonAdduct])
        #expect(repeated.adducts == [protonAdduct, protonAdduct])
        #expect(specified.id == chain.id)
        #expect(specified.name == chain.name)
        #expect(specified.sequenceString == chain.sequenceString)
    }

    @Test("Terminal copy operation preserves the source and other state")
    func termini() {
        let chain = ProteinChain(sequence: "ACDE", name: "alpha")
            .withAdducts([protonAdduct])

        let edited = chain.withTermini(
            nTerm: lossOfAmmonia,
            cTerm: lossOfWater
        )

        #expect(chain.nTerminal == hydrogenModification)
        #expect(chain.cTerminal == hydroxylModification)
        #expect(edited.nTerminal == lossOfAmmonia)
        #expect(edited.cTerminal == lossOfWater)
        #expect(edited.adducts == chain.adducts)
        #expect(edited.id == chain.id)
        #expect(edited.sequenceString == chain.sequenceString)
    }

    @Test("Endpoint removal preserves terminal state until explicitly replaced")
    func endpointRemovalAndTerminalChemistry() throws {
        let precursor = ProteinChain(sequence: "MACDEK")
            .withTermini(nTerm: lossOfAmmonia, cTerm: lossOfWater)

        let structurallyTrimmedNTerm = try precursor.removingResidues(in: 0..<1)
        let matureNTerm = structurallyTrimmedNTerm.withTermini(
            nTerm: hydrogenModification,
            cTerm: precursor.cTerminal
        )

        #expect(structurallyTrimmedNTerm.sequenceString == "ACDEK")
        #expect(structurallyTrimmedNTerm.nTerminal == lossOfAmmonia)
        #expect(structurallyTrimmedNTerm.cTerminal == lossOfWater)
        #expect(matureNTerm.nTerminal == hydrogenModification)
        #expect(matureNTerm.cTerminal == lossOfWater)

        let structurallyTrimmedCTerm = try precursor.removingResidues(in: 5..<6)
        let matureCTerm = structurallyTrimmedCTerm.withTermini(
            nTerm: precursor.nTerminal,
            cTerm: hydroxylModification
        )

        #expect(structurallyTrimmedCTerm.sequenceString == "MACDE")
        #expect(structurallyTrimmedCTerm.nTerminal == lossOfAmmonia)
        #expect(structurallyTrimmedCTerm.cTerminal == lossOfWater)
        #expect(matureCTerm.nTerminal == lossOfAmmonia)
        #expect(matureCTerm.cTerminal == hydroxylModification)
        #expect(precursor.sequenceString == "MACDEK")
    }

    @Test("A residue modification can be added and removed on copies")
    func singleModification() {
        let chain = ProteinChain(sequence: "ACDE", name: "alpha")
        let modified = chain.addingModification(lossOfWater, at: 1)
        let restored = modified.removingModification(at: 1)

        #expect(chain.residues[1].modification == nil)
        #expect(modified.residues[1].modification == lossOfWater)
        #expect(restored.residues[1].modification == nil)
        #expect(modified.id == chain.id)
        #expect(modified.name == chain.name)
    }

    @Test("Bulk residue modification operations edit only matching identifiers")
    func bulkModifications() {
        let chain = ProteinChain(sequence: "ACCA")
        let modified = chain.modifyingResidues(for: "C", with: lossOfWater)
        let restored = modified.removingModifications(for: "C")

        #expect(chain.modifications.isEmpty)
        #expect(modified.residues[0].modification == nil)
        #expect(modified.residues[1].modification == lossOfWater)
        #expect(modified.residues[2].modification == lossOfWater)
        #expect(modified.residues[3].modification == nil)
        #expect(restored.modifications.isEmpty)
    }

    @Test("Modification copy operations support nucleotide residues")
    func nucleotideModifications() {
        let chain = RNAChain(sequence: "ACCA", name: "messenger")
        let modified = chain.modifyingResidues(for: "C", with: lossOfAmmonia)
        let removed = modified.removingModification(at: 1)

        #expect(chain.modifications.isEmpty)
        #expect(modified.residues[1].modification == lossOfAmmonia)
        #expect(modified.residues[2].modification == lossOfAmmonia)
        #expect(removed.residues[1].modification == nil)
        #expect(removed.residues[2].modification == lossOfAmmonia)
        #expect(removed.id == chain.id)
        #expect(removed.name == chain.name)
    }

    @Test("Invalid modification locations retain existing no-op semantics")
    func invalidModificationLocations() {
        let chain = ProteinChain(sequence: "ACDE")

        let added = chain.addingModification(lossOfWater, at: -1)
        let removed = chain.removingModification(at: chain.residues.count)

        #expect(added.modifications.isEmpty)
        #expect(removed.modifications.isEmpty)
        #expect(added.id == chain.id)
        #expect(removed.id == chain.id)
    }
}
