//
//  SearchTests.swift
//  BioSwift
//

import Foundation
import Testing

@testable import BioSwift

@Suite struct SearchTests: BioSwiftTestSuite {
    var fixtures = BioSwiftTestFixtures()
    @Test func lowMassSearch() {
        if let chain = testProtein.chains.first {
            let searchParameters = MassSearchParameters(
                searchValue: 1, tolerance: MassTolerance(type: .ppm, value: 10),
                searchType: .sequential, massType: .monoisotopic, charge: 0)

            let ranges: [Range<Int>] = chain.searchMass(params: searchParameters)

            #expect(ranges.isEmpty)
        }
    }

    @Test func moverzSearch() {
        if let chain = testProtein.chains.first {
            let searchParameters = MassSearchParameters(
                searchValue: 890.3877, tolerance: MassTolerance(type: .ppm, value: 10),
                searchType: .sequential, massType: .monoisotopic, charge: 2)

            let ranges = measure("Sliding Window") {
                let ranges: [Range<Int>] = chain.searchMass(params: searchParameters)
                return ranges
            }

            debugPrint(ranges)
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

    @Test func moverzLongSearch() {
        let longTest = Protein(
            sequence: """

                MIPARFAGVLLALALILPGTLCAEGTRGRSSTARCSLFGSDFVNTFDGSMYSFAGYCSYLLAGGCQKRSFSIIGDFQNGKRVSLSVYLGEFFDIHLFVNGTVTQGDQRVSMPYASKGLYLETEAGYYKLSGEAYGFVARIDGSGNFQVLLSDRYFNKTCGLCGNFNIFAEDDFMTQEGTLTSDPYDFANSWALSSGEQWCERASPPSSSCNISSGEMQKGLWEQCQLLKSTSVFARCHPLVDPEPFVALCEKTLCECAGGLECACPALLEYARTCAQEGMVLYGWTDHSACSPVCPAGMEYRQCVSPCARTCQSLHINEMCQERCVDGCSCPEGQLLDEGLCVESTECPCVHSGKRYPPGTSLSRDCNTCICRNSQWICSNEECPGECLVTGQSHFKSFDNRYFTFSGICQYLLARDCQDHSFSIVIETVQCADDRDAVCTRSVTVRLPGLHNSLVKLKHGAGVAMDGQDVQLPLLKGDLRIQHTVTASVRLSYGEDLQMDWDGRGRLLVKLSPVYAGKTCGLCGNYNGNQGDDFLTPSGLAEPRVEDFGNAWKLHGDCQDLQKQHSDPCALNPRMTRFSEEACAVLTSPTFEACHRAVSPLPYLRNCRYDVCSCSDGRECLCGALASYAAACAGRGVRVAWREPGRCELNCPKGQVYLQCGTPCNLTCRSLSYPDEECNEACLEGCFCPPGLYMDERGDCVPKAQCPCYYDGEIFQPEDIFSDHHTMCYCEDGFMHCTMSGVPGSLLPDAVLSSPLSHRSKRSLSCRPPMVKLVCPADNLRAEGLECTKTCQNYDLECMSMGCVSGCLCPPGMVRHENRCVALERCPCFHQGKEYAPGETVKIGCNTCVCQDRKWNCTDHVCDATCSTIGMAHYLTFDGLKYLFPGECQYVLVQDYCGSNPGTFRILVGNKGCSHPSVKCKKRVTILVEGGEIELFDGEVNVKRPMKDETHFEVVESGRYIILLLGKALSVVWDRHLSISVVLKQTYQEKVCGLCGNFDGIQNNDLTSSNLQVEEDPVDFGNSWKVSSQCADTRKVPLDSSPATCHNNIMKQTMVDSSCRILTSDVFQDCNKLVDPEPYLDVCIYDTCSCESIGDCACFCDTIAAYAHVCAQHGKVVTWRTATLCPQSCEERNLRENGYECEWRYNSCAPACQVTCQHPEPLACPVQCVEGCHAHCPPGKILDELLQTCVDPEDCPVCEVAGRRFASGKKVTLNPSDPEHCQICHCDVVNLTCEACQEPGGLVVPPTDAPVSPTTLYVEDISEPPLHDFYCSRLLDLVFLLDGSSRLSEAEFEVLKAFVVDMMERLRISQKWVRVAVVEYHDGSHAYIGLKDRKRPSELRRIASQVKYAGSQVASTSEVLKYTLFQIFSKIDRPEASRITLLLMASQEPQRMSRNFVRYVQGLKKKKVIVIPVGIGPHANLKQIRLIEKQAPENKAFVLSSVDELEQQRDEIVSYLCDLAPEAPPPTLPPDMAQVTVGPGLLGVSTLGPKRNSMVLDVAFVLEGSDKIGEADFNRSKEFMEEVIQRMDVGQDSIHVTVLQYSYMVTVEYPFSEAQSKGDILQRVREIRYQGGNRTNTGLALRYLSDHSFLVSQGDREQAPNLVYMVTGNPASDEIKRLPGDIQVVPIGVGPNANVQELERIGWPNAPILIQDFETLPREAPDLVLQRCCSGEGLQIPTLSPAPDCSQPLDVILLLDGSSSFPASYFDEMKSFAKAFISKANIGPRLTQVSVLQYGSITTIDVPWNVVPEKAHLLSLVDVMQREGGPSQIGDALGFAVRYLTSEMHGARPGASKAVVILVTDVSVDSVDAAADAARSNRVTVFPIGIGDRYDAAQLRILAGPAGDSNVVKLQRIEDLPTMVTLGNSFLHKLCSGFVRICMDEDGNEKRPGDVWTLPDQCHTVTCQPDGQTLLKSHRVNCDRGLRPSCPNSQSPVKVEETCGCRWTCPCVCTGSSTRHIVTFDGQNFKLTGSCSYVLFQNKEQDL...
                """)

        if let chain = longTest.chains.first {
            let searchParameters = MassSearchParameters(
                searchValue: 10355.6744, tolerance: MassTolerance(type: .ppm, value: 10),
                searchType: .sequential, massType: .monoisotopic, charge: 1)

            let ranges = measure("Sliding Window") {
                let ranges: [Range<Int>] = chain.searchMass(params: searchParameters)
                return ranges
            }

            debugPrint(ranges)
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
            chain.addModification(modification, at: 76)

            let searchParameters = MassSearchParameters(
                searchValue: 689.28, tolerance: MassTolerance(type: .ppm, value: 10),
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

    @Test func averageMassSearch() {
        if let chain = testProtein.chains.first {
            let searchParameters = MassSearchParameters(
                searchValue: 609.71, tolerance: MassTolerance(type: .ppm, value: 10),
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

    @Test func moverzSearchBruteForce() {
        if let chain = testProtein.chains.first {
            let searchParameters = MassSearchParameters(
                searchValue: 890.3877, tolerance: MassTolerance(type: .ppm, value: 10),
                searchType: .sequential, massType: .monoisotopic, charge: 2)

            let peptides: [Peptide] = chain.searchMassBruteForce(params: searchParameters)

            #expect(peptides.contains(where: {
                $0.sequenceString == "TDTSHHDQDHPTFNK"
            }))
            #expect(!peptides.contains(where: {
                $0.sequenceString == "NIFFS"
            }))
        }
    }

    @Test func compareSearchImplementations() {
        if let chain = testProtein.chains.first {
            let searchParameters = MassSearchParameters(
                searchValue: 890.3877, tolerance: MassTolerance(type: .ppm, value: 10),
                searchType: .sequential, massType: .monoisotopic, charge: 2)

            let result1 = measure("Original Brute Force method") {
                let peptides: [Peptide] = chain.searchMassBruteForce(params: searchParameters)
                return peptides.map(\.range)
            }

            let result2 = measure("Sliding Window") {
                let ranges: [Range<Int>] = chain.searchMass(params: searchParameters)
                return ranges
            }

            debugPrint(result1)
            debugPrint(result2)

            #expect(result1 == result2)
        }
    }

    @Test func checkMassDifferences() {
        let peptide = Peptide(sequence: "SAMPLER")
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
