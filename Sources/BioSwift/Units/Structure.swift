import Foundation

public protocol Structure: Chargeable {
    var name: String { get }
    var formula: Formula { get }
    var adducts: [Adduct] { get set }
}

extension Structure {
    public func calculateMasses() -> MassContainer {
        return mass(of: formula.elements)
    }
}
