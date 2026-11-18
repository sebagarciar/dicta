import AppKit
import CoreGraphics

/// Pastes text with the clipboard, then puts the old clipboard back.
/// One paste at a time: a second call waits for the first to finish.
actor Paster {
    private var delayBefore: UInt64 { UInt64(Settings.pasteDelayBeforeMs * 1_000_000) }
    private var delayAfter: UInt64 { UInt64(Settings.pasteDelayAfterMs * 1_000_000) }

    func paste(_ text: String) async {
        let board = NSPasteboard.general
        let saved: [[(NSPasteboard.PasteboardType, Data)]] = (board.pasteboardItems ?? []).map { item in
            item.types.compactMap { type in item.data(forType: type).map { (type, $0) } }
        }
        board.clearContents()
        board.setString(text, forType: .string)
        try? await Task.sleep(nanoseconds: delayBefore)
        Self.pressCommandV()
        try? await Task.sleep(nanoseconds: delayAfter)
        // Always restore, even if the paste went nowhere.
        board.clearContents()
        let items = saved.map { entries -> NSPasteboardItem in
            let item = NSPasteboardItem()
            for (type, data) in entries { item.setData(data, forType: type) }
            return item
        }
        if !items.isEmpty { board.writeObjects(items) }
    }

    private static func pressCommandV() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let v: CGKeyCode = 9
        let down = CGEvent(keyboardEventSource: source, virtualKey: v, keyDown: true)
        let up = CGEvent(keyboardEventSource: source, virtualKey: v, keyDown: false)
        down?.flags = .maskCommand
        up?.flags = .maskCommand
        down?.post(tap: .cgAnnotatedSessionEventTap)
        up?.post(tap: .cgAnnotatedSessionEventTap)
    }
}
