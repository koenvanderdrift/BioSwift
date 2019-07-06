import Foundation

public struct Modification {
    public let group: FunctionalGroup
    public var location: Int
    public var site: String

    public init(group: FunctionalGroup, location: Int, site: String = "") {
        self.group = group
        self.location = location
        self.site = site
    }
}

extension Modification: Hashable {
    public static func == (lhs: Modification, rhs: Modification) -> Bool {
        return (lhs.group == rhs.group && lhs.location == rhs.location && lhs.site == rhs.site)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(group)
        hasher.combine(location)
        hasher.combine(site)
    }
}
