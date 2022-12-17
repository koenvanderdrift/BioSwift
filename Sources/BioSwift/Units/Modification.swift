import Foundation

public let unmodifiedString = "Unmodified"
public let zeroModification = Modification(name: unmodifiedString, elements: [:])

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
        case let .add(group):
            result += group.masses
        case let .remove(group):
            result -= group.masses
        case .undefined:
            break
        }

        return result
    }
}

public protocol Modifiable {
    var modification: Modification? { get set }

    func allowedModifications() -> [Modification]
}

extension Modifiable {
    mutating func setModification(_ modification: Modification?) {
        self.modification = modification
    }

    mutating func removeModification() {
        modification = nil
    }
    
    func modificationMasses() -> MassContainer {
        return modification?.masses ?? zeroMass
    }

}

public struct Modification: Decodable {
/*
     via: https://www.unimod.org/fields.html
     
     Site: Chosen from a controlled list of categories. Choose "N-term" or "C-Term" if the modification applies to a terminus independent of the identity of the terminal residue, (e.g. methylation of a carboxy terminus).

     Position: Chosen from a controlled list of categories. Choose "Anywhere" if the modification applies to a residue independent of its position, (e.g. oxidation of methionine). Choose "Any N-term" or "Any C-term" if the modification applies to a residue only when it is at a peptide terminus, (e.g. conversion of methionine to homoserine). Choose "Protein N-term" or "Protein C-term" if the modification only applies to the original terminus of the intact protein, not new peptide termini created by digestion, (e.g. post-translational acetylation of the protein amino terminus). If Site was specified as "N-term" or "C-Term", then "Anywhere" becomes equivalent to "Any N-term" or "Any C-term".
*/

    public let name: String
    public let reactions: [Reaction]
    public let sites: [String] // sites it can attach to

    private(set) var _masses: MassContainer = zeroMass

    enum CodingKeys: String, CodingKey {
        case name = "name"
        case reactions = "reactions"
        case sites = "sites"
    }
    
    public init(from decoder: Decoder) throws {
        self.name = ""
        self.reactions = []
        self.sites = []
        
        _masses = calculateMasses()
    }
    
    public init(name: String, reactions: [Reaction], sites: [String] = []) {
        self.name = name
        self.reactions = reactions
        self.sites = sites

        _masses = calculateMasses()
    }

    public init(name: String, elements: [String: Int], sites: [String] = []) {
        var reactions = [Reaction]()

        let negativeElements = elements.filter { $0.value < 0 }
        if negativeElements.count > 0 {
            let group = FunctionalGroup(name: name, formula: negativeElements)
            reactions.append(Reaction.remove(group))
        }

        let postiveElements = elements.filter { $0.value > 0 }
        if postiveElements.count > 0 {
            let group = FunctionalGroup(name: name, formula: postiveElements)
            reactions.append(Reaction.add(group))
        }

        self.init(name: name, reactions: reactions, sites: sites)
    }
    
    public init(_ modification: Modification) {
        self.name = modification.name
        self.sites = modification.sites
        self.reactions = modification.reactions

        _masses = calculateMasses()
    }
}

extension Modification: Hashable {
    public static func == (lhs: Modification, rhs: Modification) -> Bool {
        return lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

extension Modification: Mass {
    public var masses: MassContainer {
        _masses
    }

    public func calculateMasses() -> MassContainer {
        return reactions.reduce(zeroMass) { $0 + $1.masses }
    }
}

public struct LocalizedModification: Hashable {
    public let location: Int
    public let chain: Int
    public let modification: Modification
    
    public init(_ modification: Modification, at location: Int, in chain: Int = 0) {
        self.location = location
        self.chain = chain
        self.modification = modification
    }
}

public struct Link: Hashable {
    public var mods: [LocalizedModification]
    
    public init(mods: [LocalizedModification]) {
        self.mods = mods
    }

    public func contains(_ location: Int) -> Bool {
        return mods.contains(where: { $0.location == location })
    }
}

extension Link {
    // https://codereview.stackexchange.com/questions/237295/comparing-two-structs-in-swift#
    
    public enum CompareResult {
        case equal
        case intersect
        case disjoint
    }

    public func compareLocations(with other: Link) -> CompareResult {
        let modsSet = Set(mods)
        let otherModsSet = Set(other.mods)
        
        if modsSet == otherModsSet {
            return .equal
        } else if modsSet.isDisjoint(with: otherModsSet) {
            return .disjoint
        } else {
            return .intersect
        }
    }
}
