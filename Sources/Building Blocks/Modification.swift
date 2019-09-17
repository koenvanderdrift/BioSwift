import Foundation

public class Modification: NSObject {
    public let group: FunctionalGroup
    public var location: Int
    public var site: String

    public init(group: FunctionalGroup, location: Int, site: String = "") {
        self.group = group
        self.location = location
        self.site = site
    }
}

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

public struct Bond { // only created as a modification
    public var from: Int
    public var to: Int
    public var info: BondInfo
    
    public init(from: Int, to: Int, info: BondInfo) {
        self.from = from
        self.to = to
        self.info = info
    }
    
    public func contains(_ location: Int) -> Bool {
        return (from == location || to == location)
    }
}

extension Bond: Equatable {
    public static func == (lhs: Bond, rhs: Bond) -> Bool {
        // return true if same type and if to and from are the same or reversed
        return lhs.info == rhs.info &&
            ((lhs.from == rhs.from && lhs.to == rhs.to) ||
            (lhs.from == rhs.to && lhs.to == rhs.from))
    }
}

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


//extension Modification: Hashable {
//    public static func == (lhs: Modification, rhs: Modification) -> Bool {
//        return (lhs.group == rhs.group && lhs.location == rhs.location && lhs.site == rhs.site)
//    }
//
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(group)
//        hasher.combine(location)
//        hasher.combine(site)
//    }
//}
