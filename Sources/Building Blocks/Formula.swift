import Foundation

public struct Formula {
    private(set) var elements: [ChemicalElement] = []
    private(set) var _masses: MassContainer = zeroMass

    public var stringValue: String

    public init(stringValue: String) {
        self.stringValue = stringValue
        self.elements = parse(stringValue)
        
        _masses = calculateMasses()
    }
    
    var description: String {
        return stringValue
    }
    
    private typealias ElementInfo = (element: String, count: Int)

    private func parse(_ string: String) -> [ChemicalElement] {

        let characters = Array(string)
        var i = characters.count
        
        var parenthesisLevel = 0
        var multiplication = [1]
        var number = 0
        var element = ""
        var result = [ElementInfo]()
        
        while i > 0 {
            i -= 1
            let char = characters[i]
            
            if  "({[<".contains(char) {
                parenthesisLevel -= 1
                if parenthesisLevel < 0 || number != 0 {
                    // error no closing bracket
                }
            }
            
            else if ")}]>".contains(char) {
                if number == 0 { number = 1 }
                parenthesisLevel += 1
                
                if parenthesisLevel > multiplication.count - 1 {
                    multiplication.append(0)
                }
                
                multiplication[parenthesisLevel] = number * multiplication[parenthesisLevel - 1]
                number = 0
            }
            
            else if "0123456789".contains(char) {
                let j = i
                
                while i > 0 && "0123456789".contains(characters[i-1]) {
                    i -= 1
                }
                
                number = Int(string[i..<j+1])!
                if number == 0 {
                    // error count is zero
                }
            }
                
            else if "abcdefghijklmnopqrstuvwxyz".contains(char) {
                if !("ABCDEFGHIJKLMNOPQRSTUVWXYZ".contains(characters[i-1])) {
                    // error unexpected character
                }
                
                element = String(char)
            }
            else if "ABCDEFGHIJKLMNOPQRSTUVWXYZ".contains(char) {
                element = String(char) + element
                if number == 0 { number = 1 }
                
                var iso = ""
                let j = i
                
                while i > 0 && "0123456789".contains(characters[i-1]) {
                    i -= 1
                    iso = String(string[i]) + iso
                }
                
                if (iso.count > 0 && i > 0) && ("({[<".contains(characters[i-1]) == false) {
                    i = j
                    iso = ""
                }
                
                let elementCount = number * multiplication[parenthesisLevel]
                if var info = result.first(where: { $0.element == element }) {
                    info.count += elementCount
                    result.append(info)
                }
                else {
                    let info = ElementInfo(element, elementCount)
                    result.append(info)
                }
                
                element = ""
                number = 0
            }
            else {
                // error invalid character
            }
        }
        
        var elements = [ChemicalElement]()

        for info in result {
            if let element = elementLibrary.first(where: { $0.identifier == info.element }) {
                for _ in 1...info.count {
                    elements.append(element)
                }
            }
        }
        
        return elements
    }
}

extension Formula: Mass {
    public var masses: MassContainer {
        return _masses
    }

    public func calculateMasses() -> MassContainer {
        let result = mass(of: elements)
    
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
