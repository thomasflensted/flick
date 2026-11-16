import Foundation
import Testing
@testable import FlickCore

struct CalculationTests {
    let english = Locale(identifier: "en_US")

    func value(_ text: String) -> Double? {
        Calculation.evaluate(text)?.value
    }

    @Test func doesBasicArithmetic() {
        #expect(value("50*12") == 600)
        #expect(value("7 + 3") == 10)
        #expect(value("10 - 4 - 3") == 3)
        #expect(value("9/2") == 4.5)
    }

    @Test func multipliesBeforeAdding() {
        #expect(value("2+3*4") == 14)
        #expect(value("20-12/4") == 17)
    }

    @Test func respectsParentheses() {
        #expect(value("(150-50)*12") == 1200)
        #expect(value("2*(3+(4-1))") == 12)
    }

    @Test func handlesNegativeAndDecimalNumbers() {
        #expect(value("-5+2") == -3)
        #expect(value("3*-2") == -6)
        #expect(value("1.5*2") == 3)
        #expect(value("1,5*2") == 3)
    }

    @Test func ignoresTextThatIsNotACalculation() {
        #expect(value("50") == nil)
        #expect(value("-50") == nil)
        #expect(value("(50)") == nil)
        #expect(value("50*") == nil)
        #expect(value("(150-50*12") == nil)
        #expect(value("c++") == nil)
        #expect(value("5/0") == nil)
    }

    @Test func formatsWithoutFloatingPointNoise() throws {
        let calculation = try #require(Calculation.evaluate("0.1+0.2"))
        #expect(calculation.formattedValue(english) == "0.3")
    }

    @Test func plainValueHasNoGrouping() throws {
        let calculation = try #require(Calculation.evaluate("5000*3"))
        #expect(calculation.formattedValue(english) == "15,000")
        #expect(calculation.plainValue(english) == "15000")
    }

    @Test func showsCalculationFirstInSearch() {
        let results = SearchResults(links: [], apps: [], usage: [:]).results(for: "50*12")
        #expect(results.first?.kind == .calculation(Calculation(expression: "50*12", value: 600)))
    }
}
