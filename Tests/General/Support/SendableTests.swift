import Foundation
import Testing

@testable import BioSwift

@Suite("Sendable API")
struct SendableTests {
    @Test func immutableServicesAreSendable() throws {
        let peptide = try Peptide(sequence: "AC")
        let peptideFragmenter = PeptideFragmenter(
            precursor: try peptide.ionized(with: [protonAdduct])
        )
        let oligonucleotideFragmenter = OligonucleotideFragmenter(
            precursor: try DNAChain(sequence: "AC").ionized(with: [negativeProtonAdduct])
        )
        let digester = ProteinDigester(protein: try Protein(sequence: "AC"))

        requireSendable(peptideFragmenter)
        requireSendable(oligonucleotideFragmenter)
        requireSendable(digester)
        requireSendable(FastaParser())
        requireSendable(IsoelectricPointCalculator(residues: peptide.residues))
    }

    @Test func isoelectricPointCalculatorHasValueSemantics() throws {
        let peptide = try Peptide(sequence: "AC")
        let original = IsoelectricPointCalculator(residues: peptide.residues)
        var copy = original

        copy.residues = []

        #expect(original.residues.count == 2)
        #expect(copy.residues.isEmpty)
    }

    @Test func fastaParserCanBeSharedAcrossTasks() async throws {
        let parser = FastaParser()
        let data = Data(">first\nAC\n>second\nGT".utf8)

        async let first = parser.parse(data)
        async let second = parser.parse(data)
        let results = try await [first, second]

        #expect(results.allSatisfy { $0.map(\.sequence) == ["AC", "GT"] })
    }

    private func requireSendable<Value: Sendable>(_: Value) {}
}
