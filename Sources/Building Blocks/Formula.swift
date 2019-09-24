import Foundation

// chemical formula parser

public typealias Formula = String

private typealias ElementInfo = (name: String, count: Int)

extension Formula {
    private func parse() -> [ChemicalElement] {
        // https://stackoverflow.com/questions/23602175/regex-for-parsing-chemical-formulas
        let pattern = "([A-Z][a-z]*)([0-9]*)"
//        let pattern =  "([0-9]?d*|[A-Z][a-z]{0,2}?d*)"
//        let pattern = "[+-]?([A-Z][a-z]*)(\\d*)"
//        let openingBrackets = "({["
//        let closingBrackets = ")}]"
        
        var result = [ChemicalElement]()
        
        for match in self.matches(for: pattern) {
            guard let elementString = self.substring(with: match.range),
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
}


extension Formula: Mass {
    public var charge: Int {
        return 0
    }
    
    public var masses: MassContainer {
        return calculateMasses()
    }
    
    public func calculateMasses() -> MassContainer {
        let result = parse()
            .reduce(zeroMass, {$0 + $1.masses})

        return hasPrefix("-") ? -1 * result : result
    }
}


public let formulaSeparator = " + "

extension Formula {
    public static func - (lhs: Formula, rhs: Formula) -> Formula {
        return lhs + formulaSeparator + "-" + rhs
    }
}
