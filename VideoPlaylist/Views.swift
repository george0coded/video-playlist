import SwiftUI
import AVKit
import UniformTypeIdentifiers

// MARK: - Playlist list

struct ContentView: View {
    @EnvironmentObject var store: PlaylistStore
    @EnvironmentObject var player: PlayerManager

    @State private var showNewAlert = false
    @State private var newName = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.playlists) { playlist in
                    NavigationLink(value: playlist.id) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(playlist.name)
                            Text("\(playlist.tracks.count) videos")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { store.playlists.remove(atOffsets: $0) }
            }
            .overlay {
                if store.playlists.isEmpty {
                    ContentUnavailableView("No playlists",
                                           systemImage: "list.and.film",
                                           description: Text("Tap + to create one."))
                }
            }
            .navigationTitle("Playlists")
            .navigationDestination(for: UUID.self) { PlaylistDetailView(playlistID: $0) }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        newName = ""
                        showNewAlert = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("New Playlist", isPresented: $showNewAlert) {
                TextField("Name", text: $newName)
                Button("Create") {
                    let name = newName.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty { store.playlists.append(Playlist(name: name)) }
                }
                Button("Cancel", role: .cancel) {}
            }
            .safeAreaInset(edge: .bottom) {
                if player.isActive { MiniPlayer() }
            }
        }
        .fullScreenCover(isPresented: $player.showFullPlayer) {
            PlayerView()
        }
    }
}

// MARK: - Playlist detail

struct PlaylistDetailView: View {
    let playlistID: UUID

    @EnvironmentObject var store: PlaylistStore
    @EnvironmentObject var player: PlayerManager
    @State private var importing = false

    private var playlistIndex: Int? {
        store.playlists.firstIndex { $0.id == playlistID }
    }

    var body: some View {
        if let i = playlistIndex {
            content(i)
        } else {
            Text("Playlist not found")
        }
    }

    @ViewBuilder
    private func content(_ i: Int) -> some View {
        let playlist = store.playlists[i]

        List {
            if !playlist.tracks.isEmpty {
                Section {
                    HStack(spacing: 12) {
                        Button {
                            player.start(playlist.tracks, shuffled: false)
                        } label: {
                            Label("Play", systemImage: "play.fill").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            player.start(playlist.tracks, shuffled: true)
                        } label: {
                            Label("Shuffle", systemImage: "shuffle").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
            }

            Section {
                ForEach(playlist.tracks) { track in
                    Button {
                        player.start(playlist.tracks, at: track, shuffled: false)
                    } label: {
                        HStack {
                            Text(track.title).lineLimit(2)
                            Spacer()
                            if player.isActive, player.current?.id == track.id {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
                .onMove { store.playlists[i].tracks.move(fromOffsets: $0, toOffset: $1) }
                .onDelete { store.playlists[i].tracks.remove(atOffsets: $0) }
            }
        }
        .navigationTitle(playlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                EditButton()
                Button { importing = true } label: { Image(systemName: "plus") }
            }
        }
        .overlay {
            if playlist.tracks.isEmpty {
                ContentUnavailableView("No videos yet",
                                       systemImage: "film",
                                       description: Text("Tap + to add videos from Files."))
            }
        }
        .fileImporter(isPresented: $importing,
                      allowedContentTypes: [.movie],
                      allowsMultipleSelection: true) { result in
            if case .success(let urls) = result {
                store.add(urls: urls, to: playlistID)
            }
        }
    }
}

// MARK: - Mini player

struct MiniPlayer: View {
    @EnvironmentObject var player: PlayerManager

    var body: some View {
        HStack(spacing: 16) {
            Button { player.showFullPlayer = true } label: {
                HStack {
                    Image(systemName: "play.rectangle.fill")
                    Text(player.current?.title ?? "")
                        .lineLimit(1)
                    Spacer()
                }
            }
            .foregroundStyle(.primary)

            Button { player.next() } label: { Image(systemName: "forward.fill") }
            Button { player.stop() } label: { Image(systemName: "xmark") }
        }
        .padding()
        .background(.regularMaterial)
    }
}

// MARK: - Full player

struct PlayerView: View {
    @EnvironmentObject var player: PlayerManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: { Image(systemName: "chevron.down") }
                Spacer()
                Text(player.current?.title ?? "")
                    .lineLimit(1)
                    .font(.headline)
                Spacer()
                Button("Stop") { player.stop() }
            }
            .padding()

            VideoPlayer(player: player.player)

            if let error = player.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            HStack(spacing: 40) {
                Button { player.setShuffle(!player.isShuffled) } label: {
                    Image(systemName: "shuffle")
                        .foregroundStyle(player.isShuffled ? Color.accentColor : .white)
                }
                Button { player.previous() } label: { Image(systemName: "backward.fill") }
                Button { player.next() } label: { Image(systemName: "forward.fill") }
                Button { player.repeatAll.toggle() } label: {
                    Image(systemName: "repeat")
                        .foregroundStyle(player.repeatAll ? Color.accentColor : .white)
                }
            }
            .font(.title2)
            .padding()
        }
        .foregroundStyle(.white)
        .background(Color.black)
    }
}
