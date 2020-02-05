import Foundation

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
    case bond(Int, Reaction)
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
        case .bond(_, let reaction):
            result += reaction.masses
            break
        }
        
        return result
    }
}

public typealias ModificationInfo = (name: String, location: Int)

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

public let disulfideBondInfo = BondInfo(name: "Disulfide", from: "Cys", to: "Cys")

public struct BondInfo {
    public let name: String
    public let from: String
    public let to: String
    
    public init(name: String, from: String, to: String) {
        self.from = from
        self.to = to
        self.name = name
    }
}

extension BondInfo: Equatable {
    public static func == (lhs: BondInfo, rhs: BondInfo) -> Bool {
        return lhs.name == rhs.name && lhs.from == rhs.from && lhs.to == rhs.to
    }
}

//public struct Bond { // only created as a modification
//    public var from: Int
//    public var to: Int
//    public var info: BondInfo
//    
//    public init(from: Int, to: Int, info: BondInfo) {
//        self.from = from
//        self.to = to
//        self.info = info
//    }
//    
//    public func contains(_ location: Int) -> Bool {
//        return (from == location || to == location)
//    }
//}
//
//extension Bond: Equatable {
//    public static func == (lhs: Bond, rhs: Bond) -> Bool {
//        // return true if same type and if to and from are the same or reversed
//        return lhs.info == rhs.info &&
//            ((lhs.from == rhs.from && lhs.to == rhs.to) ||
//            (lhs.from == rhs.to && lhs.to == rhs.from))
//    }
//}

/*

Bond (FunctionalGroup)
•	Name (disulfide, lactam, etc)
•	Formula (probably negative)
•	Sites it can attach to
•	Is ignorant of where it is located in a sequence
Link (Modification)
•	Bond
•	Locations (in sequence)
•	Sites it is attached to

So Bond is a FG and Link is a Mod
•	But with two sites it is attached to
•	So subclass and add additional property for pair of sites
•	In init: set location (inherited from Mod) to -1


typealias Bond = FunctionalGroup

public class Link: Modification {
    public var sites: [String]
    
    public init(bond: Bond, sites: [String]) {
        self.sites = sites
        self.group = bond

       super.init(group: bond, location: -1)
    }
}

*/
