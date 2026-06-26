import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    enum Phase { case working, onBreak }

    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var phase: Phase = .working
    private var remaining = 0
    private var paused = false

    // Fast mode (set BREAK_REMINDER_FAST=1) shrinks minutes to seconds for testing.
    private let fast = ProcessInfo.processInfo.environment["BREAK_REMINDER_FAST"] == "1"

    private var workMinutes: Int { UserDefaults.standard.object(forKey: "workMinutes") as? Int ?? 45 }
    private var breakMinutes: Int { UserDefaults.standard.object(forKey: "breakMinutes") as? Int ?? 10 }
    private var workSeconds: Int { fast ? 5 : workMinutes * 60 }
    private var breakSeconds: Int { fast ? 3 : breakMinutes * 60 }

    private let monoFont = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        phase = .working
        remaining = workSeconds
        updateTitle()
        startTimer()
        maybeNotifyChecklist()
    }

    // MARK: - Timer

    private func startTimer() {
        timer?.invalidate()
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in self?.tick() }
        t.tolerance = 0.2
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        guard !paused else { return }
        remaining -= 1
        if remaining <= 0 {
            advancePhase()
        }
        updateTitle()
    }

    private func advancePhase() {
        switch phase {
        case .working:
            phase = .onBreak
            remaining = breakSeconds
            Notifier.notify(
                title: "Time for a break ☕",
                body: "Step away for \(breakMinutes) min. Look ~20 ft away, stand up, hydrate.",
                sound: "Glass")
        case .onBreak:
            phase = .working
            remaining = workSeconds
            Notifier.notify(
                title: "Break's over 💻",
                body: "Back to it — next break in \(workMinutes) min.",
                sound: "Ping")
        }
    }

    // MARK: - Status bar title

    private func updateTitle() {
        guard let button = statusItem.button else { return }
        let emoji = paused ? "⏸" : (phase == .working ? "💻" : "☕")
        let text = "\(emoji) \(mmss(remaining))"
        button.attributedTitle = NSAttributedString(string: text, attributes: [.font: monoFont])
    }

    private func mmss(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    // MARK: - Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        // Status line
        let statusText: String
        if paused {
            statusText = "⏸ Paused"
        } else if phase == .working {
            statusText = "💻 Working — \(mmss(remaining)) until break"
        } else {
            statusText = "☕ On break — \(mmss(remaining)) left"
        }
        let status = NSMenuItem(title: statusText, action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        menu.addItem(.separator())

        // Controls
        menu.addItem(item(paused ? "Resume" : "Pause", #selector(togglePause)))
        let skipTitle = phase == .working ? "Start break now" : "End break now"
        menu.addItem(item(skipTitle, #selector(skipPhase)))
        menu.addItem(item("Reset timer", #selector(resetTimer)))
        menu.addItem(.separator())

        // Daily checklist
        menu.addItem(buildChecklistItem())
        menu.addItem(.separator())

        // Settings
        menu.addItem(buildDurationsItem())
        let login = item("Start at login", #selector(toggleLogin))
        login.state = LoginItem.isEnabled ? .on : .off
        menu.addItem(login)
        menu.addItem(.separator())

        menu.addItem(item("Quit Jude Gao Routine", #selector(quit)))
    }

    private func buildChecklistItem() -> NSMenuItem {
        let items = Checklist.loadItems()
        let done = Checklist.doneItems()
        let (d, total) = Checklist.progress()

        let parent = NSMenuItem(title: "Daily checklist — \(d)/\(total)", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        for title in items {
            let mi = NSMenuItem(title: title, action: #selector(toggleChecklistItem(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = title
            mi.state = done.contains(title) ? .on : .off
            sub.addItem(mi)
        }
        sub.addItem(.separator())
        sub.addItem(item("Reset checklist", #selector(resetChecklist)))
        sub.addItem(item("Edit items…", #selector(editChecklistItems)))
        parent.submenu = sub
        return parent
    }

    private func buildDurationsItem() -> NSMenuItem {
        let parent = NSMenuItem(
            title: "Durations: \(workMinutes) / \(breakMinutes) min", action: nil, keyEquivalent: "")
        let sub = NSMenu()

        let workHeader = NSMenuItem(title: "Work interval", action: nil, keyEquivalent: "")
        workHeader.isEnabled = false
        sub.addItem(workHeader)
        for m in [25, 45, 50, 60] {
            let mi = NSMenuItem(title: "\(m) min", action: #selector(setWork(_:)), keyEquivalent: "")
            mi.target = self
            mi.tag = m
            mi.state = (m == workMinutes) ? .on : .off
            sub.addItem(mi)
        }
        sub.addItem(.separator())
        let breakHeader = NSMenuItem(title: "Break length", action: nil, keyEquivalent: "")
        breakHeader.isEnabled = false
        sub.addItem(breakHeader)
        for m in [5, 10, 15] {
            let mi = NSMenuItem(title: "\(m) min", action: #selector(setBreak(_:)), keyEquivalent: "")
            mi.target = self
            mi.tag = m
            mi.state = (m == breakMinutes) ? .on : .off
            sub.addItem(mi)
        }
        parent.submenu = sub
        return parent
    }

    private func item(_ title: String, _ action: Selector) -> NSMenuItem {
        let mi = NSMenuItem(title: title, action: action, keyEquivalent: "")
        mi.target = self
        return mi
    }

    // MARK: - Actions

    @objc private func togglePause() {
        paused.toggle()
        updateTitle()
    }

    @objc private func skipPhase() {
        advancePhase()
        updateTitle()
    }

    @objc private func resetTimer() {
        phase = .working
        remaining = workSeconds
        paused = false
        updateTitle()
    }

    @objc private func toggleChecklistItem(_ sender: NSMenuItem) {
        guard let title = sender.representedObject as? String else { return }
        Checklist.toggle(title)
    }

    @objc private func resetChecklist() {
        Checklist.resetToday()
    }

    @objc private func editChecklistItems() {
        _ = Checklist.loadItems() // ensure the file exists
        NSWorkspace.shared.open(Checklist.itemsFile)
    }

    @objc private func setWork(_ sender: NSMenuItem) {
        UserDefaults.standard.set(sender.tag, forKey: "workMinutes")
        if phase == .working { remaining = workSeconds }
        updateTitle()
    }

    @objc private func setBreak(_ sender: NSMenuItem) {
        UserDefaults.standard.set(sender.tag, forKey: "breakMinutes")
        if phase == .onBreak { remaining = breakSeconds }
        updateTitle()
    }

    @objc private func toggleLogin() {
        if LoginItem.isEnabled { LoginItem.disable() } else { LoginItem.enable() }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    // MARK: - Checklist nudge (once per day)

    private func maybeNotifyChecklist() {
        guard !fast else { return }
        let (done, total) = Checklist.progress()
        let key = "checklistNotifiedDate"
        guard done == 0, UserDefaults.standard.string(forKey: key) != Checklist.todayString() else { return }
        UserDefaults.standard.set(Checklist.todayString(), forKey: key)
        Notifier.notify(
            title: "Daily checklist 📋",
            body: "\(total) items to set up your day — open the menu bar to check them off.",
            sound: "Tink")
    }
}
