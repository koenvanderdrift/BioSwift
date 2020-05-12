import Foundation

public typealias ModificationSet = Set<LocalizedModification>

public indirect enum Reaction {
    case add(Group)
    case remove(Group)
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

public struct Modification {
    public let name: String
    public let reactions: [Reaction]
    public let sites: [String] // sites it can attach to

    public init(name: String, reactions: [Reaction], sites: [String] = []) {
        self.name = name
        self.reactions = reactions
        self.sites = sites
    }

    public init(name: String, elements: [String: Int], sites: [String] = []) {
        var reactions = [Reaction]()

        let negativeElements = elements.filter { $0.value < 0 }
        if negativeElements.count > 0 {
            let group = Group(name: name, formula: negativeElements)
            reactions.append(Reaction.remove(group))
        }

        let postiveElements = elements.filter { $0.value > 0 }
        if postiveElements.count > 0 {
            let group = Group(name: name, formula: postiveElements)
            reactions.append(Reaction.add(group))
        }

        self.init(name: name, reactions: reactions, sites: sites)
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
        return reactions.reduce(zeroMass) { $0 + $1.masses }
    }
}

public struct LocalizedModification: Comparable, Hashable {
    public let modification: Modification?
    public let location: Int

    public init(modification: Modification?, location: Int) {
        self.modification = modification
        self.location = location
    }

    public static func < (lhs: LocalizedModification, rhs: LocalizedModification) -> Bool {
        return lhs.location < rhs.location
    }
}

public struct Link: Hashable {
    // https://codereview.stackexchange.com/questions/237295/comparing-two-structs-in-swift#
    public var mods: Set<LocalizedModification>

    public init(_ mods: Set<LocalizedModification>) {
        self.mods = mods
    }
}

extension Link {
    public enum CompareResult {
        case equal
        case intersect
        case disjoint
    }

    public func compareLocations(with other: Link) -> CompareResult {
        if mods == other.mods {
            return .equal
        } else if mods.isDisjoint(with: other.mods) {
            return .disjoint
        } else {
            return .intersect
        }
    }

    public func contains(_ location: Int) -> Bool {
        for mod in mods {
            if mod.location == location {
                return true
            }
        }

        return false
    }
}
