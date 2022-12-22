import Foundation

public protocol Structure: ChargedMass {
    var name: String { get }
    var formula: Formula { get }
    var adducts: [Adduct] { get set }
}

public extension Structure {
    func calculateMasses() -> MassContainer {
        mass(of: formula.elements)
    }
}
