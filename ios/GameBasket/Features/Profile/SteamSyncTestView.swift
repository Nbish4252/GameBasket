import SwiftUI

// TEMPORARY: validates the steam-sync Edge Function end to end before any
// real Steam-linking UI exists. Remove once that's built (profile
// settings should own steam_id entry, not a standalone test screen).
struct SteamSyncTestView: View {
    @EnvironmentObject private var appState: AppState

    @State private var steamId = ""
    @State private var statusMessage = ""
    @State private var isWorking = false
    @State private var library: [SteamLibraryEntry] = []

    var body: some View {
        Form {
            Section("Steam ID") {
                TextField("SteamID64", text: $steamId)
                    .keyboardType(.numberPad)
                Button("Save Steam ID") {
                    Task { await saveSteamId() }
                }
                .disabled(steamId.isEmpty || isWorking)
            }

            Section {
                Button("Sync Now") {
                    Task { await sync() }
                }
                .disabled(isWorking)
            }

            if !statusMessage.isEmpty {
                Section("Status") {
                    Text(statusMessage)
                }
            }

            if !library.isEmpty {
                Section("Steam Library (\(library.count))") {
                    ForEach(library, id: \.steamAppId) { entry in
                        Text("App \(entry.steamAppId) — \(entry.playtimeMinutes) min")
                    }
                }
            }
        }
        .navigationTitle("Steam Sync (Test)")
    }

    private func saveSteamId() async {
        guard let userId = appState.session?.userId else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            try await ProfileService.updateSteamId(userId: userId, steamId: steamId)
            statusMessage = "Saved Steam ID."
        } catch {
            statusMessage = "Save failed: \(error)"
        }
    }

    private func sync() async {
        guard let userId = appState.session?.userId else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            let count = try await SteamSyncService.sync()
            statusMessage = "Synced \(count) games."
            library = (try? await SteamSyncService.library(for: userId)) ?? []
        } catch {
            statusMessage = "Sync failed: \(error)"
        }
    }
}
