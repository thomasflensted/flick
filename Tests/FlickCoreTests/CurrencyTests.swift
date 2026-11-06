import Foundation
import Testing
@testable import FlickCore

struct CurrencyTests {
    let rates = CurrencyRates(base: "USD", updated: Date(timeIntervalSince1970: 0),
                              rates: ["USD": 1, "EUR": 0.9, "DKK": 6.75, "SEK": 10, "GBP": 0.8])
    let codes: Set<String> = ["USD", "EUR", "DKK", "SEK", "GBP"]

    func parse(_ text: String, local: String = "DKK") -> MoneyQuery? {
        MoneyQuery.parse(text, known: codes, local: local)
    }

    @Test func parsesCodesAndTargets() {
        #expect(parse("100 usd to eur") == MoneyQuery(amount: 100, from: "USD", to: "EUR"))
        #expect(parse("100usd in dkk") == MoneyQuery(amount: 100, from: "USD", to: "DKK"))
        #expect(parse("50 EUR") == MoneyQuery(amount: 50, from: "EUR", to: nil))
        #expect(parse("100 usd sek") == MoneyQuery(amount: 100, from: "USD", to: "SEK"))
        #expect(parse("$20 dkk") == MoneyQuery(amount: 20, from: "USD", to: "DKK"))
    }

    @Test func parsesSymbolsWordsAndThousands() {
        #expect(parse("$20") == MoneyQuery(amount: 20, from: "USD", to: nil))
        #expect(parse("€ 5 > £") == MoneyQuery(amount: 5, from: "EUR", to: "GBP"))
        #expect(parse("10k kr to euro") == MoneyQuery(amount: 10_000, from: "DKK", to: "EUR"))
        #expect(parse("10 kr", local: "SEK")?.from == "SEK")
    }

    @Test func ignoresNonMoney() {
        #expect(parse("100") == nil)
        #expect(parse("100 apples") == nil)
        #expect(parse("usd") == nil)
        #expect(parse("10 usd to apples") == nil)
    }

    @Test func readsDecimalAndGroupingSeparators() {
        #expect(MoneyQuery.amount(from: "1.5") == 1.5)
        #expect(MoneyQuery.amount(from: "1,5") == 1.5)
        #expect(MoneyQuery.amount(from: "1,500") == 1500)
        #expect(MoneyQuery.amount(from: "1.500") == 1500)
        #expect(MoneyQuery.amount(from: "1.234.567") == 1_234_567)
        #expect(MoneyQuery.amount(from: "1,234.50") == 1234.5)
        #expect(MoneyQuery.amount(from: "1.234,50") == 1234.5)
    }

    @Test func convertsThroughTheBase() throws {
        let conversion = try #require(CurrencyConverter.conversions(for: "90 eur to dkk", rates: rates, local: "DKK").first)
        #expect(abs(conversion.value - 675) < 0.0001)
    }

    @Test func defaultsToLocalCurrencyThenEuroAndDollar() {
        #expect(CurrencyConverter.conversions(for: "10 usd", rates: rates, local: "DKK").map(\.to) == ["DKK", "EUR"])
        #expect(CurrencyConverter.conversions(for: "10 dkk", rates: rates, local: "DKK").map(\.to) == ["EUR", "USD"])
    }

    @Test func plainValueHasNoGrouping() {
        let conversion = Conversion(amount: 1, from: "USD", value: 12345.678, to: "DKK", rate: 1)
        #expect(conversion.plainValue(Locale(identifier: "en_US")) == "12345.68")
    }

    @Test func showsConversionsFirstInSearch() {
        let results = SearchResults(links: [], apps: [], usage: [:], rates: rates, locale: Locale(identifier: "da_DK")).results(for: "100 usd")
        #expect(results.first?.id == "conversion:DKK")
    }

    @Test func ratesGoStaleAfterHalfADay() {
        #expect(!rates.isStale(now: Date(timeIntervalSince1970: 3600)))
        #expect(rates.isStale(now: Date(timeIntervalSince1970: 13 * 3600)))
    }

    @Test func parsesExchangeRateResponse() throws {
        let json = #"{"result":"success","base_code":"USD","time_last_update_unix":100,"rates":{"USD":1,"DKK":6.5}}"#
        let parsed = try ExchangeRateAPI.parse(Data(json.utf8))
        #expect(parsed == CurrencyRates(base: "USD", updated: Date(timeIntervalSince1970: 100), rates: ["USD": 1, "DKK": 6.5]))
    }
}
