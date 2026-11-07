import FlickCore
import MapKit

final class PlaceSuggester: NSObject, Suggesting, MKLocalSearchCompleterDelegate {
    var onUpdate: () -> Void = {}
    private(set) var suggestions: [String] = []
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func suggest(_ query: String) {
        let text = query.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { clear(); return }
        completer.queryFragment = text
    }

    func clear() {
        completer.cancel()
        suggestions = []
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = completer.results.prefix(GoogleSuggest.limit).map { Suggestions.placeText(title: $0.title, subtitle: $0.subtitle) }
        onUpdate()
    }
}
