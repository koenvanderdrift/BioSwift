import Foundation

public enum GlycanError: Error, Equatable, Sendable {
    case emptyMonosaccharideSequence
    case invalidLinkageCount(expected: Int, actual: Int)
    case invalidGlycosidicPosition(Int)
    case duplicateNodeID(UUID)
    case nodeNotFound(UUID)
    case acceptorPositionOccupied(nodeID: UUID, position: GlycosidicPosition)
    case nonReducingEndIsBranched
}
