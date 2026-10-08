import Foundation

public enum GlycanError: Error, Equatable, Sendable {
    case emptyMonosaccharideSequence
    case invalidLinkageCount(expected: Int, actual: Int)
    case invalidGlycosidicPosition(Int)
}

public struct GlycosidicPosition: Codable, Hashable, Sendable {
    public static let unknown = GlycosidicPosition(number: nil)
    public let number: Int?

    public init(_ number: Int) throws {
        guard number > 0 else {
            throw BioSwiftDiagnostics.logged(GlycanError.invalidGlycosidicPosition(number))
        }
        self.number = number
    }

    private init(number: Int?) {
        self.number = number
    }

    public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            guard let number = try container.decodeIfPresent(Int.self, forKey: .number) else {
                self = .unknown
                return
            }
            try self.init(number)
        } catch let error as GlycanError {
            throw error
        } catch {
            throw BioSwiftDiagnostics.logged(error)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case number
    }
}

/// Bond positions connecting two adjacent monosaccharides.
///
/// Anomeric configuration and ring form belong to the donor monosaccharide
/// and are intentionally not duplicated here.
public struct GlycosidicLinkage: Codable, Hashable, Sendable {
    public let donorPosition: GlycosidicPosition
    public let acceptorPosition: GlycosidicPosition

    public init(donorPosition: GlycosidicPosition, acceptorPosition: GlycosidicPosition) {
        self.donorPosition = donorPosition
        self.acceptorPosition = acceptorPosition
    }

    public init(donorPosition: Int, acceptorPosition: Int) throws {
        self.init(
            donorPosition: try GlycosidicPosition(donorPosition),
            acceptorPosition: try GlycosidicPosition(acceptorPosition)
        )
    }

    public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.init(
                donorPosition: try container.decode(
                    GlycosidicPosition.self,
                    forKey: .donorPosition
                ),
                acceptorPosition: try container.decode(
                    GlycosidicPosition.self,
                    forKey: .acceptorPosition
                )
            )
        } catch let error as GlycanError {
            throw error
        } catch {
            throw BioSwiftDiagnostics.logged(error)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case donorPosition
        case acceptorPosition
    }
}

public struct GlycosidicConnection: Hashable, Sendable {
    public let donor: Monosaccharide
    public let linkage: GlycosidicLinkage
    public let acceptor: Monosaccharide
}

/// A standalone glycan with linear topology.
///
/// Monosaccharides are stored from the non-reducing end to the reducing end.
/// Linkage at index i connects monosaccharide i as donor to i + 1 as acceptor.
public struct Glycan: Structure, Codable, CustomStringConvertible, Hashable, Sendable {
    public var name: String
    public private(set) var monosaccharides: [Monosaccharide]
    public private(set) var linkages: [GlycosidicLinkage]

    private enum CodingKeys: String, CodingKey {
        case name
        case monosaccharides
        case linkages
    }

    public init(monosaccharide: Monosaccharide, name: String = "") {
        self.name = name
        self.monosaccharides = [monosaccharide]
        self.linkages = []
    }

    public init(
        monosaccharides: [Monosaccharide],
        linkages: [GlycosidicLinkage],
        name: String = ""
    ) throws {
        guard monosaccharides.isEmpty == false else {
            throw BioSwiftDiagnostics.logged(GlycanError.emptyMonosaccharideSequence)
        }

        let expected = monosaccharides.count - 1
        guard linkages.count == expected else {
            throw BioSwiftDiagnostics.logged(
                GlycanError.invalidLinkageCount(expected: expected, actual: linkages.count)
            )
        }

        self.name = name
        self.monosaccharides = monosaccharides
        self.linkages = linkages
    }

    public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            try self.init(
                monosaccharides: container.decode(
                    [Monosaccharide].self,
                    forKey: .monosaccharides
                ),
                linkages: container.decode([GlycosidicLinkage].self, forKey: .linkages),
                name: container.decode(String.self, forKey: .name)
            )
        } catch let error as GlycanError {
            throw error
        } catch {
            throw BioSwiftDiagnostics.logged(error)
        }
    }

    public var formula: Formula {
        var result = monosaccharides.reduce(zeroFormula) { $0 + $1.formula }
        for _ in linkages {
            result -= water.formula
        }
        return result
    }

    public var monosaccharideCount: Int { monosaccharides.count }
    public var nonReducingEnd: Monosaccharide { monosaccharides[0] }
    public var reducingEnd: Monosaccharide { monosaccharides[monosaccharides.count - 1] }

    public var composition: [Monosaccharide: Int] {
        monosaccharides.reduce(into: [:]) { $0[$1, default: 0] += 1 }
    }

    public var connections: [GlycosidicConnection] {
        linkages.indices.map { index in
            GlycosidicConnection(
                donor: monosaccharides[index],
                linkage: linkages[index],
                acceptor: monosaccharides[index + 1]
            )
        }
    }

    public subscript(index: Int) -> Monosaccharide { monosaccharides[index] }

    public mutating func appendAtReducingEnd(
        _ monosaccharide: Monosaccharide,
        linkage: GlycosidicLinkage
    ) {
        monosaccharides.append(monosaccharide)
        linkages.append(linkage)
    }

    public mutating func prependAtNonReducingEnd(
        _ monosaccharide: Monosaccharide,
        linkage: GlycosidicLinkage
    ) {
        monosaccharides.insert(monosaccharide, at: 0)
        linkages.insert(linkage, at: 0)
    }

    public func appendingAtReducingEnd(
        _ monosaccharide: Monosaccharide,
        linkage: GlycosidicLinkage
    ) -> Glycan {
        var copy = self
        copy.appendAtReducingEnd(monosaccharide, linkage: linkage)
        return copy
    }

    public func prependingAtNonReducingEnd(
        _ monosaccharide: Monosaccharide,
        linkage: GlycosidicLinkage
    ) -> Glycan {
        var copy = self
        copy.prependAtNonReducingEnd(monosaccharide, linkage: linkage)
        return copy
    }

    public var description: String {
        var result = ""
        for connection in connections {
            result += shortName(for: connection.donor)
            result += "("
            result += anomerSymbol(for: connection.donor.anomer)
            result += positionDescription(connection.linkage.donorPosition)
            result += "→"
            result += positionDescription(connection.linkage.acceptorPosition)
            result += ")"
        }
        result += shortName(for: reducingEnd)
        return result
    }

    private func shortName(for monosaccharide: Monosaccharide) -> String {
        let suffix: String
        switch monosaccharide.ringForm {
        case .furanose: suffix = "f"
        case .pyranose: suffix = "p"
        case .openChain, .unspecified: suffix = ""
        }
        return monosaccharide.abbreviation + suffix
    }

    private func anomerSymbol(for anomer: AnomericConfiguration) -> String {
        switch anomer {
        case .alpha: "α"
        case .beta: "β"
        case .unspecified: "?"
        }
    }

    private func positionDescription(_ position: GlycosidicPosition) -> String {
        position.number.map(String.init) ?? "?"
    }
}
