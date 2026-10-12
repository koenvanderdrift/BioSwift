//
//  NCBIBLASTResponse.swift
//  BioSwiftNetworking
//

import BioSwift
import Foundation

struct NCBIBLASTResponseDecoder {
    func decode(
        _ data: Data,
        query: BLASTQuery,
        configuration: BLASTConfiguration
    ) throws -> BLASTResult {
        let output: NCBIOutput
        do {
            output = try JSONDecoder().decode(NCBIEnvelope.self, from: data).output.first
                .unwrapped(or: NCBIBLASTError.malformedResult("The JSON2 result is empty."))
        } catch let error as NCBIBLASTError {
            throw error
        } catch {
            throw NCBIBLASTError.malformedResult(error.localizedDescription)
        }

        if let error = output.error {
            throw NCBIBLASTError.searchFailed(error.message)
        }
        guard let report = output.report else {
            throw NCBIBLASTError.malformedResult("The JSON2 result contains no report.")
        }
        guard let program = BLASTProgram(rawValue: report.program.lowercased()) else {
            throw NCBIBLASTError.malformedResult("Unknown BLAST program: \(report.program)")
        }

        let hits = try (report.results.search.hits ?? []).map { hit in
            guard let description = hit.description.first else {
                throw NCBIBLASTError.malformedResult("A BLAST hit has no description.")
            }
            return try BLASTHit(
                identifier: description.id,
                accession: description.accession,
                definition: description.title,
                sequenceLength: hit.length,
                highScoringPairs: try (hit.hsps ?? []).map {
                    try highScoringPair($0, program: program)
                }
            )
        }

        return BLASTResult(
            program: program,
            database: report.searchTarget.database ?? configuration.database,
            query: query,
            hits: hits
        )
    }

    private func highScoringPair(
        _ pair: NCBIHSP,
        program: BLASTProgram
    ) throws -> BLASTHighScoringPair {
        let rawScore = pair.score.rounded()
        guard rawScore == pair.score,
            rawScore >= Double(Int.min), rawScore <= Double(Int.max)
        else {
            throw NCBIBLASTError.malformedResult("A raw score is not an integer.")
        }

        let queryCoordinates = try coordinates(from: pair.queryFrom, to: pair.queryTo)
        let subjectCoordinates = try coordinates(from: pair.hitFrom, to: pair.hitTo)
        let identityCount = pair.identity ?? 0

        return try BLASTHighScoringPair(
            rawScore: Int(rawScore),
            bitScore: pair.bitScore,
            expectationValue: pair.expectationValue,
            queryRange: queryCoordinates.range,
            subjectRange: subjectCoordinates.range,
            querySequence: pair.querySequence,
            subjectSequence: pair.hitSequence,
            identityCount: identityCount,
            positiveCount: pair.positive ?? identityCount,
            gapCount: pair.gaps ?? 0,
            queryStrand: strand(pair.queryStrand)
                ?? (program == .blastn ? queryCoordinates.strand : nil),
            subjectStrand: strand(pair.hitStrand)
                ?? (program == .blastn ? subjectCoordinates.strand : nil),
            queryFrame: pair.queryFrame,
            subjectFrame: pair.hitFrame
        )
    }

    private func coordinates(
        from: Int,
        to: Int
    ) throws -> (range: Range<Int>, strand: BLASTStrand) {
        let lowerBound = min(from, to)
        let upperBound = max(from, to)
        guard let biologicalRange = BiologicalRange(validating: lowerBound...upperBound) else {
            throw NCBIBLASTError.malformedResult("Invalid coordinates: \(from)...\(to)")
        }
        return (
            biologicalRange.zeroBasedRange,
            from <= to ? .plus : .minus
        )
    }

    private func strand(_ value: String?) -> BLASTStrand? {
        value.flatMap { BLASTStrand(rawValue: $0.lowercased()) }
    }
}

private struct NCBIEnvelope: Decodable {
    let output: [NCBIOutput]

    private enum CodingKeys: String, CodingKey {
        case output = "BlastOutput2"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let single = try? container.decode(NCBIOutput.self, forKey: .output) {
            output = [single]
        } else {
            output = try container.decode([NCBIOutput].self, forKey: .output)
        }
    }
}

private struct NCBIOutput: Decodable {
    let report: NCBIReport?
    let error: NCBIError?
}

private struct NCBIError: Decodable {
    let code: Int
    let message: String?
}

private struct NCBIReport: Decodable {
    let program: String
    let searchTarget: NCBISearchTarget
    let results: NCBIResults

    private enum CodingKeys: String, CodingKey {
        case program
        case searchTarget = "search_target"
        case results
    }
}

private struct NCBISearchTarget: Decodable {
    let database: String?

    private enum CodingKeys: String, CodingKey {
        case database = "db"
    }
}

private struct NCBIResults: Decodable {
    let search: NCBISearch
}

private struct NCBISearch: Decodable {
    let hits: [NCBIHit]?
}

private struct NCBIHit: Decodable {
    let description: [NCBIHitDescription]
    let length: Int
    let hsps: [NCBIHSP]?

    private enum CodingKeys: String, CodingKey {
        case description
        case length = "len"
        case hsps
    }
}

private struct NCBIHitDescription: Decodable {
    let id: String
    let accession: String?
    let title: String?
}

private struct NCBIHSP: Decodable {
    let bitScore: Double
    let score: Double
    let expectationValue: Double
    let identity: Int?
    let positive: Int?
    let gaps: Int?
    let queryFrom: Int
    let queryTo: Int
    let hitFrom: Int
    let hitTo: Int
    let queryStrand: String?
    let hitStrand: String?
    let queryFrame: Int?
    let hitFrame: Int?
    let querySequence: String
    let hitSequence: String

    private enum CodingKeys: String, CodingKey {
        case bitScore = "bit_score"
        case score
        case expectationValue = "evalue"
        case identity
        case positive
        case gaps
        case queryFrom = "query_from"
        case queryTo = "query_to"
        case hitFrom = "hit_from"
        case hitTo = "hit_to"
        case queryStrand = "query_strand"
        case hitStrand = "hit_strand"
        case queryFrame = "query_frame"
        case hitFrame = "hit_frame"
        case querySequence = "qseq"
        case hitSequence = "hseq"
    }
}

private extension Optional {
    func unwrapped(or error: @autoclosure () -> Error) throws -> Wrapped {
        guard let self else { throw error() }
        return self
    }
}
