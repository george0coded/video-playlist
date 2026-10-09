import AVKit
import MediaPlayer

@MainActor
final class PlayerManager: ObservableObject {
    let player = AVPlayer()

    @Published private(set) var queue: [Track] = []
    @Published private(set) var index = 0
    @Published private(set) var isActive = false
    @Published private(set) var isShuffled = false
    @Published var repeatAll = true
    @Published var showFullPlayer = false
    @Published var errorMessage: String?

    private var original: [Track] = []
    private var scopedURL: URL?

    var current: Track? {
        queue.indices.contains(index) ? queue[index] : nil
    }

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.next() }
        }
        setupRemoteCommands()
    }

    // MARK: - Starting / stopping

    func start(_ tracks: [Track], at startTrack: Track? = nil, shuffled: Bool) {
        guard !tracks.isEmpty else { return }
        original = tracks
        isShuffled = shuffled

        if shuffled {
            var q = tracks.shuffled()
            if let startTrack, let i = q.firstIndex(where: { $0.id == startTrack.id }) {
                q.swapAt(0, i)
            }
            queue = q
            index = 0
        } else {
            queue = tracks
            index = startTrack.flatMap { s in tracks.firstIndex(where: { $0.id == s.id }) } ?? 0
        }

        isActive = true
        showFullPlayer = true
        load()
    }

    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        releaseScopedURL()
        isActive = false
        showFullPlayer = false
        queue = []
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: - Controls

    func setShuffle(_ on: Bool) {
        isShuffled = on
        guard let cur = current else { return }
        if on {
            let rest = original.filter { $0.id != cur.id }.shuffled()
            queue = [cur] + rest
            index = 0
        } else {
            queue = original
            index = original.firstIndex(where: { $0.id == cur.id }) ?? 0
        }
    }

    func next() {
        guard !queue.isEmpty else { return }
        if index + 1 < queue.count {
            index += 1
        } else if repeatAll {
            if isShuffled { queue.shuffle() }
            index = 0
        } else {
            player.pause()
            return
        }
        load()
    }

    func previous() {
        guard !queue.isEmpty else { return }
        if player.currentTime().seconds > 3 {
            player.seek(to: .zero)
            return
        }
        index = index > 0 ? index - 1 : (repeatAll ? queue.count - 1 : 0)
        load()
    }

    // MARK: - Loading

    private func load() {
        releaseScopedURL()
        guard let track = current else { return }

        var stale = false
        guard let url = try? URL(resolvingBookmarkData: track.bookmark,
                                 options: [],
                                 relativeTo: nil,
                                 bookmarkDataIsStale: &stale) else {
            errorMessage = "Couldn't open \"\(track.title)\". The file may have been moved or deleted."
            player.pause()
            return
        }

        if url.startAccessingSecurityScopedResource() { scopedURL = url }
        errorMessage = nil
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
        player.play()

        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: track.title
        ]
    }

    private func releaseScopedURL() {
        scopedURL?.stopAccessingSecurityScopedResource()
        scopedURL = nil
    }

    // MARK: - Lock screen / headphone controls

    private func setupRemoteCommands() {
        let c = MPRemoteCommandCenter.shared()
        c.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.player.play() }
            return .success
        }
        c.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.player.pause() }
            return .success
        }
        c.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.next() }
            return .success
        }
        c.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.previous() }
            return .success
        }
    }
}
