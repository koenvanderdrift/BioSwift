import Foundation

public enum GlycanIUPACParserError: Error, Equatable, Sendable {
    case emptyInput
    case unknownMonosaccharide(String, position: Int)
    case invalidResidue(String, position: Int)
    case invalidLinkage(String, position: Int)
    case unexpectedToken(position: Int)
    case unbalancedBranch(position: Int)
}

/// Parses IUPAC-condensed and IUPAC-extended glycan notation into rooted glycans.
public struct GlycanIUPACParser: Sendable {
    public static let defaultMonosaccharides: [Monosaccharide] = [
        .glucose, .galactose, .mannose, .fructose, .xylose, .arabinose,
        .ribose, .deoxyribose, .fucose, .nAcetylglucosamine,
        .nAcetylgalactosamine, .nAcetylneuraminicAcid
    ]

    private let monosaccharides: [Monosaccharide]

    public init(monosaccharides: [Monosaccharide] = defaultMonosaccharides) {
        self.monosaccharides = monosaccharides
    }

    public func parse(_ notation: String, name: String = "") throws -> Glycan {
        do {
            let normalized = notation
                .replacingOccurrences(of: "alpha", with: "α", options: .caseInsensitive)
                .replacingOccurrences(of: "beta", with: "β", options: .caseInsensitive)
                .replacingOccurrences(of: "->", with: "→")
            let tokens = try tokenize(normalized)
            guard tokens.isEmpty == false else {
                throw GlycanIUPACParserError.emptyInput
            }
            let root = try parseChain(tokens[...])
            return try Glycan(name: name, root: root)
        } catch {
            throw BioSwiftDiagnostics.logged(error)
        }
    }

    private func tokenize(_ notation: String) throws -> [Token] {
        var tokens: [Token] = []
        var index = notation.startIndex

        while index < notation.endIndex {
            let character = notation[index]
            if character.isWhitespace || character == "-" {
                index = notation.index(after: index)
                continue
            }
            let position = notation.distance(from: notation.startIndex, to: index)
            if character == "[" {
                tokens.append(.openBranch(position))
                index = notation.index(after: index)
                continue
            }
            if character == "]" {
                tokens.append(.closeBranch(position))
                index = notation.index(after: index)
                continue
            }
            if character == "(" {
                guard let close = notation[index...].firstIndex(of: ")") else {
                    throw GlycanIUPACParserError.invalidLinkage(
                        String(notation[index...]), position: position
                    )
                }
                let contentStart = notation.index(after: index)
                let content = String(notation[contentStart..<close])
                tokens.append(.linkage(try parseLinkage(content, position: position), position))
                index = notation.index(after: close)
                continue
            }

            let start = index
            while index < notation.endIndex, !"[](".contains(notation[index]) {
                index = notation.index(after: index)
            }
            let text = String(notation[start..<index]).trimmingCharacters(
                in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "-"))
            )
            guard text.isEmpty == false else {
                throw GlycanIUPACParserError.unexpectedToken(position: position)
            }
            tokens.append(.residue(try parseResidue(text, position: position), position))
        }
        return tokens
    }

    private func parseChain(_ tokens: ArraySlice<Token>) throws -> GlycanNode {
        guard case let .residue(rootResidue, _) = tokens.last else {
            throw GlycanIUPACParserError.unexpectedToken(position: tokens.last?.position ?? 0)
        }

        var root = GlycanNode(monosaccharide: rootResidue)
        var cursor = tokens.index(before: tokens.endIndex)

        while cursor > tokens.startIndex {
            let previous = tokens.index(before: cursor)
            switch tokens[previous] {
            case .closeBranch:
                let open = try matchingOpenBranch(before: previous, in: tokens)
                let donor = try parseDonor(tokens[tokens.index(after: open)..<previous])
                root = adding(donor, to: root)
                cursor = open
            default:
                let donor = try parseDonor(tokens[tokens.startIndex..<cursor])
                root = adding(donor, to: root)
                cursor = tokens.startIndex
            }
        }
        return root
    }

    private func parseDonor(
        _ tokens: ArraySlice<Token>
    ) throws -> (node: GlycanNode, linkage: GlycosidicLinkage) {
        guard case let .linkage(parsedLinkage, _) = tokens.last else {
            throw GlycanIUPACParserError.unexpectedToken(position: tokens.last?.position ?? 0)
        }
        let chainTokens = tokens.dropLast()
        guard chainTokens.isEmpty == false else {
            throw GlycanIUPACParserError.unexpectedToken(position: tokens.last?.position ?? 0)
        }
        var node = try parseChain(chainTokens)
        if parsedLinkage.anomer != .unspecified {
            node = replacingRootAnomer(of: node, with: parsedLinkage.anomer)
        }
        return (node, parsedLinkage.linkage)
    }

    private func matchingOpenBranch(
        before close: ArraySlice<Token>.Index,
        in tokens: ArraySlice<Token>
    ) throws -> ArraySlice<Token>.Index {
        var depth = 1
        var index = close
        while index > tokens.startIndex {
            index = tokens.index(before: index)
            switch tokens[index] {
            case .closeBranch: depth += 1
            case .openBranch:
                depth -= 1
                if depth == 0 { return index }
            default: break
            }
        }
        throw GlycanIUPACParserError.unbalancedBranch(position: tokens[close].position)
    }

    private func adding(
        _ donor: (node: GlycanNode, linkage: GlycosidicLinkage),
        to root: GlycanNode
    ) -> GlycanNode {
        GlycanNode(
            id: root.id,
            monosaccharide: root.monosaccharide,
            branches: root.branches + [GlycanBranch(linkage: donor.linkage, child: donor.node)]
        )
    }

    private func replacingRootAnomer(
        of node: GlycanNode,
        with anomer: AnomericConfiguration
    ) -> GlycanNode {
        GlycanNode(
            id: node.id,
            monosaccharide: copy(node.monosaccharide, anomer: anomer),
            branches: node.branches
        )
    }

    private func parseResidue(_ text: String, position: Int) throws -> Monosaccharide {
        var components = text.split(separator: "-").map(String.init)
        var anomer = AnomericConfiguration.unspecified
        var configuration = MonosaccharideConfiguration.unspecified

        if let first = components.first, let parsed = parseAnomer(first) {
            anomer = parsed
            components.removeFirst()
        }
        if let first = components.first, first.uppercased() == "D" || first.uppercased() == "L" {
            configuration = first.uppercased() == "D" ? .d : .l
            components.removeFirst()
        }
        guard components.count == 1 else {
            throw GlycanIUPACParserError.invalidResidue(text, position: position)
        }

        var identifier = components[0]
        var ringForm = MonosaccharideRingForm.pyranose
        if identifier.hasSuffix("p") {
            identifier.removeLast()
        } else if identifier.hasSuffix("f") {
            identifier.removeLast()
            ringForm = .furanose
        }

        guard let base = monosaccharides.first(where: {
            $0.abbreviation.caseInsensitiveCompare(identifier) == .orderedSame
        }) else {
            throw GlycanIUPACParserError.unknownMonosaccharide(identifier, position: position)
        }
        if configuration == .unspecified { configuration = base.configuration }
        return copy(base, configuration: configuration, anomer: anomer, ringForm: ringForm)
    }

    private func parseLinkage(_ text: String, position: Int) throws -> ParsedLinkage {
        let compact = text.replacingOccurrences(of: " ", with: "")
        var index = compact.startIndex
        var anomer = AnomericConfiguration.unspecified
        if index < compact.endIndex,
           let parsed = parseAnomer(String(compact[index])) {
            anomer = parsed
            index = compact.index(after: index)
        }
        let arrowParts = compact[index...].split(separator: "→", omittingEmptySubsequences: false)
        let hyphenParts = compact[index...].split(separator: "-", omittingEmptySubsequences: false)
        let parts = arrowParts.count == 2 ? arrowParts : hyphenParts
        guard parts.count == 2,
              let donor = parsePosition(String(parts[0])),
              let acceptor = parsePosition(String(parts[1])) else {
            throw GlycanIUPACParserError.invalidLinkage(text, position: position)
        }
        return ParsedLinkage(
            linkage: GlycosidicLinkage(donorPosition: donor, acceptorPosition: acceptor),
            anomer: anomer
        )
    }

    private func parsePosition(_ text: String) -> GlycosidicPosition? {
        if text == "?" { return .unknown }
        guard let number = Int(text), number > 0 else { return nil }
        return try? GlycosidicPosition(number)
    }

    private func parseAnomer(_ text: String) -> AnomericConfiguration? {
        switch text.lowercased() {
        case "a", "α": .alpha
        case "b", "β": .beta
        case "?": .unspecified
        default: nil
        }
    }

    private func copy(
        _ monosaccharide: Monosaccharide,
        configuration: MonosaccharideConfiguration? = nil,
        anomer: AnomericConfiguration? = nil,
        ringForm: MonosaccharideRingForm? = nil
    ) -> Monosaccharide {
        Monosaccharide(
            name: monosaccharide.name,
            abbreviation: monosaccharide.abbreviation,
            formula: monosaccharide.formula,
            type: monosaccharide.type,
            carbonylType: monosaccharide.carbonylType,
            configuration: configuration ?? monosaccharide.configuration,
            anomer: anomer ?? monosaccharide.anomer,
            ringForm: ringForm ?? monosaccharide.ringForm
        )
    }
}

private extension GlycanIUPACParser {
    enum Token: Sendable {
        case residue(Monosaccharide, Int)
        case linkage(ParsedLinkage, Int)
        case openBranch(Int)
        case closeBranch(Int)

        var position: Int {
            switch self {
            case let .residue(_, position), let .linkage(_, position),
                 let .openBranch(position), let .closeBranch(position):
                position
            }
        }
    }

    struct ParsedLinkage: Sendable {
        let linkage: GlycosidicLinkage
        let anomer: AnomericConfiguration
    }
}
