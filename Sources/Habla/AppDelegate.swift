import AppKit
import AVFoundation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let statusLine = NSMenuItem(title: "Starting...", action: nil, keyEquivalent: "")
    private let hotkey = HotkeyMonitor()
    private let recorder = AudioRecorder()
    private let transcriber = Transcriber()
    private let paster = Paster()
    private let pill = Pill()
    private var model: ModelChoice = .ultra
    private var modelItems: [ModelChoice: NSMenuItem] = [:]
    private var ready = false
    private var busy = false
    private var retryTimer: Timer?
    private var hotkeyActive: Bool { hotkey.isRunning }

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenu()
        setStatus("Checking permissions...")
        requestPermissions()
        hotkey.onStart = { [weak self] in Task { @MainActor in self?.startRecording() } }
        hotkey.onStop = { [weak self] in Task { @MainActor in self?.stopRecording() } }
        hotkey.onCancel = { [weak self] in Task { @MainActor in self?.cancelRecording() } }
        loadModel()
    }

    // MARK: Menu

    private func buildMenu() {
        statusItem.button?.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "Habla")
        let menu = NSMenu()
        menu.addItem(statusLine)
        menu.addItem(.separator())
        for choice in ModelChoice.allCases {
            let item = NSMenuItem(title: choice.rawValue, action: #selector(pickModel(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = choice.rawValue
            item.state = choice == model ? .on : .off
            modelItems[choice] = item
            menu.addItem(item)
        }
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Habla", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    private func setStatus(_ text: String) { statusLine.title = text }

    @objc private func pickModel(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let choice = ModelChoice(rawValue: raw), choice != model else { return }
        model = choice
        for (c, item) in modelItems { item.state = c == choice ? .on : .off }
        loadModel()
    }

    // MARK: Permissions

    private func requestPermissions() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            if !granted {
                Task { @MainActor in
                    self.explain("Habla needs the microphone to hear you.",
                                 url: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
                }
            }
        }
        if !CGPreflightListenEventAccess() { _ = CGRequestListenEventAccess() }
        if !hotkey.start() {
            setStatus(permissionMessage())
            retryHotkey()
            explain("Habla needs Accessibility access to see the Right Option key and to paste. Turn it on for Habla, then open Habla again.",
                    url: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
            // Ask macOS to show its own prompt entry for this app.
            let key = "AXTrustedCheckOptionPrompt" as CFString
            _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
        }
    }

    private func permissionMessage() -> String {
        if !AXIsProcessTrusted() { return "Needs Accessibility permission" }
        if !CGPreflightListenEventAccess() { return "Needs Input Monitoring permission" }
        return "Hotkey failed to start"
    }

    /// Keeps trying until the user turns Accessibility on, so no restart is needed.
    private func retryHotkey() {
        retryTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.setStatus(self.hotkey.isRunning ? "Ready" : self.permissionMessage())
                if self.hotkey.start() {
                    self.retryTimer?.invalidate()
                    self.setStatus(self.ready ? "Ready" : "Loading \(self.model.rawValue)...")
                }
            }
        }
    }

    private func explain(_ message: String, url: String) {
        let alert = NSAlert()
        alert.messageText = "Permission needed"
        alert.informativeText = message
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Not now")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn, let u = URL(string: url) {
            NSWorkspace.shared.open(u)
        }
    }

    // MARK: Model

    private func loadModel() {
        ready = false
        setStatus("Loading \(model.rawValue)...")
        let choice = model
        Task {
            do {
                try await transcriber.load(choice)
                guard choice == model else { return }
                ready = true
                setStatus(hotkeyActive ? "Ready" : permissionMessage())
            } catch {
                setStatus("Model failed to load")
            }
        }
    }

    // MARK: Dictation

    private func startRecording() {
        guard ready, !busy else { return }
        do {
            try recorder.start()
            NSSound(named: "Tink")?.play()
            setStatus("Listening")
            pill.show("Listening")
        } catch {
            setStatus("Microphone error")
        }
    }

    private func cancelRecording() {
        _ = recorder.stop()
        pill.hide()
        setStatus("Ready")
    }

    private func stopRecording() {
        let samples = recorder.stop()
        NSSound(named: "Pop")?.play()
        guard samples.count > 8000 else { pill.hide(); setStatus("Ready"); return }  // under 0.5 s
        busy = true
        setStatus("Transcribing")
        pill.show("Transcribing")
        Task {
            let text = (try? await transcriber.transcribe(samples)) ?? ""
            pill.hide()
            if !text.isEmpty { await paster.paste(text) }
            busy = false
            setStatus("Ready")
        }
    }
}
