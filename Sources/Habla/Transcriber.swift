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
        return result.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
