import AppKit

/// Small floating label near the bottom centre. It never takes focus.
@MainActor
final class Pill {
    private let panel: NSPanel
    private let label = NSTextField(labelWithString: "")

    init() {
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 150, height: 36),
                        styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        let box = NSVisualEffectView(frame: panel.contentView!.bounds)
        box.material = .hudWindow
        box.state = .active
        box.wantsLayer = true
        box.layer?.cornerRadius = 18
        box.autoresizingMask = [.width, .height]
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.alignment = .center
        label.frame = NSRect(x: 0, y: 8, width: 150, height: 20)
        label.autoresizingMask = [.width]
        box.addSubview(label)
        panel.contentView = box
    }

    func show(_ text: String) {
        label.stringValue = text
        if let screen = NSScreen.main {
            let f = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(x: f.midX - 75, y: f.minY + 60))
        }
        panel.orderFrontRegardless()
    }

    func hide() { panel.orderOut(nil) }
}
