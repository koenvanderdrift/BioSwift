import Foundation

/// A finite glycan rooted at its reducing-end or attachment-proximal monosaccharide.
///
/// Children extend away from the root toward non-reducing ends.
public struct Glycan: Structure, Codable, CustomStringConvertible, Hashable, Sendable {
    public var name: String
    public private(set) var root: GlycanNode

    private enum CodingKeys: String, CodingKey {
        case name
        case root
    }

    public init(monosaccharide: Monosaccharide, name: String = "") {
        self.name = name
        self.root = GlycanNode(monosaccharide: monosaccharide)
    }

    public init(name: String = "", root: GlycanNode) throws {
        self.name = name
        self.root = root
        try validate()
    }

    /// Builds a linear tree from conventional non-reducing-to-reducing arrays.
    public init(
        monosaccharides: [Monosaccharide],
        linkages: [GlycosidicLinkage],
        name: String = ""
    ) throws {
        guard let reducingEnd = monosaccharides.last else {
            throw BioSwiftDiagnostics.logged(GlycanError.emptyMonosaccharideSequence)
        }
        let expected = monosaccharides.count - 1
        guard linkages.count == expected else {
            throw BioSwiftDiagnostics.logged(
                GlycanError.invalidLinkageCount(expected: expected, actual: linkages.count)
            )
        }

        self.init(monosaccharide: reducingEnd, name: name)
        var parentID = root.id
        if monosaccharides.count > 1 {
            for index in stride(from: monosaccharides.count - 2, through: 0, by: -1) {
                parentID = try add(
                    monosaccharides[index],
                    to: parentID,
                    linkage: linkages[index]
                )
            }
        }
    }

    public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            try self.init(
                name: container.decode(String.self, forKey: .name),
                root: container.decode(GlycanNode.self, forKey: .root)
            )
        } catch let error as GlycanError {
            throw error
        } catch {
            throw BioSwiftDiagnostics.loggedDecodingFailure(error, from: decoder)
        }
    }

    public var formula: Formula { root.formula }
    public var nodes: [GlycanNode] { root.nodesDepthFirst }
    public var monosaccharides: [Monosaccharide] {
        root.nodesNonReducingToReducing.map(\.monosaccharide)
    }
    public var linkages: [GlycosidicLinkage] { connections.map(\.linkage) }
    public var connections: [GlycosidicConnection] { root.connections }
    public var monosaccharideCount: Int { nodes.count }
    public var reducingEnd: Monosaccharide { root.monosaccharide }
    public var nonReducingEnds: [Monosaccharide] {
        nodes.filter(\.isLeaf).map(\.monosaccharide)
    }
    public var nonReducingEnd: Monosaccharide { nonReducingEnds[0] }

    public var composition: [Monosaccharide: Int] {
        nodes.reduce(into: [:]) { $0[$1.monosaccharide, default: 0] += 1 }
    }

    public subscript(index: Int) -> Monosaccharide { monosaccharides[index] }

    public func node(id: GlycanNode.ID) -> GlycanNode? {
        nodes.first { $0.id == id }
    }

    @discardableResult
    public mutating func add(
        _ monosaccharide: Monosaccharide,
        to parentID: GlycanNode.ID,
        linkage: GlycosidicLinkage,
        id: GlycanNode.ID = UUID()
    ) throws -> GlycanNode.ID {
        let child = GlycanNode(id: id, monosaccharide: monosaccharide)
        guard try root.add(child, to: parentID, linkage: linkage) else {
            throw BioSwiftDiagnostics.logged(GlycanError.nodeNotFound(parentID))
        }
        return id
    }

    public mutating func appendAtReducingEnd(
        _ monosaccharide: Monosaccharide,
        linkage: GlycosidicLinkage
    ) {
        root = GlycanNode(
            monosaccharide: monosaccharide,
            branches: [GlycanBranch(linkage: linkage, child: root)]
        )
    }

    public mutating func prependAtNonReducingEnd(
        _ monosaccharide: Monosaccharide,
        linkage: GlycosidicLinkage
    ) throws {
        let leaves = nodes.filter(\.isLeaf)
        guard leaves.count == 1, let leaf = leaves.first else {
            throw BioSwiftDiagnostics.logged(GlycanError.nonReducingEndIsBranched)
        }
        try add(monosaccharide, to: leaf.id, linkage: linkage)
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
    ) throws -> Glycan {
        var copy = self
        try copy.prependAtNonReducingEnd(monosaccharide, linkage: linkage)
        return copy
    }

    public var description: String { describe(root) }

    private func describe(_ node: GlycanNode) -> String {
        guard let first = node.branches.first else {
            return shortName(for: node.monosaccharide)
        }

        var result = describe(first.child) + linkageDescription(first)
        for branch in node.branches.dropFirst() {
            result += "[" + describe(branch.child) + linkageDescription(branch) + "]"
        }
        return result + shortName(for: node.monosaccharide)
    }

    private func linkageDescription(_ branch: GlycanBranch) -> String {
        "(" + anomerSymbol(for: branch.child.monosaccharide.anomer)
            + positionDescription(branch.linkage.donorPosition)
            + "→" + positionDescription(branch.linkage.acceptorPosition) + ")"
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

    private func validate() throws {
        try root.validate()
    }
}

