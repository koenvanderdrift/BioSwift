import Foundation
import Testing

@testable import BioSwift

@Suite("Codable invariants and compatibility")
struct CodableTests {
    @Test func chainsDecodePayloadsMissingNewerDefaultedFields() throws {
        let dna = try DNAChain(sequence: "AT", name: "DNA")
        let decodedDNA: DNAChain = try decodeRemovingKeys(["range", "parentLength"], from: dna)
        #expect(decodedDNA.range == zeroRange)
        #expect(decodedDNA.parentLength == 0)

        let rna = try RNAChain(sequence: "AU", name: "RNA")
        let decodedRNA: RNAChain = try decodeRemovingKeys(["range", "parentLength"], from: rna)
        #expect(decodedRNA.range == zeroRange)
        #expect(decodedRNA.parentLength == 0)

        let peptide = try Peptide(sequence: "AC", name: "Peptide")
        let decodedPeptide: Peptide = try decodeRemovingKeys(
            ["nTerminal", "cTerminal", "range", "parentLength"],
            from: peptide
        )
        #expect(decodedPeptide.nTerminal == hydrogenModification)
        #expect(decodedPeptide.cTerminal == hydroxylModification)
        #expect(decodedPeptide.range == zeroRange)
        #expect(decodedPeptide.parentLength == 0)

        let proteinChain = try ProteinChain(sequence: "AC", name: "Protein")
        let decodedProteinChain: ProteinChain = try decodeRemovingKeys(
            ["nTerminal", "cTerminal", "range", "parentLength"],
            from: proteinChain
        )
        #expect(decodedProteinChain.nTerminal == hydrogenModification)
        #expect(decodedProteinChain.cTerminal == hydroxylModification)
        #expect(decodedProteinChain.range == zeroRange)
        #expect(decodedProteinChain.parentLength == 0)
    }

    @Test func formulaRejectsInconsistentRepresentations() throws {
        let formula = try Formula("H2O")
        var payload = try #require(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(formula)) as? [String: Any]
        )
        payload["inputString"] = "CO2"

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(
                Formula.self,
                from: JSONSerialization.data(withJSONObject: payload)
            )
        }
    }

    @Test func glycanNodeDecodingValidatesTheCompleteTree() throws {
        let duplicateID = UUID()
        let child = GlycanNode(id: duplicateID, monosaccharide: .galactose)
        let root = GlycanNode(
            id: duplicateID,
            monosaccharide: .glucose,
            branches: [
                GlycanBranch(
                    linkage: try GlycosidicLinkage(donorPosition: 1, acceptorPosition: 4),
                    child: child
                )
            ]
        )

        #expect(throws: GlycanError.duplicateNodeID(duplicateID)) {
            try JSONDecoder().decode(GlycanNode.self, from: JSONEncoder().encode(root))
        }
    }

    private func decodeRemovingKeys<Value: Codable>(
        _ keys: [String],
        from value: Value
    ) throws -> Value {
        var payload = try #require(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(value)) as? [String: Any]
        )
        for key in keys {
            payload.removeValue(forKey: key)
        }

        return try JSONDecoder().decode(
            Value.self,
            from: JSONSerialization.data(withJSONObject: payload)
        )
    }
}
