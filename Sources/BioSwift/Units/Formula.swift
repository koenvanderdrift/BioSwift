import Foundation

public let zeroFormula = Formula("")

public class Formula {
    public var formulaString: String

    public lazy var elements: [ChemicalElement] = getElements()

    public init(_ string: String) {
        formulaString = string
    }

    public init(_ dict: [String: Int]) {
        var formula = ""
        for (element, count) in dict {
            formula.append(element)
            if count > 1 {
                formula.append(String(count))
            }
        }

        formulaString = formula
    }

    public var description: String {
        formulaString
    }
    
    public var chemicalString: String {  // TODO
        var result = ""

        for c in formulaString {
            if c.isNumber {
                result.append(String(c).subSript())
            }
            else {
                result.append(c)
            }
        }

        return result
    }

    public func countedElements() -> NSCountedSet {
        NSCountedSet(array: elements)
    }

    public func isotopes() -> NSCountedSet {
        NSCountedSet(array: elements.map(\.isotopes).reduce([], +))
    }

    public func countFor(element: String) -> Int {
        elements.map(\.symbol).filter { $0 == element }.count
    }
}

extension Formula {
    private enum ParseError: Error {
        case missingClosingBracket
        case missingOpeningBracket
        case zeroCount
        case invalidCharacterFound(Character)
        case elementNotFound
        case numberPrecedingFormula
        case invalidFormula
    }

    private func getElements() -> [ChemicalElement] {
        var result: [ChemicalElement] = []

        do {
            result = try parseElements()
        } catch {
            debugPrint(error)
        }

        return result
    }

    private func parseElements() throws -> [ChemicalElement] {
        // https://github.com/cgohlke/molmass/blob/master/molmass/molmass.py
        // https://github.com/cgohlke/molmass/blob/master/molmass/elements.py

        let characters = Array(formulaString)
        var i = characters.count

        var parenthesisLevel = 0
        var multiplication = [1]

        var elementCount = 0
        var elementName = ""

        var result = [ChemicalElement]()

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
            } else if isClosingBracket(char) {
                if elementCount == 0 {
                    elementCount = 1
                }

                parenthesisLevel += 1

                if parenthesisLevel > multiplication.count - 1 {
                    multiplication.append(0)
                }

                multiplication[parenthesisLevel] = elementCount * multiplication[parenthesisLevel - 1]

                elementCount = 0
            } else if char.isNumber {
                let j = i

                while i > 0, characters[i - 1].isNumber {
                    i -= 1
                }

                elementCount = Int(formulaString[i ..< j + 1])!

                if elementCount == 0 {
                    throw ParseError.zeroCount
                }
            } else if char.isLowercase {
                if characters[i - 1].isUppercase == false {
                    throw ParseError.invalidCharacterFound(char)
                }

                elementName = String(char)
            } else if char.isUppercase {
                elementName = String(char) + elementName

                if elementCount == 0 {
                    elementCount = 1
                }

                let j = i

                while i > 0, characters[i - 1].isNumber {
                    i -= 1
                }

                if i > 0, isOpeningBracket(characters[i - 1]) == false {
                    i = j
                }

                if let element = elementLibrary.first(where: { $0.identifier == elementName }) {
                    for _ in 0 ..< (elementCount * multiplication[parenthesisLevel]) {
                        result.append(element)
                    }
                } else {
                    throw ParseError.elementNotFound
                }

                elementName = ""
                elementCount = 0
            } else {
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

    private func isOpeningBracket(_ char: Character) -> Bool {
        "({[<".contains(char)
    }

    private func isClosingBracket(_ char: Character) -> Bool {
        ")}]>".contains(char)
    }
}

extension Formula: Equatable {
    public static func == (lhs: Formula, rhs: Formula) -> Bool {
        lhs.countedElements() == rhs.countedElements()
    }
}

public extension Formula {
    static func + (lhs: Formula, rhs: Formula) -> Formula {
        Formula(lhs.formulaString + rhs.formulaString)
    }

    static func += (lhs: inout Formula, rhs: Formula) {
        lhs = lhs + rhs
    }
}

public extension String {
    func superScript() -> String {
        var result = ""
        for char in self {
            if char == "+" { result.append("\u{207A}") }
            else if char == "-" { result.append("\u{207B}") }
            else if char == "1" { result.append("") }
            else if char == "2" { result.append("\u{00B2}") }
            else if char == "3" { result.append("\u{00B3}") }
            else if char == "4" { result.append("\u{2074}") }
            else if char == "5" { result.append("\u{2075}") }
            else if char == "6" { result.append("\u{2076}") }
            else if char == "7" { result.append("\u{2077}") }
            else if char == "8" { result.append("\u{2078}") }
            else if char == "9" { result.append("\u{2079}") }
        }

        return result
    }

    func subSript() -> String {
        var result = ""
        for char in self {
            if char == "0" { result.append("\u{2080}") }
            else if char == "1" { result.append("\u{2081}") }
            else if char == "2" { result.append("\u{2082}") }
            else if char == "3" { result.append("\u{2083}") }
            else if char == "4" { result.append("\u{2084}") }
            else if char == "5" { result.append("\u{2085}") }
            else if char == "6" { result.append("\u{2086}") }
            else if char == "7" { result.append("\u{2087}") }
            else if char == "8" { result.append("\u{2088}") }
            else if char == "9" { result.append("\u{2089}") }
        }

        return result
    }
}


/*
 # Common chemical groups
 GROUPS = {
     'Abu': 'C4H7NO',
     'Acet': 'C2H3O',
     'Acm': 'C3H6NO',
     'Adao': 'C10H15O',
     'Aib': 'C4H7NO',
     'Ala': 'C3H5NO',
     'Arg': 'C6H12N4O',
     'Argp': 'C6H11N4O',
     'Asn': 'C4H6N2O2',
     'Asnp': 'C4H5N2O2',
     'Asp': 'C4H5NO3',
     'Aspp': 'C4H4NO3',
     'Asu': 'C8H13NO3',
     'Asup': 'C8H12NO3',
     'Boc': 'C5H9O2',
     'Bom': 'C8H9O',
     'Bpy': 'C10H8N2',  # Bipyridine
     'Brz': 'C8H6BrO2',
     'Bu': 'C4H9',
     'Bum': 'C5H11O',
     'Bz': 'C7H5O',
     'Bzl': 'C7H7',
     'Bzlo': 'C7H7O',
     'Cha': 'C9H15NO',
     'Chxo': 'C6H11O',
     'Cit': 'C6H11N3O2',
     'Citp': 'C6H10N3O2',
     'Clz': 'C8H6ClO2',
     'Cp': 'C5H5',
     'Cy': 'C6H11',
     'Cys': 'C3H5NOS',
     'Cysp': 'C3H4NOS',
     'Dde': 'C10H13O2',
     'Dnp': 'C6H3N2O4',
     'Et': 'C2H5',
     'Fmoc': 'C15H11O2',
     'For': 'CHO',
     'Gln': 'C5H8N2O2',
     'Glnp': 'C5H7N2O2',
     'Glp': 'C5H5NO2',
     'Glu': 'C5H7NO3',
     'Glup': 'C5H6NO3',
     'Gly': 'C2H3NO',
     'Hci': 'C7H13N3O2',
     'Hcip': 'C7H12N3O2',
     'His': 'C6H7N3O',
     'Hisp': 'C6H6N3O',
     'Hser': 'C4H7NO2',
     'Hserp': 'C4H6NO2',
     'Hx': 'C6H11',
     'Hyp': 'C5H7NO2',
     'Hypp': 'C5H6NO2',
     'Ile': 'C6H11NO',
     'Ivdde': 'C14H21O2',
     'Leu': 'C6H11NO',
     'Lys': 'C6H12N2O',
     'Lysp': 'C6H11N2O',
     'Mbh': 'C15H15O2',
     'Me': 'CH3',
     'Mebzl': 'C8H9',
     'Meobzl': 'C8H9O',
     'Met': 'C5H9NOS',
     'Mmt': 'C20H17O',
     'Mtc': 'C14H19O3S',
     'Mtr': 'C10H13O3S',
     'Mts': 'C9H11O2S',
     'Mtt': 'C20H17',
     'Nle': 'C6H11NO',
     'Npys': 'C5H3N2O2S',
     'Nva': 'C5H9NO',
     'Odmab': 'C20H26NO3',
     'Orn': 'C5H10N2O',
     'Ornp': 'C5H9N2O',
     'Pbf': 'C13H17O3S',
     'Pen': 'C5H9NOS',
     'Penp': 'C5H8NOS',
     'Ph': 'C6H5',
     'Phe': 'C9H9NO',
     'Phepcl': 'C9H8ClNO',
     'Phg': 'C8H7NO',
     'Pmc': 'C14H19O3S',
     'Ppa': 'C8H7O2',
     'Pro': 'C5H7NO',
     'Prop': 'C3H7',
     'Py': 'C5H5N',
     'Pyr': 'C5H5NO2',
     'Sar': 'C3H5NO',
     'Ser': 'C3H5NO2',
     'Serp': 'C3H4NO2',
     'Sta': 'C8H15NO2',
     'Stap': 'C8H14NO2',
     'Tacm': 'C6H12NO',
     'Tbdms': 'C6H15Si',
     'Tbu': 'C4H9',
     'Tbuo': 'C4H9O',
     'Tbuthio': 'C4H9S',
     'Tfa': 'C2F3O',
     'Thi': 'C7H7NOS',
     'Thr': 'C4H7NO2',
     'Thrp': 'C4H6NO2',
     'Tips': 'C9H21Si',
     'Tms': 'C3H9Si',
     'Tos': 'C7H7O2S',
     'Trp': 'C11H10N2O',
     'Trpp': 'C11H9N2O',
     'Trt': 'C19H15',
     'Tyr': 'C9H9NO2',
     'Tyrp': 'C9H8NO2',
     'Val': 'C5H9NO',
     'Valoh': 'C5H9NO2',
     'Valohp': 'C5H8NO2',
     'Xan': 'C13H9O',
 }

 # Amino acids - H2O
 AMINOACIDS = {
     'G': 'C2H3NO',  # Glycine, Gly
     'P': 'C5H7NO',  # Proline, Pro
     'A': 'C3H5NO',  # Alanine, Ala
     'V': 'C5H9NO',  # Valine, Val
     'L': 'C6H11NO',  # Leucine, Leu
     'I': 'C6H11NO',  # Isoleucine, Ile
     'M': 'C5H9NOS',  # Methionine, Met
     'C': 'C3H5NOS',  # Cysteine, Cys
     'F': 'C9H9NO',  # Phenylalanine, Phe
     'Y': 'C9H9NO2',  # Tyrosine, Tyr
     'W': 'C11H10N2O',  # Tryptophan, Trp
     'H': 'C6H7N3O',  # Histidine, His
     'K': 'C6H12N2O',  # Lysine, Lys
     'R': 'C6H12N4O',  # Arginine, Arg
     'Q': 'C5H8N2O2',  # Glutamine, Gln
     'N': 'C4H6N2O2',  # Asparagine, Asn
     'E': 'C5H7NO3',  # Glutamic Acid, Glu
     'D': 'C4H5NO3',  # Aspartic Acid, Asp
     'S': 'C3H5NO2',  # Serine, Ser
     'T': 'C4H7NO2',  # Threonine, Thr
 }

 # Deoxynucleotide monophosphates - H2O
 DEOXYNUCLEOTIDES = {
     'A': 'C10H12N5O5P',
     'T': 'C10H13N2O7P',
     'C': 'C9H12N3O6P',
     'G': 'C10H12N5O6P',
     'complements': {'A': 'T', 'T': 'A', 'C': 'G', 'G': 'C'},
 }

 # Nucleotide monophosphates - H2O
 NUCLEOTIDES = {
     'A': 'C10H12N5O6P',
     'U': 'C9H11N2O8P',
     'C': 'C9H12N3O7P',
     'G': 'C10H12N5O7P',
     'complements': {'A': 'U', 'U': 'A', 'C': 'G', 'G': 'C'},
 }

 # Formula preprocessors
 PREPROCESSORS = {
     'peptide': from_peptide,
     'ssdna': lambda x: from_oligo(x, 'ssdna'),
     'dsdna': lambda x: from_oligo(x, 'dsdna'),
     'ssrna': lambda x: from_oligo(x, 'ssrna'),
     'dsrna': lambda x: from_oligo(x, 'dsrna'),
 }

 */
