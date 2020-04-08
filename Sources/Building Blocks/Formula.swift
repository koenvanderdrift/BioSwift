import Foundation

public typealias Elements = [ChemicalElement]

public struct Formula {
    private(set) var elements: [ChemicalElement] = []
    
    public var string: String
    
    public init(_ string: String) {
        self.string = string
        self.elements = elements(from: string)
    }
    
    public init(_ dict: [String:Int]) {
        var formula = ""
        for (element, count) in dict {
            formula.append(element)
            if count > 1 {
                formula.append(String(count))
            }
        }

        self.string = formula
        self.elements = elements(from: formula)
    }
    
    var description: String {
        return string
    }
    
    public func countedElements() -> NSCountedSet {
        let set = NSCountedSet()
        
        for element in elements {
            set.add(element.symbol)
        }
        
        return set
    }
}

extension Formula {
    private func elements(from formula: String) -> Elements {
        var result = Elements()
        
        do {
            result = try parse(formula)
        }
        catch {
            debugPrint(error)
        }
        
        return result
    }

    private func countFor(element: String) -> Int {
        return elements.map { $0.symbol }.filter{ $0 == element }.count
    }
    
    private enum ParseError: Error {
        case missingClosingBracket
        case missingOpeningBracket
        case zeroCount
        case invalidCharacterFound(Character)
        case elementNotFound
        case numberPrecedingFormula
        case invalidFormula
    }
    
    private func parse(_ formula: String) throws -> Elements {
        
        // https://www.lfd.uci.edu/~gohlke/code/molmass.py.html
        // https://www.lfd.uci.edu/~gohlke/code/elements.py.html
        
        let characters = Array(formula)
        var i = characters.count
        
        var parenthesisLevel = 0
        var multiplication = [1]
        
        var elementCount = 0
        var elementName = ""
        
        var result = Elements()
        
        if i == 0 {
            return result
        }
        
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
                
                elementCount = Int(formula[i..<j+1])!
                
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

public let formulaSeparator = " + "

extension Formula {
    public static func + (lhs: Formula, rhs: Formula) -> Formula {
        return Formula((lhs.string + formulaSeparator + rhs.string))
    }
    
    public static func - (lhs: Formula, rhs: Formula) -> Formula {
        return Formula((lhs.string + formulaSeparator + "-" + rhs.string))
    }
}
