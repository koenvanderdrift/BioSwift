//
//  Nucleotide.swift
//  BioSwift
//

import Foundation

public enum NucleicAcidType: String, Codable, Sendable {
    case dna = "DNA"
    case rna = "RNA"
}

/// Nucleotide conforms to the ``Residue`` protocol.
public struct Nucleotide: Residue, Codable, Sendable {
    public let formula: Formula
    public let name: String
    public let oneLetterCode: String
    public let threeLetterCode: String
    public let represents: [String]
    public let representedBy: [String]
    public let nucleicAcidType: NucleicAcidType

    public var modification: Modification?
    public var adducts: [Adduct]

    public init(
        name: String,
        oneLetterCode: String,
        threeLetterCode: String = "",
        formula: Formula,
        nucleicAcidType: NucleicAcidType,
        represents: [String] = [],
        representedBy: [String] = []
    ) {
        self.name = name
        self.oneLetterCode = oneLetterCode
        self.threeLetterCode = threeLetterCode
        self.formula = formula
        self.nucleicAcidType = nucleicAcidType
        self.represents = represents
        self.representedBy = representedBy
        self.adducts = []
    }

    public init(
        name: String,
        oneLetterCode: String,
        threeLetterCode: String = "",
        elements: [String: Int],
        nucleicAcidType: NucleicAcidType
    ) throws {
        self.init(
            name: name,
            oneLetterCode: oneLetterCode,
            threeLetterCode: threeLetterCode,
            formula: try Formula(elements: elements),
            nucleicAcidType: nucleicAcidType
        )
    }

    public var complement: Nucleotide {
        guard let complementCode else { return self }
        return Self.standard(code: complementCode, type: nucleicAcidType) ?? self
    }

    private var complementCode: Character? {
        switch (nucleicAcidType, oneLetterCode) {
        case (.dna, "A"): return "T"
        case (.dna, "T"): return "A"
        case (.rna, "A"): return "U"
        case (.rna, "U"): return "A"
        case (_, "C"): return "G"
        case (_, "G"): return "C"
        default: return nil
        }
    }

    static func standard(code: Character, type: NucleicAcidType) -> Nucleotide? {
        do {
            switch (type, code.uppercased()) {
            case (.dna, "A"): return Nucleotide(name: "Adenine", oneLetterCode: "A", threeLetterCode: "dAMP", formula: try Formula("C10H12N5O5P"), nucleicAcidType: .dna)
            case (.dna, "T"): return Nucleotide(name: "Thymine", oneLetterCode: "T", threeLetterCode: "dTMP", formula: try Formula("C10H13N2O7P"), nucleicAcidType: .dna)
            case (.dna, "C"): return Nucleotide(name: "Cytosine", oneLetterCode: "C", threeLetterCode: "dCMP", formula: try Formula("C9H12N3O6P"), nucleicAcidType: .dna)
            case (.dna, "G"): return Nucleotide(name: "Guanine", oneLetterCode: "G", threeLetterCode: "dGMP", formula: try Formula("C10H12N5O6P"), nucleicAcidType: .dna)
            case (.rna, "A"): return Nucleotide(name: "Adenine", oneLetterCode: "A", threeLetterCode: "AMP", formula: try Formula("C10H12N5O6P"), nucleicAcidType: .rna)
            case (.rna, "U"): return Nucleotide(name: "Uracil", oneLetterCode: "U", threeLetterCode: "UMP", formula: try Formula("C9H11N2O8P"), nucleicAcidType: .rna)
            case (.rna, "C"): return Nucleotide(name: "Cytosine", oneLetterCode: "C", threeLetterCode: "CMP", formula: try Formula("C9H12N3O7P"), nucleicAcidType: .rna)
            case (.rna, "G"): return Nucleotide(name: "Guanine", oneLetterCode: "G", threeLetterCode: "GMP", formula: try Formula("C10H12N5O7P"), nucleicAcidType: .rna)
            default: return nil
            }
        } catch {
            preconditionFailure("Invalid built-in nucleotide formula: \(error)")
        }
    }
}
