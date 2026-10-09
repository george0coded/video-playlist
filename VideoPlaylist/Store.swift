import Foundation

struct Track: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    /// Bookmark to the original file so we can reopen it after the app restarts.
    var bookmark: Data
}

struct Playlist: Identifiable, Codable {
    var id = UUID()
    var name: String
    var tracks: [Track] = []
}

@MainActor
final class PlaylistStore: ObservableObject {
    @Published var playlists: [Playlist] = [] {
        didSet { save() }
    }

    private let fileURL = URL.documentsDirectory.appending(path: "playlists.json")

    init() {
        load()
    }

    /// Adds files picked with the file importer to a playlist.
    func add(urls: [URL], to playlistID: UUID) {
        guard let i = playlists.firstIndex(where: { $0.id == playlistID }) else { return }
        for url in urls {
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            guard let data = try? url.bookmarkData(options: [],
                                                   includingResourceValuesForKeys: nil,
                                                   relativeTo: nil) else { continue }
            let title = url.deletingPathExtension().lastPathComponent
            playlists[i].tracks.append(Track(title: title, bookmark: data))
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Playlist].self, from: data) else { return }
        playlists = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(playlists) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
