import FluidAudio
import Foundation

enum ModelChoice: String, CaseIterable {
    case ultra = "Parakeet Ultra"
    case v3 = "Parakeet v3"
}

/// Loads the speech model once and keeps it in memory.
actor Transcriber {
    private var asr: AsrManager?
    private var vad: VadManager?
    private var boosting: VocabularyBoostingSession?
    private var ctc: CtcModels?

    /// Folder for the user's own files. Outside the repo on purpose.
    static var supportFolder: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Habla")
    }
    static var wordsFile: URL { supportFolder.appendingPathComponent("words.txt") }

    /// Reads words.txt (one word or phrase per line, # for comments) and prepares word boosting.
    /// Returns how many words are active. An empty list turns boosting off.
    func loadWords() async -> Int {
        let text = (try? String(contentsOf: Self.wordsFile, encoding: .utf8)) ?? ""
        let words = text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
        guard !words.isEmpty else { boosting = nil; return 0 }
        do {
            if ctc == nil { ctc = try await CtcModels.downloadAndLoad(variant: .ctc110m) }
            // "Word = alias1, alias2": the aliases are what the model tends to hear instead.
            let terms = words.map { line -> CustomVocabularyTerm in
                let parts = line.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                let aliases = parts.count > 1
                    ? parts[1].split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                    : []
                return CustomVocabularyTerm(text: parts[0], aliases: aliases.isEmpty ? nil : aliases)
            }
            let vocab = CustomVocabularyContext(terms: terms)
            // Tested setting: the aggressive rescue pass is off because it swapped correct
            // words for custom ones. A wrong replacement costs more than a miss.
            boosting = try await VocabularyBoostingSession(
                vocabulary: vocab, ctcModels: ctc!,
                config: VocabularyRescorer.Config(spotterRescueEnabled: false),
                thresholds: .init(cbw: 0, minSimilarity: 0.7))
            return terms.count
        } catch {
            boosting = nil
            return 0
        }
    }

    func load(_ choice: ModelChoice) async throws {
        asr = nil
        let models: AsrModels
        switch choice {
        case .ultra:
            models = try await AsrModels.downloadAndLoad(version: .ultra)
        case .v3:
            // Reuse the copy OpenOats already has (read only) so there is no download.
            let folder = URL(fileURLWithPath: NSHomeDirectory())
                .appendingPathComponent("Library/Application Support/OpenOats/Models/Transcription/parakeet/parakeet-v3/parakeet-tdt-0.6b-v3")
            if FileManager.default.fileExists(atPath: folder.path) {
                models = try await AsrModels.load(from: folder, version: .v3)
            } else {
                models = try await AsrModels.downloadAndLoad(version: .v3)
            }
        }
        let manager = AsrManager(config: .default)
        try await manager.loadModels(models)
        asr = manager
        if vad == nil { vad = try? await VadManager() }
    }

    /// Returns the text, or an empty string if there was no speech.
    func transcribe(_ samples: [Float]) async throws -> String {
        guard let asr else { return "" }
        var audio = samples
        if let vad, let parts = try? await vad.segmentSpeechAudio(samples) {
            if parts.isEmpty { return "" }
            let gap = [Float](repeating: 0, count: 3200)  // 0.2 s of silence between parts
            audio = parts.enumerated().flatMap { $0.offset == 0 ? $0.element : gap + $0.element }
        }
        var state = TdtDecoderState.make(decoderLayers: await asr.decoderLayerCount)
        let result = try await asr.transcribe(audio, decoderState: &state)
        var text = result.text
        if let boosting,
           let out = await boosting.rescore(text: text, tokenTimings: result.tokenTimings ?? [], audioSamples: audio) {
            text = out.text
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
