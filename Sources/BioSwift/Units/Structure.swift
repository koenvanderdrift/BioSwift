import Foundation

public protocol Structure: Mass {
    var name: String { get }
    var formula: Formula { get }
}

extension Structure {
    public func calculateMasses() -> MassContainer {
        return mass(of: formula.elements)
    }
}
