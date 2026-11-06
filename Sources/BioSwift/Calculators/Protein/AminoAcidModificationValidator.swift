import Foundation

/// The residue and attachment being checked. Terminal flags describe the residue.
public struct AminoAcidModificationContext: Sendable {
    public enum Attachment: Sendable {
        /// A residue attachment whose chemical location is unspecified.
        case residue
        case sideChain
        case backbone
        case nTerminus
        case cTerminus
    }

    public let attachment: Attachment
    /// The amino acid's one-letter code.
    public let residue: String
    public let isNTerminal: Bool
    public let isCTerminal: Bool
    /// nil means the relationship to the original protein is unknown.
    public let isProteinNTerminal: Bool?
    public let isProteinCTerminal: Bool?

    public init(
        residue: String,
        attachment: Attachment = .residue,
        isNTerminal: Bool = false,
        isCTerminal: Bool = false,
        isProteinNTerminal: Bool? = nil,
        isProteinCTerminal: Bool? = nil
    ) {
        self.residue = residue
        self.attachment = attachment
        self.isNTerminal = isNTerminal
        self.isCTerminal = isCTerminal
        self.isProteinNTerminal = isProteinNTerminal
        self.isProteinCTerminal = isProteinCTerminal
    }
}

public enum ModificationValidation: Equatable, Sendable {
    case allowed
    case rejected(reasons: [String])
}

/// Checks stored site, position, and attachment rules, not broader chemical feasibility.
/// Opt-in validation; existing molecule editing APIs do not call this automatically.
public enum AminoAcidModificationValidator {
    public static func validate(
        _ modification: Modification,
        in context: AminoAcidModificationContext
    ) -> ModificationValidation {
        guard context.residue.count == 1,
              "ACDEFGHIKLMNPQRSTVWYUBZOJX".contains(context.residue) else {
            return .rejected(reasons: ["Requires an amino-acid one-letter code."])
        }
        guard (context.attachment != .nTerminus || context.isNTerminal),
              (context.attachment != .cTerminus || context.isCTerminal),
              (context.isProteinNTerminal != true || context.isNTerminal),
              (context.isProteinCTerminal != true || context.isCTerminal) else {
            return .rejected(reasons: ["The attachment and terminal context are inconsistent."])
        }
        guard !modification.specificities.isEmpty else {
            return .rejected(reasons: ["No attachment rules are available."])
        }

        var reasons: [String] = []
        for specificity in modification.specificities {
            // Both parts of the same rule must match; rules are alternatives.
            guard let reason = rejectionReason(for: specificity, in: context) else {
                return .allowed
            }
            if !reasons.contains(reason) {
                reasons.append(reason)
            }
        }
        return .rejected(reasons: reasons)
    }

    private static func rejectionReason(
        for specificity: ModificationSpecificity,
        in context: AminoAcidModificationContext
    ) -> String? {
        // Preserve source strings in metadata; normalize only when interpreting them.
        // Every supplied constraint must be satisfied. Compound cross-link rules
        // cannot be checked against this single-residue context.
        for value in specificity.attachmentPositions {
            var rule = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if rule.hasSuffix(".") { rule.removeLast() }
            switch rule {
            case "Amino acid side chain":
                guard context.attachment == .sideChain else {
                    return "Requires an explicitly specified side-chain attachment."
                }
            case "Amino acid backbone":
                guard context.attachment == .backbone
                        || context.attachment == .nTerminus
                        || context.attachment == .cTerminus else {
                    return "Requires an explicitly specified backbone attachment."
                }
            default:
                return "Unsupported attachment-position rule: \(value)"
            }
        }
        switch specificity.site {
        case "N-term":
            guard context.attachment == .nTerminus else {
                return "Requires an N-terminal attachment."
            }
        case "C-term", "C-Term":
            guard context.attachment == .cTerminus else {
                return "Requires a C-terminal attachment."
            }
        default:
            guard specificity.site == "X" || specificity.site == context.residue else {
                return "Requires residue \(specificity.site)."
            }
            if specificity.position == "Anywhere", specificity.attachmentPositions.isEmpty,
               context.attachment == .nTerminus || context.attachment == .cTerminus {
                return "Requires a residue attachment."
            }
        }

        // A one-residue peptide has both ends, but their attachment groups differ.
        if context.attachment == .cTerminus,
           ["Any N-term", "Protein N-term"].contains(specificity.position) {
            return "Requires an N-terminal attachment."
        }
        if context.attachment == .nTerminus,
           ["Any C-term", "Protein C-term"].contains(specificity.position) {
            return "Requires a C-terminal attachment."
        }

        switch specificity.position {
        case "Anywhere":
            return nil
        case "Any N-term":
            return context.isNTerminal ? nil : "Requires the peptide's N-terminus."
        case "Any C-term":
            return context.isCTerminal ? nil : "Requires the peptide's C-terminus."
        case "Protein N-term":
            guard context.isNTerminal else {
                return "Requires the protein's N-terminus."
            }
            guard let matches = context.isProteinNTerminal else {
                return "The protein N-terminal context is unknown."
            }
            return matches ? nil : "Requires the protein's N-terminus."
        case "Protein C-term":
            guard context.isCTerminal else {
                return "Requires the protein's C-terminus."
            }
            guard let matches = context.isProteinCTerminal else {
                return "The protein C-terminal context is unknown."
            }
            return matches ? nil : "Requires the protein's C-terminus."
        default:
            return "Unsupported position rule: \(specificity.position)."
        }
    }
}
