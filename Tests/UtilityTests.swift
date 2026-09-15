//
//  UtilityTests.swift
//  BioSwift
//

import Foundation
import Testing

@testable import BioSwift

@Suite struct UtilityTests: BioSwiftTestSuite {
    var fixtures = BioSwiftTestFixtures()
    @Test func checkRegex() {
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

    @Test func findSubStrings() {
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

    @Test func findsSingleLetterRanges() {
        let sequence = "AAAA"

        #expect(sequence.sequenceRanges(of: "A") == [0..<1, 1..<2, 2..<3, 3..<4])
    }

    @Test func findsNonOverlappingSequenceRanges() {
        let sequence = "AAAA"

        #expect(sequence.sequenceRanges(of: "AA") == [0..<2, 2..<4])
    }

    @Test func findsOverlappingSequenceRanges() {
        let sequence = "AAAA"

        #expect(sequence.sequenceRanges(of: "AA", allowingOverlaps: true) == [0..<2, 1..<3, 2..<4])
    }

    @Test("Finds all non-overlapping matching ranges") func stringMatchingRanges() {
        let text = "ABC DEF ABC"

        let result = text.ranges(matching: "ABC")

        #expect(result == [0..<3, 8..<11])
    }

    @Test("Empty search string returns no ranges") func emptySearchStringReturnsNoRanges() {
        let text = "ABC DEF ABC"

        #expect(text.ranges(matching: "").isEmpty)
    }

    @Test("Missing search string returns no ranges") func missingSearchStringReturnsNoRanges() {
        let text = "ABC DEF ABC"

        #expect(text.ranges(matching: "XYZ").isEmpty)
    }

    @Test("Single-character matches return one-length ranges") func singleCharacterMatchingRanges() {
        let text = "ABACA"

        let result = text.ranges(matching: "A")

        #expect(result == [0..<1, 2..<3, 4..<5])
    }

    @Test func convertsSequenceCoordinatesToOneBasedRanges() {
        let sequence = "MKWVTFISLL"

        #expect(sequence.sequenceRanges(of: "VTF") == [3..<6])
    }

    @Test func emptySubstringProducesNoRanges() {
        let sequence = "PEPTIDE"

        #expect(sequence.sequenceRanges(of: "").isEmpty)
    }

    @Test func identifiesAnyProhibitedCharacter() {
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

        #expect(throws: Error.self) {
            try UnimodXMLParser().parse(data: data)
        }
    }

    @Test func malformedXMLThrowsParseError2() throws {
        let malformedXML = """
            <root>
                <item>Broken</root>
            """

        let data = Data(malformedXML.utf8)

        let error = try #require(
            #expect(throws: Error.self) {
                try UnimodXMLParser().parse(data: data)
            })

        let nsError = error as NSError

        #expect(nsError.domain == XMLParser.errorDomain)
        #expect(!nsError.localizedDescription.isEmpty)
    }

    @Test func malformedXMLThrowsXMLParserError() throws {
        let malformedXML = Data("<root><broken></root>".utf8)

        let parser = UnimodXMLParser()

        let error = try #require(
            #expect(throws: Error.self) {
                try parser.parse(data: malformedXML)
            })

        let nsError = error as NSError

        #expect(nsError.domain == XMLParser.errorDomain)
        #expect(!nsError.localizedDescription.isEmpty)

        #if DEBUG
            debugPrint("Received expected XML parse error:", nsError.localizedDescription)
        #endif
    }

    @Test func malformedXMLThrowsXMLParserError2() throws {
        let malformedXML = Data("<root><broken></root>".utf8)

        let parser = UnimodXMLParser()

        let error = #expect(throws: Error.self) {
            try parser.parse(data: malformedXML)
        }

        let nsError = try #require(error as NSError?)

        #expect(nsError.domain == XMLParser.errorDomain)
        #expect(!nsError.localizedDescription.isEmpty)
    }

    @Test("Convert BiologicalRange to zero-based Range") func biologicalRangeToRange() {
        let biologicalRange = BiologicalRange(1...4)

        let result = biologicalRange.zeroBasedRange

        #expect(result == 0..<4)
    }

    @Test("Convert zero-based Range to BiologicalRange") func rangeToBiologicalRange() {
        let range: Range<Int> = 0..<4

        let result = range.biologicalRange

        #expect(result == BiologicalRange(1...4))
    }

    @Test("Round-trip Range through BiologicalRange") func rangeBiologicalRangeRoundTrip() {
        let original: Range<Int> = 25..<33

        let biologicalRange = original.biologicalRange
        let convertedBack = biologicalRange?.zeroBasedRange

        #expect(biologicalRange == BiologicalRange(26...33))
        #expect(convertedBack == original)
    }

    @Test("Empty Range cannot convert to BiologicalRange") func emptyRangeToBiologicalRange() {
        let emptyRange: Range<Int> = 0..<0

        #expect(emptyRange.biologicalRange == nil)
    }

    @Test("BiologicalRange rejects a zero-based ClosedRange") func invalidBiologicalRange() {
        let result = BiologicalRange(validating: 0...4)

        #expect(result == nil)
    }

    @Test func propertySetContainsExpectedValues() {
        let properties: Set<AminoAcidProperty> = [.polar, .aromatic]

        #expect(properties.contains(.polar))
        #expect(properties.contains(.aromatic))
        #expect(!properties.contains(.nonpolar))
        #expect(properties.count == 2)
    }

    @Test func duplicatePropertiesAreIgnored() {
        let properties: Set<AminoAcidProperty> = [.polar, .polar, .aromatic]

        #expect(properties == [.polar, .aromatic])
        #expect(properties.count == 2)
    }

    @Test func twoWordHasCorrectDisplayName() {
        let property = AminoAcidProperty.chargedPositive

        #expect(property.displayName == "Charged Positive")
    }

}
