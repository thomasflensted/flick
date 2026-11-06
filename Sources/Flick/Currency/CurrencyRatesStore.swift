import FlickCore
import Foundation

final class CurrencyRatesStore {
    private let file = JSONFile<CurrencyRates>(url: AppSupport.ratesFile)
    private(set) var rates: CurrencyRates?
    private var isFetching = false
    var onUpdate: () -> Void = {}

    init() {
        rates = try? file.load()
    }

    func refreshIfStale() {
        guard !isFetching, rates?.isStale(now: Date()) ?? true else { return }
        isFetching = true
        Task { @MainActor in
            defer { isFetching = false }
            guard let (data, _) = try? await URLSession.shared.data(from: ExchangeRateAPI.url),
                  let fresh = try? ExchangeRateAPI.parse(data) else { return }
            rates = fresh
            file.save(fresh)
            onUpdate()
        }
    }
}
