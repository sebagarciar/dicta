import AppKit
import SwiftUI

struct SettingsView: View {
    @State private var holdMs = Settings.holdThresholdMs
    @State private var before = Settings.pasteDelayBeforeMs
    @State private var after = Settings.pasteDelayAfterMs
    @State private var sounds = Settings.soundsOn
    @State private var model = Settings.model
    var onModelChange: (ModelChoice) -> Void
    var onHoldChange: (Double) -> Void
    var onReloadWords: () -> Void

    var body: some View {
        Form {
            Section("Recording") {
                slider("Hold time before recording", $holdMs, 50...600, "ms")
                    .onChange(of: holdMs) { _, v in Settings.holdThresholdMs = v; onHoldChange(v) }
                Toggle("Play start and stop sounds", isOn: $sounds)
                    .onChange(of: sounds) { _, v in Settings.soundsOn = v }
            }
            Section("Pasting") {
                slider("Wait before pasting", $before, 0...300, "ms")
                    .onChange(of: before) { _, v in Settings.pasteDelayBeforeMs = v }
                slider("Wait before restoring clipboard", $after, 50...600, "ms")
                    .onChange(of: after) { _, v in Settings.pasteDelayAfterMs = v }
            }
            Section("Custom words") {
                Text("One word or phrase per line. Use it for names the model gets wrong.")
                    .font(.caption).foregroundStyle(.secondary)
                HStack {
                    Button("Open words file") { openWordsFile() }
                    Button("Reload words") { onReloadWords() }
                }
            }
            Section("Model") {
                Picker("Speech model", selection: $model) {
                    ForEach(ModelChoice.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .onChange(of: model) { _, v in Settings.model = v; onModelChange(v) }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 480)
    }

    private func openWordsFile() {
        let url = Transcriber.wordsFile
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: Transcriber.supportFolder, withIntermediateDirectories: true)
            let header = "# One word or phrase per line. Lines starting with # are ignored.\n# Example: Sapira\n"
            try? header.write(to: url, atomically: true, encoding: .utf8)
        }
        NSWorkspace.shared.open(url)
    }

    private func slider(_ title: String, _ value: Binding<Double>, _ range: ClosedRange<Double>, _ unit: String) -> some View {
        VStack(alignment: .leading) {
            Text("\(title): \(Int(value.wrappedValue)) \(unit)")
            Slider(value: value, in: range, step: 10)
        }
    }
}

@MainActor
final class SettingsWindow {
    private var window: NSWindow?

    func show(onModelChange: @escaping (ModelChoice) -> Void, onHoldChange: @escaping (Double) -> Void,
              onReloadWords: @escaping () -> Void) {
        if window == nil {
            let w = NSWindow(contentViewController: NSHostingController(
                rootView: SettingsView(onModelChange: onModelChange, onHoldChange: onHoldChange, onReloadWords: onReloadWords)))
            w.title = "Habla settings"
            w.styleMask = [.titled, .closable]
            w.isReleasedWhenClosed = false
            window = w
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }
}
