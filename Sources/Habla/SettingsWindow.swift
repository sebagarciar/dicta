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
            Section("Model") {
                Picker("Speech model", selection: $model) {
                    ForEach(ModelChoice.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .onChange(of: model) { _, v in Settings.model = v; onModelChange(v) }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 380)
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

    func show(onModelChange: @escaping (ModelChoice) -> Void, onHoldChange: @escaping (Double) -> Void) {
        if window == nil {
            let w = NSWindow(contentViewController: NSHostingController(
                rootView: SettingsView(onModelChange: onModelChange, onHoldChange: onHoldChange)))
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
