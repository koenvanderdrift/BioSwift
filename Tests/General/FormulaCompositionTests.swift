import Testing

import BioSwift

@Suite("Formula composition")
struct FormulaCompositionTests {
    @Test("Addition combines element counts without changing either operand")
    func addition() throws {
        let glucose = try Formula("C6H12O6")
        let water = try Formula("H2O")

        let combined = glucose + water

        #expect(combined.formulaString == "C6H14O7")
        #expect(combined.elementCount(for: "C") == 6)
        #expect(combined.elementCount(for: "H") == 14)
        #expect(combined.elementCount(for: "O") == 7)
        #expect(glucose.formulaString == "C6H12O6")
        #expect(water.formulaString == "H2O")
    }

    @Test("In-place addition updates the formula")
    func inPlaceAddition() throws {
        var formula = try Formula("CH4")
        let oxygen = try Formula("O2")
        let expected = try Formula("CH4O2")

        formula += oxygen

        #expect(formula == expected)
    }

    @Test("The zero formula is an additive identity")
    func zeroIdentity() throws {
        let formula = try Formula("C2H5NO2")

        #expect(formula + zeroFormula == formula)
        #expect(zeroFormula + formula == formula)
    }

    @Test("Subtraction operators are publicly available and symmetric")
    func subtraction() throws {
        let combined = try Formula("C6H14O7")
        let water = try Formula("H2O")
        let glucose = try Formula("C6H12O6")
        let pentose = try Formula("C5H10O5")
        var result = combined - water

        #expect(result == glucose)

        result -= try Formula("CH2O")
        #expect(result == pentose)
    }
}
