import Foundation

public let noModification = Modification(name: "None", reactions: [], sites: [])

public let oxidation = Modification(name: "Oxidation", reactions: [.add(oxygen)], sites: ["M", "W", "Y"])
public let deamidation = Modification(name: "Deamidation", reactions: [.add(water), .remove(ammonia)], sites: ["N", "Q"])
public let reduction = Modification(name: "Reduction", reactions: [.remove(hydrogen)], sites: ["C"])
public let methylation = Modification(name: "Methylation", reactions: [.add(methyl)], sites: ["K"])
public let acetylation = Modification(name: "Acetylation", reactions: [.add(acetyl)], sites: ["K", "NTerminal"])

public let pyroglutamateE = Modification(name: "Pyroglutamate (E)", reactions: [.remove(water)], sites: ["E"])
public let pyroglutamateQ = Modification(name: "Pyroglutamate (Q)", reactions: [.remove(ammonia)], sites: ["Q"])

public let cysteinylation = Modification(name: "Cysteinylation", reactions: [.remove(cysteinyl)], sites: ["C"])

// TODO: generate from modifications.json
public var modificationsLibrary = [oxidation, deamidation, reduction, methylation, acetylation, pyroglutamateE, pyroglutamateQ, cysteinylation]

public indirect enum Reaction {
    case add(FunctionalGroup)
    case remove(FunctionalGroup)
    case undefined
}

extension Reaction: Mass {
    public var masses: MassContainer {
        return calculateMasses()
    }
    
    public func calculateMasses() -> MassContainer {
        var result = zeroMass

        switch self {
        case .add(let group) :
            result += group.masses
        case .remove(let group):
            result -= group.masses
        case .undefined:
            result += zeroMass
        }
        
        return result
    }
}

public struct ModificationInfo {
    public let modification: Modification
    public let location: Int
    
    public init(modification: Modification, location: Int) {
        self.modification = modification
        self.location = location
    }
}

public struct Modification {
    public let name: String
    public let reactions: [Reaction]
    public let sites: [String] // sites it can attach to
    
    public init(name: String, reactions: [Reaction], sites: [String] = []) {
        self.name = name
        self.reactions = reactions
        self.sites = sites
    }
}

extension Modification: Hashable {
    public static func == (lhs: Modification, rhs: Modification) -> Bool {
        return lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(sites)
    }
}

extension Modification: Mass {
    public var masses: MassContainer {
        return calculateMasses()
    }
    
    public func calculateMasses() -> MassContainer {
        return reactions.reduce(zeroMass, { $0 + $1.masses })
    }
}
