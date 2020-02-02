import Foundation

public typealias Elements = [ChemicalElement]

public struct Formula {
    private(set) var elements: [ChemicalElement] = []
    private(set) var _masses: MassContainer = zeroMass
    
    public var string: String
    
    public init(_ string: String) {
        self.string = string
        self.elements = {
            var result = Elements()
            
            do {
                result = try parse()
            }
            catch {
                debugPrint(error)
            }
        
            return result
        }()
        
        _masses = calculateMasses()
    }
    
    var description: String {
        return string
    }
}

extension Formula {
    public func countFor(element: String) -> Int {
        return elements.map { $0.symbol }.filter{ $0 == element }.count
    }
    
    enum ParseError: Error {
        case missingClosingBracket
        case missingOpeningBracket
        case zeroCount
        case invalidCharacterFound(Character)
        case elementNotFound
        case numberPrecedingFormula
        case invalidFormula
    }
    
    private func parse() throws -> Elements {
        
        // https://www.lfd.uci.edu/~gohlke/code/molmass.py.html
        // https://www.lfd.uci.edu/~gohlke/code/elements.py.html
        
        let characters = Array(string)
        var i = characters.count
        
        var parenthesisLevel = 0
        var multiplication = [1]
        
        var elementCount = 0
        var elementName = ""
        
        var result = Elements()
        
        // parse string backwards
        
        while i > 0 {
            i -= 1
            let char = characters[i]
            
            if isOpeningBracket(char) {
                parenthesisLevel -= 1
                if parenthesisLevel < 0 || elementCount != 0 {
                    throw ParseError.missingClosingBracket
                }
            }
                
            else if isClosingBracket(char) {
                if elementCount == 0 {
                    elementCount = 1
                }
                
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
                    throw ParseError.zeroCount
                }
            }
                
            else if isLowercase(char) {
                if isUppercase(characters[i-1]) == false {
                    throw ParseError.invalidCharacterFound(char)
                }
                
                elementName = String(char)
            }
                
            else if isUppercase(char) {
                elementName = String(char) + elementName
                
                if elementCount == 0 {
                    elementCount = 1
                }
                
                let j = i
                
                while i > 0 && isDigit(characters[i-1]) {
                    i -= 1
                }
                
                if i > 0 && isOpeningBracket(characters[i-1]) == false {
                    i = j
                }
                
                if let element = elementLibrary.first(where: { $0.identifier == elementName }) {
                    for _ in 0..<(elementCount * multiplication[parenthesisLevel]) {
                        result.append(element)
                    }
                }
                else {
                    throw ParseError.elementNotFound
                }
                
                elementName = ""
                elementCount = 0
            }
                
            else {
                throw ParseError.invalidCharacterFound(char)
            }
        }
        
        if elementCount != 0 {
            throw ParseError.numberPrecedingFormula
        }
        
        if parenthesisLevel != 0 {
            throw ParseError.missingOpeningBracket
        }
        
        if parenthesisLevel != 0 {
            throw ParseError.missingOpeningBracket
        }
        
        if result.isEmpty {
            throw ParseError.invalidFormula
        }
        
        return result
    }
    
    private func isUppercase(_ char: Character) -> Bool {
        return "ABCDEFGHIJKLMNOPQRSTUVWXYZ".contains(char)
    }
    
    private func isLowercase(_ char: Character) -> Bool {
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
        let result = mass(of: elements)
        
        return string.hasPrefix("-") ? -1 * result : result
    }
}

public let formulaSeparator = " + "

extension Formula {
    public static func + (lhs: Formula, rhs: Formula) -> Formula {
        return Formula((lhs.string + formulaSeparator + rhs.string))
    }
    
    public static func - (lhs: Formula, rhs: Formula) -> Formula {
        return Formula((lhs.string + formulaSeparator + "-" + rhs.string))
    }
}
