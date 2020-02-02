import Foundation

public typealias Formula = String
public typealias Elements = [ChemicalElement]

public let formulaSeparator = " + "

extension Formula: Mass {
    public var masses: MassContainer {
        return calculateMasses()
    }
    
    public func calculateMasses() -> MassContainer {
        let result = mass(of: elements)
        
        return self.hasPrefix("-") ? -1 * result : result
    }
    
    public var elements: Elements {
        return parse()
    }
    
    private func parse() -> Elements {
        
        // https://www.lfd.uci.edu/~gohlke/code/molmass.py.html
        // https://www.lfd.uci.edu/~gohlke/code/elements.py.html
        
        let characters = Array(self)
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
                    debugPrint("missing closing bracket error")
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
                
                elementCount = Int(self[i..<j+1])!
                
                if elementCount == 0 {
                    debugPrint("count is zero error")
                }
            }
                
            else if isLowercase(char) {
                if isUppercase(characters[i-1]) == false {
                    // error unexpected character
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
                    debugPrint("element not in library error")
                }
                
                elementName = ""
                elementCount = 0
            }
                
            else {
                debugPrint("invalid character error")
            }
        }
        
        if elementCount != 0 {
            debugPrint("number preceding formula error")
        }
        
        if parenthesisLevel != 0 {
            debugPrint("missing opening parenthesis error")
        }
        
        if result.isEmpty {
            debugPrint("invalid formula error")
        }
        
        if parenthesisLevel != 0 {
            debugPrint("missing opening parenthesis error")
        }
        
        return result
    }
    
    public func countFor(element: String) -> Int {
        return elements.map { $0.symbol }.filter{ $0 == element }.count
    }
}

extension Formula {
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
