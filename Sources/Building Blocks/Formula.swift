import Foundation

public struct Formula {
    public let stringValue: String
    
    public init(stringValue: String) {
        self.stringValue = stringValue
    }

    private typealias ElementInfo = (name: String, count: Int)

    private func parse() -> [ChemicalElement] {
        // https://stackoverflow.com/questions/23602175/regex-for-parsing-chemical-formulas
        let pattern = "([A-Z][a-z]*)([0-9]*)"
//        let pattern =  "([0-9]?d*|[A-Z][a-z]{0,2}?d*)"
//        let pattern = "[+-]?([A-Z][a-z]*)(\\d*)"
//        let openingBrackets = "({["
//        let closingBrackets = ")}]"
        
        var result = [ChemicalElement]()
        
        for match in self.stringValue.matches(for: pattern) {
            guard let elementString = self.stringValue.substring(with: match.range),
                let elementInfo = countOneElement(string: String(elementString))
                else { break }
            
            if let element = elementLibrary.first(where: { $0.identifier == elementInfo.name }) {
                for _ in 1...elementInfo.count {
                    result.append(element)
                }
            }
        }
        
        return result
    }
    
    private func countOneElement(string: String) -> ElementInfo? {
        let scanner = Scanner(string: string)
        
        guard
            let element = scanner.scanCharactersFromSet(set: CharacterSet.letters),
            let elementCount = scanner.scanInt()
            else { return nil }
        
        return ElementInfo(element as String, (elementCount == 0) ? 1 : elementCount)
    }

    public lazy var masses: MassContainer = {
        return calculateMasses()
    }()
}

extension Formula: Mass {
    public func calculateMasses() -> MassContainer {
        var elements = parse()
        let result = elements.indices.map { elements[$0].masses }
            .reduce(zeroMass, +)

        return stringValue.hasPrefix("-") ? -1 * result : result
    }
}

public let formulaSeparator = " + "

extension Formula {
    public static func + (lhs: Formula, rhs: Formula) -> Formula {
        return Formula(stringValue: (lhs.stringValue + formulaSeparator + rhs.stringValue))
    }

    public static func - (lhs: Formula, rhs: Formula) -> Formula {
        return Formula(stringValue: (lhs.stringValue + formulaSeparator + "-" + rhs.stringValue))
    }
}
