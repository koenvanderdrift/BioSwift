import Foundation

public class Molecule: NSObject, Mass {
    public var charge: Int = 0
    
    public let name: String
    public let formula: Formula

    public init(name: String, formula: String) {
        self.name = name
        self.formula = formula
    }
    
    public lazy var masses: MassContainer = {
        return calculateMasses()
    }()

    public func calculateMasses() -> MassContainer {
        return formula.masses()
    }
}



//extension Molecule: Equatable {
//    public static func == (lhs: Molecule, rhs: Molecule) -> Bool {
//        return lhs.name == rhs.name
//    }
//}
//
//extension Molecule: Hashable {
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(name)
//        hasher.combine(formula)
//    }
//}
