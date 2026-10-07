//
//  UtilityTests.swift
//  BioSwift
//

import Foundation
import Testing

@testable import BioSwift

@Suite struct UtilityTests: BioSwiftTestSuite {
    var fixtures = BioSwiftTestFixtures()
    @Test func checkRegex() throws {
        let data = """
            BEGIN PEPTIDE
            ABCDEF
            END PEPTIDE
            BEGIN PEPTIDE
            GHIJKL
            END PEPTIDE
            """

        let beginRanges = data.ranges(of: "BEGIN PEPTIDE")
        let endRanges = data.ranges(of: "END PEPTIDE")

        #expect(beginRanges.count == 2)
        #expect(endRanges.count == 2)

        let text = """
            BEGIN SEQUENCE
            MKWVTFISLL
            END SEQUENCE
            """

        let sequence = text.substring(between: "BEGIN SEQUENCE", and: "END SEQUENCE")?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        #expect(sequence == "MKWVTFISLL")
    }

    @Test func findSubStrings() throws {
        let text = """
            BEGIN PEPTIDE
            PEPTIDEK
            END PEPTIDE
            BEGIN PEPTIDE
            MKWVTF
            END PEPTIDE
            """

        let peptides = text.substrings(between: "BEGIN PEPTIDE", and: "END PEPTIDE").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        #expect(peptides == ["PEPTIDEK", "MKWVTF"])
    }

    @Test func findsSingleLetterRanges() throws {
        let sequence = "AAAA"

        #expect(sequence.sequenceRanges(of: "A") == [0..<1, 1..<2, 2..<3, 3..<4])
    }

    @Test func findsNonOverlappingSequenceRanges() throws {
        let sequence = "AAAA"

        #expect(sequence.sequenceRanges(of: "AA") == [0..<2, 2..<4])
    }

    @Test func findsOverlappingSequenceRanges() throws {
        let sequence = "AAAA"

        #expect(sequence.sequenceRanges(of: "AA", allowingOverlaps: true) == [0..<2, 1..<3, 2..<4])
    }

    @Test("Finds all non-overlapping matching ranges") func stringMatchingRanges() throws {
        let text = "ABC DEF ABC"

        let result = text.ranges(matching: "ABC")

        #expect(result == [0..<3, 8..<11])
    }

    @Test("Empty search string returns no ranges") func emptySearchStringReturnsNoRanges() throws {
        let text = "ABC DEF ABC"

        #expect(text.ranges(matching: "").isEmpty)
    }

    @Test("Missing search string returns no ranges") func missingSearchStringReturnsNoRanges() throws {
        let text = "ABC DEF ABC"

        #expect(text.ranges(matching: "XYZ").isEmpty)
    }

    @Test("Single-character matches return one-length ranges") func singleCharacterMatchingRanges() throws {
        let text = "ABACA"

        let result = text.ranges(matching: "A")

        #expect(result == [0..<1, 2..<3, 4..<5])
    }

    @Test func convertsSequenceCoordinatesToOneBasedRanges() throws {
        let sequence = "MKWVTFISLL"

        #expect(sequence.sequenceRanges(of: "VTF") == [3..<6])
    }

    @Test func emptySubstringProducesNoRanges() throws {
        let sequence = "PEPTIDE"

        #expect(sequence.sequenceRanges(of: "").isEmpty)
    }

    @Test func integerRangeLengthUsesUpperExclusiveBounds() throws {
        #expect((2..<5).length == 3)
        #expect((0..<0).length == 0)
    }

    @Test func substringUsesZeroBasedUpperExclusiveRange() throws {
        let text = "PEPTIDE"

        #expect(text.substring(in: 0..<3) == "PEP")
        #expect(text.substring(in: 3..<7) == "TIDE")
        #expect(text.substring(in: 2..<2).isEmpty)
        #expect(text.substring(in: 0..<8) == text)
    }

    @Test func substringUsesCharacterOffsets() throws {
        #expect("A🧬BC".substring(in: 1..<3) == "🧬B")
    }

    @Test func removingUsesZeroBasedUpperExclusiveRange() throws {
        let text = "PEPTIDE"

        #expect(text.removing(range: 0..<3) == "TIDE")
        #expect(text.removing(range: 3..<7) == "PEP")
        #expect(text.removing(range: 2..<2) == text)
        #expect(text.removing(range: 0..<8).isEmpty)
        #expect("A🧬BC".removing(range: 1..<3) == "AC")
    }

    @Test func identifiesAnyProhibitedCharacter() throws {
        let allowedCharacters = CharacterSet(charactersIn: "ACDEFGHIKLMNPQRSTVWY")

        #expect(!"PEPTIDE".containsCharacterOutside(allowedCharacters))
        #expect("PEPT1DE".containsCharacterOutside(allowedCharacters))
    }

    @Test func malformedXMLThrowsParseError() throws {
        let malformedXML = """
            <root>
                <item>Broken</root>
            """

        let data = Data(malformedXML.utf8)
        let elements = try ElementReferenceDefaults.loadBundled()

        #expect(throws: Error.self) {
            try UnimodXMLParser(elements: elements).parse(data: data)
        }
    }

    @Test func malformedXMLThrowsParseError2() throws {
        let malformedXML = """
            <root>
                <item>Broken</root>
            """

        let data = Data(malformedXML.utf8)
        let elements = try ElementReferenceDefaults.loadBundled()

        let error = try #require(
            #expect(throws: Error.self) {
                try UnimodXMLParser(elements: elements).parse(data: data)
            })

        let nsError = error as NSError

        #expect(nsError.domain == XMLParser.errorDomain)
        #expect(!nsError.localizedDescription.isEmpty)
    }

    @Test func malformedXMLThrowsXMLParserError() throws {
        let malformedXML = Data("<root><broken></root>".utf8)

        let parser = UnimodXMLParser(elements: try ElementReferenceDefaults.loadBundled())

        let error = try #require(
            #expect(throws: Error.self) {
                try parser.parse(data: malformedXML)
            })

        let nsError = error as NSError

        #expect(nsError.domain == XMLParser.errorDomain)
        #expect(!nsError.localizedDescription.isEmpty)

        BioSwiftDiagnostics.log("Received expected XML parse error: \(nsError.localizedDescription)")
    }

    @Test func malformedXMLThrowsXMLParserError2() throws {
        let malformedXML = Data("<root><broken></root>".utf8)

        let parser = UnimodXMLParser(elements: try ElementReferenceDefaults.loadBundled())

        let error = #expect(throws: Error.self) {
            try parser.parse(data: malformedXML)
        }

        let nsError = try #require(error as NSError?)

        #expect(nsError.domain == XMLParser.errorDomain)
        #expect(!nsError.localizedDescription.isEmpty)
    }

    @Test("Convert BiologicalRange to zero-based Range") func biologicalRangeToRange() throws {
        let biologicalRange = BiologicalRange(1...4)

        let result = biologicalRange.zeroBasedRange

        #expect(result == 0..<4)
    }

    @Test("Convert zero-based Range to BiologicalRange") func rangeToBiologicalRange() throws {
        let range: Range<Int> = 0..<4

        let result = range.biologicalRange

        #expect(result == BiologicalRange(1...4))
    }

    @Test("Round-trip Range through BiologicalRange") func rangeBiologicalRangeRoundTrip() throws {
        let original: Range<Int> = 25..<33

        let biologicalRange = original.biologicalRange
        let convertedBack = biologicalRange?.zeroBasedRange

        #expect(biologicalRange == BiologicalRange(26...33))
        #expect(convertedBack == original)
    }

    @Test("Empty Range cannot convert to BiologicalRange") func emptyRangeToBiologicalRange() throws {
        let emptyRange: Range<Int> = 0..<0

        #expect(emptyRange.biologicalRange == nil)
    }

    @Test("BiologicalRange rejects a zero-based ClosedRange") func invalidBiologicalRange() throws {
        let result = BiologicalRange(validating: 0...4)

        #expect(result == nil)
    }

    @Test func rangeClampsToSequenceBounds() throws {
        #expect((-2..<3).clamped(toSequenceLength: 10) == 0..<3)
        #expect((8..<15).clamped(toSequenceLength: 10) == 8..<10)
        #expect((12..<15).clamped(toSequenceLength: 10) == zeroRange)
    }

    @Test func biologicalRangeIsOneBased() throws {
        #expect(BiologicalRange(1...1).isValidRange)
        #expect(BiologicalRange(validating: 0...1) == nil)
    }

    @Test func propertySetContainsExpectedValues() throws {
        let properties: Set<AminoAcidProperty> = [.polar, .aromatic]

        #expect(properties.contains(.polar))
        #expect(properties.contains(.aromatic))
        #expect(!properties.contains(.nonpolar))
        #expect(properties.count == 2)
    }

    @Test func duplicatePropertiesAreIgnored() throws {
        let properties: Set<AminoAcidProperty> = [.polar, .polar, .aromatic]

        #expect(properties == [.polar, .aromatic])
        #expect(properties.count == 2)
    }

    @Test func twoWordHasCorrectDisplayName() throws {
        let property = AminoAcidProperty.chargedPositive

        #expect(property.displayName == "Charged Positive")
    }

}
