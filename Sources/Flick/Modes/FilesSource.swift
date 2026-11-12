import FlickCore

final class FilesSource: ModeSource {
    var onUpdate: () -> Void {
        get { search.onUpdate }
        set { search.onUpdate = newValue }
    }
    private let search = FileSearch()

    func enter() {
        search.clear()
    }

    func queryChanged(_ query: String) {
        search.search(query)
    }

    func results(for query: String) -> [ResultItem] {
        FileResults.results(for: query, in: search.files)
    }
}
