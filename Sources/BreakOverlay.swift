import AppKit

// A borderless window that can become key so its buttons receive clicks even
// though the app is a menu-bar accessory.
final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// Full-screen "take a break" overlay shown on every display. Firm but not a hard
// lockout: the Skip button unlocks only after a friction delay, and a limited
// Postpone preserves autonomy (avoids psychological reactance).
final class BreakOverlay: NSObject {
    var onSkip: (() -> Void)?
    var onPostpone: (() -> Void)?

    private var windows: [NSWindow] = []
    private weak var countdownLabel: NSTextField?
    private weak var skipButton: NSButton?

    private var totalSeconds = 1
    private var skipDelay = 20

    private static let suggestions = [
        "Stand up and stretch — roll your shoulders.",
        "Look out a window at something far away.",
        "Walk over and refill your water.",
        "Step outside for a moment of fresh air.",
        "Rest your eyes — focus on something ~20 ft away.",
        "Loosen up: neck, wrists, lower back.",
    ]

    var isVisible: Bool { !windows.isEmpty }

    func show(total: Int, skipDelay: Int, plan: String, allowPostpone: Bool, suggestionIndex: Int) {
        guard windows.isEmpty else { return }
        totalSeconds = max(1, total)
        self.skipDelay = skipDelay

        // Small windowed mode for headless testing — avoids taking over the screen.
        let testUI = ProcessInfo.processInfo.environment["BREAK_REMINDER_TESTUI"] == "1"

        NSApp.activate(ignoringOtherApps: true)
        let mainScreen = NSScreen.main ?? NSScreen.screens.first

        for screen in NSScreen.screens {
            let frame = testUI
                ? NSRect(x: screen.frame.midX - 360, y: screen.frame.midY - 240, width: 720, height: 480)
                : screen.frame
            let w = OverlayWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
            w.isReleasedWhenClosed = false
            w.level = testUI ? .floating : .screenSaver
            w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            w.backgroundColor = NSColor.black.withAlphaComponent(testUI ? 0.85 : 0.92)
            w.isOpaque = false
            w.hasShadow = false

            let content = NSView(frame: frame)
            w.contentView = content
            if screen == mainScreen {
                buildContent(in: content, plan: plan, allowPostpone: allowPostpone, suggestionIndex: suggestionIndex)
            }
            w.setFrame(frame, display: true)
            w.makeKeyAndOrderFront(nil)
            windows.append(w)
            if testUI { break } // one window is enough to verify
        }
        updateCountdown(remaining: totalSeconds)
    }

    func updateCountdown(remaining: Int) {
        countdownLabel?.stringValue = mmss(remaining)
        guard let skip = skipButton else { return }
        let elapsed = totalSeconds - remaining
        if elapsed >= skipDelay {
            skip.isEnabled = true
            skip.title = "Skip break"
        } else {
            skip.isEnabled = false
            skip.title = "Skip in \(max(0, skipDelay - elapsed))s"
        }
    }

    func hide() {
        for w in windows { w.orderOut(nil); w.close() }
        windows.removeAll()
        countdownLabel = nil
        skipButton = nil
    }

    // MARK: - Content

    private func buildContent(in content: NSView, plan: String, allowPostpone: Bool, suggestionIndex: Int) {
        let title = label("Time for a break ☕", size: 34, weight: .semibold, alpha: 1.0)

        let countdown = label("0:00", size: 96, weight: .thin, alpha: 1.0)
        countdown.font = NSFont.monospacedDigitSystemFont(ofSize: 96, weight: .thin)
        countdownLabel = countdown

        let suggestion = label(
            BreakOverlay.suggestions[suggestionIndex % BreakOverlay.suggestions.count],
            size: 20, weight: .regular, alpha: 0.85)

        let planLabel = label(plan.isEmpty ? "" : "Your plan: \(plan)", size: 16, weight: .regular, alpha: 0.6)
        planLabel.isHidden = plan.isEmpty

        var buttonViews: [NSView] = []
        if allowPostpone {
            let postpone = NSButton(title: "Postpone 5 min", target: self, action: #selector(postponeTapped))
            postpone.bezelStyle = .rounded
            postpone.controlSize = .large
            buttonViews.append(postpone)
        }
        let skip = NSButton(title: "Skip in \(skipDelay)s", target: self, action: #selector(skipTapped))
        skip.bezelStyle = .rounded
        skip.controlSize = .large
        skip.isEnabled = false
        skipButton = skip
        buttonViews.append(skip)

        let buttonRow = NSStackView(views: buttonViews)
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 16

        let stack = NSStackView(views: [title, countdown, suggestion, planLabel, buttonRow])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.setCustomSpacing(28, after: countdown)
        stack.setCustomSpacing(34, after: planLabel)
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: content.centerYAnchor),
        ])
    }

    private func label(_ text: String, size: CGFloat, weight: NSFont.Weight, alpha: CGFloat) -> NSTextField {
        let l = NSTextField(labelWithString: text)
        l.font = NSFont.systemFont(ofSize: size, weight: weight)
        l.textColor = NSColor.white.withAlphaComponent(alpha)
        l.alignment = .center
        l.backgroundColor = .clear
        l.isBezeled = false
        l.isEditable = false
        return l
    }

    private func mmss(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    @objc private func skipTapped() { onSkip?() }
    @objc private func postponeTapped() { onPostpone?() }
}
