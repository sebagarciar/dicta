import CoreGraphics
import Foundation

/// Watches the Right Option key. It never blocks a key: every event is passed on.
/// - Holding the key for `holdThreshold` seconds starts a recording.
/// - A tap shorter than that does nothing.
/// - Pressing any other key while Right Option is down cancels the recording
///   (for example Option+N to type a tilde).
final class HotkeyMonitor: @unchecked Sendable {
    var holdThreshold: TimeInterval = 0.15
    var onStart: (() -> Void)?
    var onStop: (() -> Void)?
    var onCancel: (() -> Void)?

    private static let rightOptionKeyCode: Int64 = 61
    private static let rightOptionDeviceBit: UInt64 = 0x40  // NX_DEVICERALTKEYMASK

    private var tap: CFMachPort?
    var isRunning: Bool { tap != nil }
    private var isDown = false
    private var isRecording = false
    private var pending: DispatchWorkItem?

    func start() -> Bool {
        let mask = (1 << CGEventType.flagsChanged.rawValue) | (1 << CGEventType.keyDown.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, refcon in
            let monitor = Unmanaged<HotkeyMonitor>.fromOpaque(refcon!).takeUnretainedValue()
            monitor.handle(type: type, event: event)
            return Unmanaged.passUnretained(event)
        }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
            eventsOfInterest: CGEventMask(mask), callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return false }
        self.tap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    private func handle(type: CGEventType, event: CGEvent) {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
        case .keyDown:
            if isDown { cancel() }
        case .flagsChanged:
            guard event.getIntegerValueField(.keyboardEventKeycode) == Self.rightOptionKeyCode else { return }
            let down = event.flags.rawValue & Self.rightOptionDeviceBit != 0
            if down && !isDown {
                isDown = true
                let work = DispatchWorkItem { [weak self] in
                    guard let self, self.isDown else { return }
                    self.isRecording = true
                    self.onStart?()
                }
                pending = work
                DispatchQueue.main.asyncAfter(deadline: .now() + holdThreshold, execute: work)
            } else if !down && isDown {
                isDown = false
                pending?.cancel()
                if isRecording {
                    isRecording = false
                    onStop?()
                }
            }
        default:
            break
        }
    }

    private func cancel() {
        pending?.cancel()
        // Stay "down" until the key is released, but do not record again.
        if isRecording {
            isRecording = false
            onCancel?()
        }
        isDown = false
    }
}
