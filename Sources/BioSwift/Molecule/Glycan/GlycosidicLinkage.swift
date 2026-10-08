import Foundation

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

/// A bond from a child donor carbon to an acceptor carbon on its parent.
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
