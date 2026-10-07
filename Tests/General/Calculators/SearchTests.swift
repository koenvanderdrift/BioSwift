//
//  SearchTests.swift
//  BioSwift
//

import Foundation
import Testing

@testable import BioSwift

@Suite struct SearchTests: BioSwiftTestSuite {
    var fixtures = BioSwiftTestFixtures()
    @Test func lowMassSearch() throws {
        if let chain = testProtein.chains.first {
            let searchParameters = MassSearchParameters(
                searchValue: 1, tolerance: .ppm(10),
                searchType: .sequential, massType: .monoisotopic, charge: 0)

            let ranges: [Range<Int>] = chain.searchMass(params: searchParameters)

            #expect(ranges.isEmpty)
        }
    }

    @Test func moverzSearch() throws {
        if let chain = testProtein.chains.first {
            let searchParameters = MassSearchParameters(
                searchValue: 890.3877, tolerance: .ppm(10),
                searchType: .sequential, massType: .monoisotopic, charge: 2)

            let ranges: [Range<Int>] = chain.searchMass(params: searchParameters)

            BioSwiftDiagnostics.log(ranges)
            let sequenceStrings = ranges.map {
                chain.sequenceString[$0]
            }

            #expect(sequenceStrings.contains(where: {
                $0 == "TDTSHHDQDHPTFNK"
            }))
            #expect(!sequenceStrings.contains(where: {
                $0 == "NIFFS"
            }))
        }
    }

    @Test func moverzLongSearch() throws {
        let longTest = try Protein(
            sequence: """

                MIPARFAGVLLALALILPGTLCAEGTRGRSSTARCSLFGSDFVNTFDGSMYSFAGYCSYLLAGGCQKRSFSIIGDFQNGKRVSLSVYLGEFFDIHLFVNGTVTQGDQRVSMPYASKGLYLETEAGYYKLSGEAYGFVARIDGSGNFQVLLSDRYFNKTCGLCGNFNIFAEDDFMTQEGTLTSDPYDFANSWALSSGEQWCERASPPSSSCNISSGEMQKGLWEQCQLLKSTSVFARCHPLVDPEPFVALCEKTLCECAGGLECACPALLEYARTCAQEGMVLYGWTDHSACSPVCPAGMEYRQCVSPCARTCQSLHINEMCQERCVDGCSCPEGQLLDEGLCVESTECPCVHSGKRYPPGTSLSRDCNTCICRNSQWICSNEECPGECLVTGQSHFKSFDNRYFTFSGICQYLLARDCQDHSFSIVIETVQCADDRDAVCTRSVTVRLPGLHNSLVKLKHGAGVAMDGQDVQLPLLKGDLRIQHTVTASVRLSYGEDLQMDWDGRGRLLVKLSPVYAGKTCGLCGNYNGNQGDDFLTPSGLAEPRVEDFGNAWKLHGDCQDLQKQHSDPCALNPRMTRFSEEACAVLTSPTFEACHRAVSPLPYLRNCRYDVCSCSDGRECLCGALASYAAACAGRGVRVAWREPGRCELNCPKGQVYLQCGTPCNLTCRSLSYPDEECNEACLEGCFCPPGLYMDERGDCVPKAQCPCYYDGEIFQPEDIFSDHHTMCYCEDGFMHCTMSGVPGSLLPDAVLSSPLSHRSKRSLSCRPPMVKLVCPADNLRAEGLECTKTCQNYDLECMSMGCVSGCLCPPGMVRHENRCVALERCPCFHQGKEYAPGETVKIGCNTCVCQDRKWNCTDHVCDATCSTIGMAHYLTFDGLKYLFPGECQYVLVQDYCGSNPGTFRILVGNKGCSHPSVKCKKRVTILVEGGEIELFDGEVNVKRPMKDETHFEVVESGRYIILLLGKALSVVWDRHLSISVVLKQTYQEKVCGLCGNFDGIQNNDLTSSNLQVEEDPVDFGNSWKVSSQCADTRKVPLDSSPATCHNNIMKQTMVDSSCRILTSDVFQDCNKLVDPEPYLDVCIYDTCSCESIGDCACFCDTIAAYAHVCAQHGKVVTWRTATLCPQSCEERNLRENGYECEWRYNSCAPACQVTCQHPEPLACPVQCVEGCHAHCPPGKILDELLQTCVDPEDCPVCEVAGRRFASGKKVTLNPSDPEHCQICHCDVVNLTCEACQEPGGLVVPPTDAPVSPTTLYVEDISEPPLHDFYCSRLLDLVFLLDGSSRLSEAEFEVLKAFVVDMMERLRISQKWVRVAVVEYHDGSHAYIGLKDRKRPSELRRIASQVKYAGSQVASTSEVLKYTLFQIFSKIDRPEASRITLLLMASQEPQRMSRNFVRYVQGLKKKKVIVIPVGIGPHANLKQIRLIEKQAPENKAFVLSSVDELEQQRDEIVSYLCDLAPEAPPPTLPPDMAQVTVGPGLLGVSTLGPKRNSMVLDVAFVLEGSDKIGEADFNRSKEFMEEVIQRMDVGQDSIHVTVLQYSYMVTVEYPFSEAQSKGDILQRVREIRYQGGNRTNTGLALRYLSDHSFLVSQGDREQAPNLVYMVTGNPASDEIKRLPGDIQVVPIGVGPNANVQELERIGWPNAPILIQDFETLPREAPDLVLQRCCSGEGLQIPTLSPAPDCSQPLDVILLLDGSSSFPASYFDEMKSFAKAFISKANIGPRLTQVSVLQYGSITTIDVPWNVVPEKAHLLSLVDVMQREGGPSQIGDALGFAVRYLTSEMHGARPGASKAVVILVTDVSVDSVDAAADAARSNRVTVFPIGIGDRYDAAQLRILAGPAGDSNVVKLQRIEDLPTMVTLGNSFLHKLCSGFVRICMDEDGNEKRPGDVWTLPDQCHTVTCQPDGQTLLKSHRVNCDRGLRPSCPNSQSPVKVEETCGCRWTCPCVCTGSSTRHIVTFDGQNFKLTGSCSYVLFQNKEQDL...
                """.filter(\.isLetter))

        if let chain = longTest.chains.first {
            let searchParameters = MassSearchParameters(
                searchValue: 10355.6744, tolerance: .ppm(10),
                searchType: .sequential, massType: .monoisotopic, charge: 1)

            let ranges: [Range<Int>] = chain.searchMass(params: searchParameters)

            BioSwiftDiagnostics.log(ranges)
            let sequenceStrings = ranges.map {
                chain.sequenceString[$0]
            }

            #expect(
                sequenceStrings.contains(where: {
                    $0
                        == "LKKKKVIVIPVGIGPHANLKQIRLIEKQAPENKAFVLSSVDELEQQRDEIVSYLCDLAPEAPPPTLPPDMAQVTVGPGLLGVSTLGPKRNSMVLDV"
                }))
            #expect(!sequenceStrings.contains(where: {
                $0 == "NIFFS"
            }))
        }
    }

    @Test func massSearchWithModification() throws {
        for modification in try modifications(
            unimodName: "Phospho", psiModAccession: "MOD:00046",
            uniProtPTMAccession: "PTM-0253") {
            var chain = try #require(testProtein.chains.first)
            try chain.addModification(modification, at: 76)

            let searchParameters = MassSearchParameters(
                searchValue: 689.28, tolerance: .ppm(10),
                searchType: .sequential, massType: .monoisotopic, charge: 0)

            let ranges: [Range<Int>] = chain.searchMass(params: searchParameters)
            let sequenceStrings = ranges.map {
                chain.sequenceString[$0]
            }

            #expect(sequenceStrings.contains(where: {
                $0 == "IFFSP"
            }))
        }
    }

    @Test func averageMassSearch() throws {
        if let chain = testProtein.chains.first {
            let searchParameters = MassSearchParameters(
                searchValue: 609.71, tolerance: .ppm(10),
                searchType: .sequential, massType: .average, charge: 0)

            let ranges: [Range<Int>] = chain.searchMass(params: searchParameters)
            let sequenceStrings = ranges.map {
                chain.sequenceString[$0]
            }

            #expect(sequenceStrings.contains(where: {
                $0 == "IFFSP"
            }))
            #expect(!sequenceStrings.contains(where: {
                $0 == "NIFFS"
            }))
        }
    }

    @Test func nominalMassSearch() throws {
        let chain = try #require(testProtein.chains.first)
        let targetSequence = "IFFSP"
        let targetMass = Dalton(try Peptide(sequence: targetSequence).nominalMass)
        let searchParameters = MassSearchParameters(
            searchValue: targetMass,
            tolerance: .dalton(0),
            searchType: .sequential,
            massType: .nominal,
            charge: 0)

        let ranges = chain.searchMass(params: searchParameters)
        let optimizedSequences = ranges.map { String(chain.sequenceString[$0]) }

        #expect(optimizedSequences.contains(targetSequence))
    }

    @Test func massTolerancePreservesDecimalValue() throws {
        let value = decimal("0.1000000000000000001")
        let parameters = MassSearchParameters(
            searchValue: 100,
            tolerance: .dalton(value),
            searchType: .sequential,
            massType: .monoisotopic,
            charge: 0
        )
        #expect(parameters.massRange.lowerBound == 100 - value)
        #expect(parameters.massRange.upperBound == 100 + value)
    }

    @Test(arguments: [
        MassTolerance.ppm(1),
        MassTolerance.dalton(1),
        MassTolerance.percent(1),
        MassTolerance.mmu(1),
    ])
    func massToleranceValuePreservesUnit(initialTolerance: MassTolerance) {
        let value = decimal("0.1000000000000000001")
        var tolerance = initialTolerance

        #expect(tolerance.value == 1)
        tolerance.value = value
        #expect(tolerance.value == value)

        switch (initialTolerance, tolerance) {
        case (.ppm, .ppm), (.dalton, .dalton), (.percent, .percent), (.mmu, .mmu):
            break
        default:
            Issue.record("Updating a tolerance value changed its unit")
        }
    }

    @Test(arguments: MassTolerance.Unit.allCases)
    func massToleranceUnitPreservesValue(unit: MassTolerance.Unit) throws {
        let value = decimal("0.1000000000000000001")
        var tolerance = MassTolerance.ppm(value)

        tolerance.unit = unit

        #expect(tolerance.value == value)
        #expect(tolerance.unit == unit)
    }

    @Test func massToleranceUnitsHaveDisplayValues() throws {
        #expect(MassTolerance.Unit.allCases == [.ppm, .dalton, .percent, .mmu])
        #expect(MassTolerance.Unit.allCases.map(\.rawValue) == ["ppm", "Da", "%", "mmu"])
    }

    @Test(arguments: [
        (MassTolerance.ppm(10), decimal("99.999"), decimal("100.001")),
        (MassTolerance.dalton(decimal("0.25")), decimal("99.75"), decimal("100.25")),
        (MassTolerance.percent(decimal("0.5")), decimal("99.5"), decimal("100.5")),
        (MassTolerance.mmu(250), decimal("99.75"), decimal("100.25")),
    ])
    func massToleranceRanges(
        tolerance: MassTolerance, expectedLowerBound: Dalton, expectedUpperBound: Dalton
    ) {
        let parameters = MassSearchParameters(
            searchValue: 100,
            tolerance: tolerance,
            searchType: .sequential,
            massType: .monoisotopic,
            charge: 0
        )

        #expect(parameters.massRange.lowerBound == expectedLowerBound)
        #expect(parameters.massRange.upperBound == expectedUpperBound)
    }

    @Test func checkMassDifferences() throws {
        let peptide = try Peptide(sequence: "SAMPLER")
        let first = peptide.subChain(range: 0..<1)
        let truncated = peptide.subChain(range: 1..<7)

        #expect(first.sequenceString == "S")
        #expect(truncated.sequenceString == "AMPLER")

        let peptideMass = peptide.monoisotopicMass
        let truncatedMass = truncated.monoisotopicMass
        let firstMass = first.monoisotopicMass

        #expect(truncatedMass == peptideMass - firstMass + water.monoisotopicMass)
    }

}
