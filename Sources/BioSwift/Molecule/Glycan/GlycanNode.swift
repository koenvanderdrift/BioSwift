import Foundation

public struct GlycanBranch: Codable, Hashable, Sendable {
    public let linkage: GlycosidicLinkage
    public internal(set) var child: GlycanNode

    public init(linkage: GlycosidicLinkage, child: GlycanNode) {
        self.linkage = linkage
        self.child = child
    }
}

public struct GlycanNode: Identifiable, Codable, Sendable {
    public let id: UUID
    public let monosaccharide: Monosaccharide
    public private(set) var branches: [GlycanBranch]

    public init(
        id: UUID = UUID(),
        monosaccharide: Monosaccharide,
        branches: [GlycanBranch] = []
    ) {
        self.id = id
        self.monosaccharide = monosaccharide
        self.branches = branches
    }

    public var isLeaf: Bool { branches.isEmpty }

    var formula: Formula {
        branches.reduce(monosaccharide.formula) {
            $0 + $1.child.formula - water.formula
        }
    }

    var nodesDepthFirst: [GlycanNode] {
        [self] + branches.flatMap { $0.child.nodesDepthFirst }
    }

    var nodesNonReducingToReducing: [GlycanNode] {
        branches.flatMap { $0.child.nodesNonReducingToReducing } + [self]
    }

    var connections: [GlycosidicConnection] {
        branches.flatMap { branch in
            branch.child.connections + [
                GlycosidicConnection(
                    donor: branch.child.monosaccharide,
                    linkage: branch.linkage,
                    acceptor: monosaccharide
                )
            ]
        }
    }

    mutating func add(
        _ child: GlycanNode,
        to parentID: ID,
        linkage: GlycosidicLinkage
    ) throws -> Bool {
        if id == parentID {
            if linkage.acceptorPosition != .unknown,
                branches.contains(where: {
                    $0.linkage.acceptorPosition == linkage.acceptorPosition
                })
            {
                throw BioSwiftDiagnostics.logged(
                    GlycanError.acceptorPositionOccupied(
                        nodeID: id,
                        position: linkage.acceptorPosition
                    )
                )
            }
            branches.append(GlycanBranch(linkage: linkage, child: child))
            return true
        }

        for index in branches.indices {
            if try branches[index].child.add(child, to: parentID, linkage: linkage) {
                return true
            }
        }
        return false
    }
}

extension GlycanNode: Hashable {
    public static func == (lhs: GlycanNode, rhs: GlycanNode) -> Bool {
        lhs.monosaccharide == rhs.monosaccharide && lhs.branches == rhs.branches
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(monosaccharide)
        hasher.combine(branches)
    }
}

public struct GlycosidicConnection: Hashable, Sendable {
    public let donor: Monosaccharide
    public let linkage: GlycosidicLinkage
    public let acceptor: Monosaccharide
}
