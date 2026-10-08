import Foundation

extension Glycan {
    /// An IUPAC-condensed representation, ordered from non-reducing to reducing end.
    ///
    /// Common configurations and pyranose ring forms are implicit. Branches are enclosed
    /// in square brackets and linkage positions use ASCII characters, for example
    /// `Man(a1-3)[Man(a1-6)]Man`.
    public var iupacCondensed: String {
        iupacCondensed(node: root)
    }

    /// An IUPAC-extended representation, ordered from non-reducing to reducing end.
    ///
    /// Configuration and ring form are included when known, for example
    /// `α-D-Manp-(1→3)-[α-D-Manp-(1→6)]-D-Manp`.
    public var iupacExtended: String {
        iupacExtended(node: root, isReducingEnd: true)
    }

    private func iupacCondensed(node: GlycanNode) -> String {
        format(
            node: node,
            residue: { $0.abbreviation },
            linkage: { branch in
                "(" + condensedAnomer(branch.child.monosaccharide.anomer)
                    + position(branch.linkage.donorPosition)
                    + "-" + position(branch.linkage.acceptorPosition) + ")"
            }
        )
    }

    private func iupacExtended(node: GlycanNode, isReducingEnd: Bool) -> String {
        let branches = orderedBranches(of: node)
        guard let mainChain = branches.first else {
            return extendedResidue(node.monosaccharide, includeAnomer: !isReducingEnd)
        }

        var result = iupacExtended(node: mainChain.child, isReducingEnd: false)
            + extendedLinkage(mainChain)
        for branch in branches.dropFirst() {
            result += "[" + iupacExtended(node: branch.child, isReducingEnd: false)
                + extendedLinkage(branch, trailingSeparator: false) + "]-"
        }
        return result + extendedResidue(node.monosaccharide, includeAnomer: !isReducingEnd)
    }

    private func format(
        node: GlycanNode,
        residue: (Monosaccharide) -> String,
        linkage: (GlycanBranch) -> String
    ) -> String {
        let branches = orderedBranches(of: node)
        guard let mainChain = branches.first else {
            return residue(node.monosaccharide)
        }

        var result = format(node: mainChain.child, residue: residue, linkage: linkage)
            + linkage(mainChain)
        for branch in branches.dropFirst() {
            result += "[" + format(node: branch.child, residue: residue, linkage: linkage)
                + linkage(branch) + "]"
        }
        return result + residue(node.monosaccharide)
    }

    private func orderedBranches(of node: GlycanNode) -> [GlycanBranch] {
        node.branches.sorted {
            ($0.linkage.acceptorPosition.number ?? Int.max)
                < ($1.linkage.acceptorPosition.number ?? Int.max)
        }
    }

    private func extendedResidue(
        _ monosaccharide: Monosaccharide,
        includeAnomer: Bool
    ) -> String {
        var components: [String] = []
        if includeAnomer, let symbol = monosaccharide.anomer.iupacSymbol {
            components.append(symbol)
        }
        if monosaccharide.configuration != .unspecified {
            components.append(monosaccharide.configuration.rawValue.uppercased())
        }

        var abbreviation = monosaccharide.abbreviation
        switch monosaccharide.ringForm {
        case .furanose: abbreviation += "f"
        case .pyranose: abbreviation += "p"
        case .openChain, .unspecified: break
        }
        components.append(abbreviation)
        return components.joined(separator: "-")
    }

    private func extendedLinkage(
        _ branch: GlycanBranch,
        trailingSeparator: Bool = true
    ) -> String {
        "-(" + position(branch.linkage.donorPosition)
            + "→" + position(branch.linkage.acceptorPosition) + ")"
            + (trailingSeparator ? "-" : "")
    }

    private func condensedAnomer(_ anomer: AnomericConfiguration) -> String {
        switch anomer {
        case .alpha: "a"
        case .beta: "b"
        case .unspecified: "?"
        }
    }

    private func position(_ position: GlycosidicPosition) -> String {
        position.number.map(String.init) ?? "?"
    }
}

private extension AnomericConfiguration {
    var iupacSymbol: String? {
        switch self {
        case .alpha: "α"
        case .beta: "β"
        case .unspecified: nil
        }
    }
}
