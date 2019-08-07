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

public enum BondType {
    case disulfide
    case lactam
    case other
}

public struct Bond {
    public var from: Int
    public var to: Int
    public var type: BondType
    
    public init(from: Int, to: Int, type: BondType) {
        self.from = from
        self.to = to
        self.type = type
    }
}

extension Bond: Equatable {
    public static func == (lhs: Bond, rhs: Bond) -> Bool {
        // return true if to and from are the same or reversed
        return (lhs.type == rhs.type) &&
            ((lhs.from == rhs.from && lhs.to == rhs.to) || (lhs.from == rhs.to && lhs.to == rhs.from))
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
