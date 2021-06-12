import Foundation

public protocol Structure: Mass {
    var name: String { get }
    var formula: Formula { get }
}

extension Structure {
    public var masses: MassContainer {
        return calculateMasses()
    }

    public func calculateMasses() -> MassContainer {
        return mass(of: formula.elements)
    }
}
