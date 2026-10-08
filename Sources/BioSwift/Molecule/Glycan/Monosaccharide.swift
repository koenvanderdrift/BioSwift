//
//  Monosaccharide.swift
//  BioSwift
//

import Foundation

/// The type and position of the carbonyl group in a monosaccharide's open-chain form.
public enum MonosaccharideCarbonylType: String, Codable, Hashable, Sendable {
    case aldose
    case ketose
    case unspecified
}

public enum AnomericConfiguration: String, Codable, Hashable, Sendable {
    case alpha
    case beta
    case unspecified

    fileprivate var symbol: String? {
        switch self {
        case .alpha: "α"
        case .beta: "β"
        case .unspecified: nil
        }
    }
}

public enum MonosaccharideRingForm: String, Codable, Hashable, Sendable {
    case furanose
    case pyranose
    case openChain
    case unspecified
}

/// Classification based on the number of carbon atoms in the monosaccharide backbone.
public enum MonosaccharideType: String, Codable, Hashable, Sendable {
    case triose
    case tetrose
    case pentose
    case hexose
    case heptose
    case octose
    case nonose
}

/// The relative configuration assigned from the highest-numbered stereocenter.
public enum MonosaccharideConfiguration: String, Codable, Hashable, Sendable {
    case d
    case l
    case unspecified
}

/// A single sugar identified independently from its elemental composition.
///
/// Stereoisomers can have the same formula and broad classification while remaining
/// distinct monosaccharides. For example, glucose, galactose, and mannose are all
/// D-aldohexoses with the formula C6H12O6.
public struct Monosaccharide: Structure, Codable, CustomStringConvertible, Sendable {
    public let name: String
    public let abbreviation: String
    public let formula: Formula
    public let type: MonosaccharideType
    public let carbonylType: MonosaccharideCarbonylType
    public let configuration: MonosaccharideConfiguration
    public let anomer: AnomericConfiguration
    public let ringForm: MonosaccharideRingForm

    private enum CodingKeys: String, CodingKey {
        case name
        case abbreviation
        case formula
        case type
        case carbonylType
        case configuration
        case anomer
        case ringForm
    }

    public init(
        name: String,
        abbreviation: String,
        formula: Formula,
        type: MonosaccharideType,
        carbonylType: MonosaccharideCarbonylType,
        configuration: MonosaccharideConfiguration = .unspecified,
        anomer: AnomericConfiguration = .unspecified,
        ringForm: MonosaccharideRingForm = .unspecified
    ) {
        self.name = name
        self.abbreviation = abbreviation
        self.formula = formula
        self.type = type
        self.carbonylType = carbonylType
        self.configuration = configuration
        self.anomer = anomer
        self.ringForm = ringForm
    }

    public init(
        name: String,
        abbreviation: String,
        formula: String,
        type: MonosaccharideType,
        carbonylType: MonosaccharideCarbonylType,
        configuration: MonosaccharideConfiguration = .unspecified,
        anomer: AnomericConfiguration = .unspecified,
        ringForm: MonosaccharideRingForm = .unspecified
    ) throws {
        self.init(
            name: name,
            abbreviation: abbreviation,
            formula: try Formula(formula),
            type: type,
            carbonylType: carbonylType,
            configuration: configuration,
            anomer: anomer,
            ringForm: ringForm
        )
    }

    public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.init(
                name: try container.decode(String.self, forKey: .name),
                abbreviation: try container.decode(String.self, forKey: .abbreviation),
                formula: try container.decode(Formula.self, forKey: .formula),
                type: try container.decode(MonosaccharideType.self, forKey: .type),
                carbonylType: try container.decode(
                    MonosaccharideCarbonylType.self,
                    forKey: .carbonylType
                ),
                configuration: try container.decode(
                    MonosaccharideConfiguration.self,
                    forKey: .configuration
                ),
                anomer: try container.decode(AnomericConfiguration.self, forKey: .anomer),
                ringForm: try container.decode(MonosaccharideRingForm.self, forKey: .ringForm)
            )
        } catch {
            throw BioSwiftDiagnostics.loggedDecodingFailure(error, from: decoder)
        }
    }

    public var description: String {
        let configurationPrefix = configuration == .unspecified
            ? ""
            : "\(configuration.rawValue.uppercased())-"

        guard ringForm == .furanose || ringForm == .pyranose else {
            return configurationPrefix + name
        }

        let anomerPrefix = anomer.symbol.map { "\($0)-" } ?? ""
        let cyclicName: String
        if name.hasSuffix("ose") {
            cyclicName = String(name.dropLast(2)) + ringForm.rawValue
        } else {
            cyclicName = name + " " + ringForm.rawValue
        }

        return anomerPrefix + configurationPrefix + cyclicName
    }

    public func form(
        anomer: AnomericConfiguration,
        ring: MonosaccharideRingForm
    ) -> Monosaccharide {
        Monosaccharide(
            name: name,
            abbreviation: abbreviation,
            formula: formula,
            type: type,
            carbonylType: carbonylType,
            configuration: configuration,
            anomer: anomer,
            ringForm: ring
        )
    }
}

extension Monosaccharide: Hashable {
    public static func == (lhs: Monosaccharide, rhs: Monosaccharide) -> Bool {
        lhs.name == rhs.name
            && lhs.abbreviation == rhs.abbreviation
            && lhs.formula == rhs.formula
            && lhs.type == rhs.type
            && lhs.carbonylType == rhs.carbonylType
            && lhs.configuration == rhs.configuration
            && lhs.anomer == rhs.anomer
            && lhs.ringForm == rhs.ringForm
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(abbreviation)
        hasher.combine(formula.formulaString)
        hasher.combine(type)
        hasher.combine(carbonylType)
        hasher.combine(configuration)
        hasher.combine(anomer)
        hasher.combine(ringForm)
    }
}

extension Monosaccharide {
    public static let glucose = builtIn(
        name: "Glucose", abbreviation: "Glc", formula: "C6H12O6",
        type: .hexose, carbonylType: .aldose, configuration: .d
    )

    public static let galactose = builtIn(
        name: "Galactose", abbreviation: "Gal", formula: "C6H12O6",
        type: .hexose, carbonylType: .aldose, configuration: .d
    )

    public static let mannose = builtIn(
        name: "Mannose", abbreviation: "Man", formula: "C6H12O6",
        type: .hexose, carbonylType: .aldose, configuration: .d
    )

    public static let fructose = builtIn(
        name: "Fructose", abbreviation: "Fru", formula: "C6H12O6",
        type: .hexose, carbonylType: .ketose, configuration: .d
    )

    public static let xylose = builtIn(
        name: "Xylose", abbreviation: "Xyl", formula: "C5H10O5",
        type: .pentose, carbonylType: .aldose, configuration: .d
    )

    public static let arabinose = builtIn(
        name: "Arabinose", abbreviation: "Ara", formula: "C5H10O5",
        type: .pentose, carbonylType: .aldose, configuration: .l
    )

    public static let ribose = builtIn(
        name: "Ribose", abbreviation: "Rib", formula: "C5H10O5",
        type: .pentose, carbonylType: .aldose, configuration: .d
    )

    public static let deoxyribose = builtIn(
        name: "2-Deoxyribose", abbreviation: "dRib", formula: "C5H10O4",
        type: .pentose, carbonylType: .aldose, configuration: .d
    )

    public static let fucose = builtIn(
        name: "Fucose", abbreviation: "Fuc", formula: "C6H12O5",
        type: .hexose, carbonylType: .aldose, configuration: .l
    )

    public static let nAcetylglucosamine = builtIn(
        name: "N-Acetylglucosamine", abbreviation: "GlcNAc", formula: "C8H15NO6",
        type: .hexose, carbonylType: .aldose, configuration: .d
    )

    public static let nAcetylgalactosamine = builtIn(
        name: "N-Acetylgalactosamine", abbreviation: "GalNAc", formula: "C8H15NO6",
        type: .hexose, carbonylType: .aldose, configuration: .d
    )

    public static let nAcetylneuraminicAcid = builtIn(
        name: "N-Acetylneuraminic acid", abbreviation: "Neu5Ac", formula: "C11H19NO9",
        type: .nonose, carbonylType: .ketose, configuration: .d
    )

    private static func builtIn(
        name: String,
        abbreviation: String,
        formula: String,
        type: MonosaccharideType,
        carbonylType: MonosaccharideCarbonylType,
        configuration: MonosaccharideConfiguration
    ) -> Monosaccharide {
        do {
            return try Monosaccharide(
                name: name,
                abbreviation: abbreviation,
                formula: formula,
                type: type,
                carbonylType: carbonylType,
                configuration: configuration
            )
        } catch {
            preconditionFailure("Invalid built-in monosaccharide formula \(formula): \(error)")
        }
    }
}
