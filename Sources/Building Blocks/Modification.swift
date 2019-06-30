import Foundation

public struct Modification {
    public let group: FunctionalGroup
    public var location: Int
    public var attachedTo: String

    public init(group: FunctionalGroup, location: Int, attachedTo: String = "") {
        self.group = group
        self.location = location
        self.attachedTo = attachedTo
    }
}

extension Modification: Hashable {
    public static func == (lhs: Modification, rhs: Modification) -> Bool {
        return (lhs.group == rhs.group && lhs.location == rhs.location && lhs.attachedTo == rhs.attachedTo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(group)
        hasher.combine(location)
        hasher.combine(attachedTo)
    }
}
