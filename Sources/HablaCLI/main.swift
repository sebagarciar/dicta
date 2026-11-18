import AVFoundation
import FluidAudio
import Foundation

// Usage: HablaCLI <ultra|v3> <clip.wav> [more clips...]
// Prints, per clip: the text, and the seconds from "stop" to "text ready".

func loadSamples(_ path: String) throws -> [Float] {
    let file = try AVAudioFile(forReading: URL(fileURLWithPath: path))
    let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)!
    guard let converter = AVAudioConverter(from: file.processingFormat, to: format),
          let input = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))
    else { throw NSError(domain: "habla", code: 1) }
    try file.read(into: input)
    let ratio = 16000 / file.processingFormat.sampleRate
    let out = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(Double(input.frameLength) * ratio) + 1024)!
    var fed = false
    var error: NSError?
    converter.convert(to: out, error: &error) { _, status in
        if fed { status.pointee = .endOfStream; return nil }
        fed = true
        status.pointee = .haveData
        return input
    }
    if let error { throw error }
    return Array(UnsafeBufferPointer(start: out.floatChannelData![0], count: Int(out.frameLength)))
}

let args = CommandLine.arguments
guard args.count >= 3 else {
    print("Usage: HablaCLI <ultra|v3> <clip.wav> [more clips...]")
    exit(1)
}
let version: AsrModelVersion = args[1] == "v3" ? .v3 : .ultra

let loadStart = Date()
// v3 can be read from OpenOats if it is installed (read only), so it needs no download.
let v3Folder = URL(fileURLWithPath: NSHomeDirectory())
    .appendingPathComponent("Library/Application Support/OpenOats/Models/Transcription/parakeet/parakeet-v3/parakeet-tdt-0.6b-v3")
let models = (version == .v3 && FileManager.default.fileExists(atPath: v3Folder.path))
    ? try await AsrModels.load(from: v3Folder, version: .v3)
    : try await AsrModels.downloadAndLoad(version: version)
let asr = AsrManager(config: .default)
try await asr.loadModels(models)
print("model \(args[1]) loaded in \(String(format: "%.1f", Date().timeIntervalSince(loadStart))) s")

for path in args.dropFirst(2) {
    let samples = try loadSamples(path)
    let seconds = Double(samples.count) / 16000
    // Run each clip twice: the first run warms up the model, the second is the real timing.
    var text = ""
    var elapsed = 0.0
    for _ in 0..<2 {
        var state = TdtDecoderState.make(decoderLayers: await asr.decoderLayerCount)
        let t0 = Date()
        let result = try await asr.transcribe(samples, decoderState: &state)
        elapsed = Date().timeIntervalSince(t0)
        text = result.text
    }
    print("\(URL(fileURLWithPath: path).lastPathComponent) | \(String(format: "%.1f", seconds)) s audio | \(String(format: "%.2f", elapsed)) s | \(text)")
}
