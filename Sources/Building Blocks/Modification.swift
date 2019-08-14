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
