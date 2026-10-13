import BioSwift
import Foundation
import Testing
@testable import BioSwiftNetworking

@Suite("NCBI BLAST web request")
struct NCBIBLASTWebRequestTests {
    @Test("Every BLAST program produces its corresponding web form", arguments: BLASTProgram.allCases)
    func programs(program: BLASTProgram) throws {
        let request = try NCBIBLASTWebRequest(
            query: BLASTQuery(identifier: "example", sequence: "ACGT"),
            configuration: BLASTConfiguration(program: program, database: "test_database")
        )
        let fields = queryFields(request.url)

        #expect(request.url.host == "blast.ncbi.nlm.nih.gov")
        #expect(request.url.path == "/Blast.cgi")
        #expect(fields["PAGE_TYPE"] == "BlastSearch")
        #expect(fields["PROGRAM"] == program.rawValue)
        #expect(fields["BLAST_PROGRAMS"] == program.rawValue)
        #expect(fields["QUERY"] == ">example\nACGT")
        #expect(fields["DATABASE"] == "test_database")
        #expect(fields["JOB_TITLE"] == "example")
    }

    @Test("Protein options are encoded into the editable NCBI form")
    func proteinOptions() throws {
        let request = try NCBIBLASTWebRequest(
            query: BLASTQuery(identifier: "protein\nquery", sequence: "MPEPTIDE"),
            configuration: BLASTConfiguration(
                program: .blastp,
                database: "swissprot",
                expectationValue: 0.001,
                maximumHits: 10,
                filtersLowComplexityRegions: false,
                substitutionMatrix: "BLOSUM62",
                wordSize: 3,
                adjustsForShortQuery: true
            )
        )
        let fields = queryFields(request.url)

        #expect(fields["PAGE"] == "Proteins")
        #expect(fields["QUERY"] == ">protein query\nMPEPTIDE")
        #expect(fields["EXPECT"] == "0.001")
        #expect(fields["HITLIST_SIZE"] == "10")
        #expect(fields["FILTER"] == "F")
        #expect(fields["MATRIX"] == "BLOSUM62")
        #expect(fields["WORD_SIZE"] == "3")
        #expect(fields["SHORT_QUERY_ADJUST"] == "true")
    }

    @Test("Nucleotide scoring options are encoded")
    func nucleotideOptions() throws {
        let request = try NCBIBLASTWebRequest(
            query: BLASTQuery(sequence: "ACGT"),
            configuration: BLASTConfiguration(
                program: .blastn,
                database: "core_nt",
                nucleotideMatchReward: 2,
                nucleotideMismatchPenalty: -3
            )
        )
        let fields = queryFields(request.url)

        #expect(fields["PAGE"] == "Nucleotides")
        #expect(fields["NUCL_REWARD"] == "2")
        #expect(fields["NUCL_PENALTY"] == "-3")
        #expect(fields["JOB_TITLE"] == nil)
    }

    @Test("Translated programs open the translated search page", arguments: [
        BLASTProgram.blastx, .tblastn, .tblastx,
    ])
    func translatedPage(program: BLASTProgram) throws {
        let request = try NCBIBLASTWebRequest(
            query: BLASTQuery(sequence: "ACGT"),
            configuration: BLASTConfiguration(program: program, database: "database")
        )
        #expect(queryFields(request.url)["PAGE"] == "Translations")
    }

    @Test("Oversized browser URLs are rejected")
    func oversizedURL() throws {
        let query = try BLASTQuery(
            sequence: String(repeating: "A", count: NCBIBLASTWebRequest.maximumURLLength)
        )
        let configuration = try BLASTConfiguration(program: .blastn, database: "core_nt")

        #expect(throws: NCBIBLASTWebRequestError.self) {
            try NCBIBLASTWebRequest(query: query, configuration: configuration)
        }
    }

    private func queryFields(_ url: URL) -> [String: String] {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        return Dictionary(
            items.compactMap { item in item.value.map { (item.name, $0) } },
            uniquingKeysWith: { _, latest in latest }
        )
    }
}
