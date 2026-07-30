import SwiftUI
import AppKit

// MARK: - Shortcut Overlay

@MainActor
final class ShortcutOverlayController {
    static let shared = ShortcutOverlayController()

    private var window: NSWindow?
    private var dismissWorkItem: DispatchWorkItem?

    private init() {}

    func show(shortcut: Shortcut, failed: Bool = false) {
        dismissWorkItem?.cancel()

        let view = ShortcutOverlayView(shortcut: shortcut, failed: failed)
        let hostingController = NSHostingController(rootView: view)

        let overlayWindow = NSWindow(contentViewController: hostingController)
        overlayWindow.styleMask = [.borderless]
        overlayWindow.backgroundColor = .clear
        overlayWindow.isOpaque = false
        overlayWindow.hasShadow = true
        overlayWindow.level = .floating
        overlayWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        overlayWindow.ignoresMouseEvents = true
        overlayWindow.setContentSize(NSSize(width: 340, height: 72))
        position(window: overlayWindow)

        window?.close()
        window = overlayWindow
        overlayWindow.orderFrontRegardless()

        let item = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.window?.close()
                self?.window = nil
            }
        }
        dismissWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + (failed ? 4.5 : 1.8), execute: item)
    }

    private func position(window: NSWindow) {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let size = window.frame.size
        let origin = NSPoint(
            x: screenFrame.midX - size.width / 2,
            y: screenFrame.maxY - size.height - 48
        )
        window.setFrameOrigin(origin)
    }
}

private struct ShortcutOverlayView: View {
    let shortcut: Shortcut
    let failed: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: failed ? "exclamationmark.triangle.fill" : "keyboard")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(failed ? Color.red : Color.accentColor)
                .frame(width: 34, height: 34)

            Text(shortcut.label.isEmpty ? L("shortcut.default_name", shortcut.keyNumber) : shortcut.label)
                .font(.system(size: 16, weight: .semibold))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .frame(width: 340, height: 72, alignment: .leading)
        .background(
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial.opacity(0.78))
                if failed {
                    Rectangle()
                        .fill(Color.red.opacity(0.20))
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(failed ? Color.red.opacity(0.75) : Color.primary.opacity(0.08), lineWidth: failed ? 1.5 : 1)
        )
    }
}
