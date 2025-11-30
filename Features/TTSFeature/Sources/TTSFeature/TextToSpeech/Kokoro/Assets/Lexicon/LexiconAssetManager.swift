import Foundation

actor LexiconAssetManager {
    private func ensureLexiconCache() async {
        do {
            try await TtsResourceDownloader.ensureLexiconFile(named: "us_lexicon_cache.json")
        } catch {
            print("Failed to download lexicon cache: \(error.localizedDescription)")
        }
    }

    func ensureCoreAssets() async throws {
        await ensureLexiconCache()
    }
}
