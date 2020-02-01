import Foundation

public struct Formula {
//    private(set) var elements: [ChemicalElement]
    private(set) var _masses: MassContainer = zeroMass

    public var stringValue: String

    public init(stringValue: String) {
        self.stringValue = stringValue
//        self.elements = parse(stringValue)
        
        _masses = calculateMasses()
    }
    
    var description: String {
        return stringValue
    }
    
    private func parse(_ string: String) -> [ChemicalElement] {

        // https://www.lfd.uci.edu/~gohlke/code/molmass.py.html
        // https://www.lfd.uci.edu/~gohlke/code/elements.py.html

        let characters = Array(string)
        var i = characters.count
        
        var parenthesisLevel = 0
        var multiplication = [1]
        
        var elementCount = 0
        var element = ""
        
        var result = [ChemicalElement]()

        while i > 0 {
            i -= 1
            let char = characters[i]
            
            if isOpeningBracket(char) {
                parenthesisLevel -= 1
                if parenthesisLevel < 0 || elementCount != 0 {
                    // error no closing bracket
                }
            }
            
            else if isClosingBracket(char) {
                if elementCount == 0 { elementCount = 1 }
                parenthesisLevel += 1
                
                if parenthesisLevel > multiplication.count - 1 {
                    multiplication.append(0)
                }
                
                multiplication[parenthesisLevel] = elementCount * multiplication[parenthesisLevel - 1]
                elementCount = 0
            }
            
            else if isDigit(char) {
                let j = i
                
                while i > 0 && isDigit(characters[i-1]) {
                    i -= 1
                }
                
                elementCount = Int(string[i..<j+1])!
                if elementCount == 0 {
                    // error count is zero
                }
            }
                
            else if isLower(char) {
                if !(isUpper(characters[i-1])) {
                    // error unexpected character
                }
                
                element = String(char)
            }
            else if isUpper(char) {
                element = String(char) + element
                if elementCount == 0 { elementCount = 1 }
                
                let j = i
                
                while i > 0 && isDigit(characters[i-1]) {
                    i -= 1
                }
                
                if i > 0 && !(isOpeningBracket(characters[i-1])) {
                    i = j
                }
                
                if let e = elementLibrary.first(where: { $0.identifier == element }) {
                    let elementCount = elementCount * multiplication[parenthesisLevel]
                    for _ in 0..<elementCount {
                        result.append(e)
                    }
                }
            
                element = ""
                elementCount = 0
            }
            
            else {
                // error invalid character
            }
        }
        
        return result
    }
}

extension Formula {
    private func isUpper(_ char: Character) -> Bool {
        return "ABCDEFGHIJKLMNOPQRSTUVWXYZ".contains(char)
    }
    
    private func isLower(_ char: Character) -> Bool {
        return "abcdefghijklmnopqrstuvwxyz".contains(char)
    }
    
    private func isDigit(_ char: Character) -> Bool {
        return "0123456789".contains(char)
    }
    
    private func isOpeningBracket(_ char: Character) -> Bool {
        return "({[<".contains(char)
    }
    
    private func isClosingBracket(_ char: Character) -> Bool {
        return ")}]>".contains(char)
    }




}

extension Formula: Mass {
    public var masses: MassContainer {
        return _masses
    }

    public func calculateMasses() -> MassContainer {
        let result = mass(of: parse(stringValue))
    
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
