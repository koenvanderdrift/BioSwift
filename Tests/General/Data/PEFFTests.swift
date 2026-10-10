//
//  PEFFTests.swift
//  BioSwift
//

import Testing

@testable import BioSwift

@Suite struct PEFFTests {
    private let parser = PEFFParser()

    @Test func parsesMetadataRecordsAndUnknownAnnotations() throws {
        let text = """
            # PEFF 1.0
            # //
            # DbName=Example
            # Prefix=ex
            # SequenceType=AA
            # //
            >ex:P12345 \\PName=Example protein \\GName=GENE1 \\TaxName=Homo sapiens \\Unknown=(one|two)
            MPEP
            TIDE
            """

        let document = try parser.parse(text)
        let record = try #require(document.records.first)

        #expect(document.version == "1.0")
        #expect(document.metadataValues(for: "DbName") == ["Example"])
        #expect(record.prefix == "ex")
        #expect(record.accession == "P12345")
        #expect(record.sequence == "MPEPTIDE")
        #expect(record.values(for: "Unknown") == ["(one|two)"])
        #expect(record.fastaRecord.headerFormat == .peff)
        #expect(record.fastaRecord.fullName == "Example protein")
        #expect(record.fastaRecord.organism == "Homo sapiens")
    }

    @Test func serializesAndReparsesWithoutLosingFields() throws {
        let original = try parser.parse("""
            # PEFF 1.0
            # //
            # DbName=Example
            # //
            >ex:A1 \\PName=Alpha \\ModResPsi=(1|MOD:00046)
            MPEPTIDE
            """)
        let reparsed = try parser.parse(original.peffString)

        #expect(reparsed == original)
    }

    @Test func rejectsOrdinaryFastaAsPEFF() {
        #expect(throws: PEFFError.missingSignature) {
            try parser.parse(">sp|P12345|EXAMPLE Protein\nMPEPTIDE")
        }
    }
}

