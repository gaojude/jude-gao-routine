import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    enum Phase { case working, onBreak }

    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var phase: Phase = .working
    private var remaining = 0
    private var paused = false

    private let overlay = BreakOverlay()
    private var postponesUsed = 0
    private var warned = false
    private var eyeElapsed = 0
    private var suggestionIdx = 0

    // Fast mode (BREAK_REMINDER_FAST=1) shrinks minutes to seconds for testing.
    private let fast = ProcessInfo.processInfo.environment["BREAK_REMINDER_FAST"] == "1"

    private var workMinutes: Int { UserDefaults.standard.object(forKey: "workMinutes") as? Int ?? 45 }
    private var breakMinutes: Int { UserDefaults.standard.object(forKey: "breakMinutes") as? Int ?? 10 }
    private var workSeconds: Int { fast ? 6 : workMinutes * 60 }
    private var breakSeconds: Int { fast ? 4 : breakMinutes * 60 }

    // Behavior settings (UserDefaults-backed; sensible evidence-based defaults).
    private var strictMode: Bool { UserDefaults.standard.object(forKey: "strictBreakScreen") as? Bool ?? true }
    private var warnEnabled: Bool { UserDefaults.standard.object(forKey: "warnBeforeBreak") as? Bool ?? true }
    private var eyeEnabled: Bool { UserDefaults.standard.object(forKey: "eye202020") as? Bool ?? false }
    private var breakPlan: String {
        UserDefaults.standard.string(forKey: "breakPlan") ?? "Stand up, look out a window, and refill your water."
    }
    private var skipDelaySeconds: Int { fast ? 1 : (UserDefaults.standard.object(forKey: "skipDelaySeconds") as? Int ?? 20) }
    private var warnSeconds: Int { fast ? 3 : 60 }
    private let maxPostpones = 2
    private var postponeSeconds: Int { fast ? 3 : 5 * 60 }
    private var eyeInterval: Int { fast ? 5 : 20 * 60 }

    private let monoFont = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        overlay.onSkip = { [weak self] in self?.skipBreak() }
        overlay.onPostpone = { [weak self] in self?.postponeBreak() }

        phase = .working
        remaining = workSeconds
        updateTitle()
        startTimer()
        maybeNotifyChecklist()
        dlog("launched: work=\(workSeconds)s break=\(breakSeconds)s strict=\(strictMode)")
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

        if phase == .working {
            if warnEnabled, !warned, remaining == warnSeconds, workSeconds > warnSeconds {
                warned = true
                let when = warnSeconds >= 60 ? "1 min" : "\(warnSeconds)s"
                Notifier.notify(
                    title: "Break coming up ⏳",
                    body: "Break in \(when) — find a stopping point so you don't get pulled back mid-task.",
                    sound: "Tink")
                dlog("pre-break warning fired")
            }
            if eyeEnabled {
                eyeElapsed += 1
                if eyeElapsed >= eyeInterval {
                    eyeElapsed = 0
                    Notifier.notify(title: "Eye break 👀", body: "Look ~20 ft away for about 20 seconds.", sound: "Pop")
                    dlog("eye reminder fired")
                }
            }
        }

        if remaining <= 0 { advancePhase() }
        if phase == .onBreak, overlay.isVisible { overlay.updateCountdown(remaining: remaining) }
        updateTitle()
    }

    private func advancePhase() {
        switch phase {
        case .working:
            phase = .onBreak
            remaining = breakSeconds
            warned = false
            suggestionIdx += 1
            if strictMode {
                Notifier.playSound("Glass")
                overlay.show(
                    total: breakSeconds, skipDelay: skipDelaySeconds, plan: breakPlan,
                    allowPostpone: postponesUsed < maxPostpones, suggestionIndex: suggestionIdx)
                dlog("break started — overlay shown (postponesUsed=\(postponesUsed))")
            } else {
                Notifier.notify(
                    title: "Time for a break ☕",
                    body: "Step away for \(breakMinutes) min. \(breakPlan)", sound: "Glass")
                dlog("break started — notification only")
            }
        case .onBreak:
            phase = .working
            remaining = workSeconds
            warned = false
            eyeElapsed = 0
            postponesUsed = 0
            overlay.hide()
            Notifier.notify(title: "Break's over 💻", body: "Back to it — next break in \(workMinutes) min.", sound: "Ping")
            dlog("break ended naturally — back to work")
        }
    }

    // MARK: - Status bar title

    private func updateTitle() {
        guard let button = statusItem.button else { return }
        let emoji = paused ? "⏸" : (phase == .working ? "💻" : "☕")
        button.attributedTitle = NSAttributedString(
            string: "\(emoji) \(mmss(remaining))", attributes: [.font: monoFont])
    }

    private func mmss(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    // MARK: - Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

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

        menu.addItem(item(paused ? "Resume" : "Pause", #selector(togglePause)))
        menu.addItem(item(phase == .working ? "Start break now" : "End break now", #selector(skipPhase)))
        menu.addItem(item("Reset timer", #selector(resetTimer)))
        menu.addItem(.separator())

        menu.addItem(buildChecklistItem())
        menu.addItem(buildBreakBehaviorItem())
        menu.addItem(.separator())

        menu.addItem(buildDurationsItem())
        let login = item("Start at login", #selector(toggleLogin))
        login.state = LoginItem.isEnabled ? .on : .off
        menu.addItem(login)
        menu.addItem(.separator())

        menu.addItem(item("Quit Jude Gao Routine", #selector(quit)))
    }

    private func buildBreakBehaviorItem() -> NSMenuItem {
        let parent = NSMenuItem(title: "Break behavior", action: nil, keyEquivalent: "")
        let sub = NSMenu()

        let strict = item("Strict break screen (blocks work)", #selector(toggleStrict))
        strict.state = strictMode ? .on : .off
        sub.addItem(strict)

        let warn = item("Warn 1 min before break", #selector(toggleWarn))
        warn.state = warnEnabled ? .on : .off
        sub.addItem(warn)

        let eye = item("20-20-20 eye reminders", #selector(toggleEye))
        eye.state = eyeEnabled ? .on : .off
        sub.addItem(eye)

        sub.addItem(.separator())
        sub.addItem(item("Edit break plan…", #selector(editBreakPlan)))
        parent.submenu = sub
        return parent
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

    // MARK: - Break actions

    private func skipBreak() {
        overlay.hide()
        phase = .working
        remaining = workSeconds
        warned = false
        postponesUsed = 0
        updateTitle()
        dlog("break skipped by user")
    }

    private func postponeBreak() {
        guard postponesUsed < maxPostpones else { return }
        postponesUsed += 1
        overlay.hide()
        phase = .working
        remaining = postponeSeconds
        warned = false
        updateTitle()
        dlog("break postponed (\(postponesUsed)/\(maxPostpones))")
    }

    // MARK: - Menu actions

    @objc private func togglePause() { paused.toggle(); updateTitle() }

    @objc private func skipPhase() { advancePhase(); updateTitle() }

    @objc private func resetTimer() {
        overlay.hide()
        phase = .working
        remaining = workSeconds
        paused = false
        warned = false
        postponesUsed = 0
        eyeElapsed = 0
        updateTitle()
    }

    @objc private func toggleChecklistItem(_ sender: NSMenuItem) {
        guard let title = sender.representedObject as? String else { return }
        Checklist.toggle(title)
    }

    @objc private func resetChecklist() { Checklist.resetToday() }

    @objc private func editChecklistItems() {
        _ = Checklist.loadItems()
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

    @objc private func toggleStrict() { flip("strictBreakScreen", default: true) }
    @objc private func toggleWarn() { flip("warnBeforeBreak", default: true) }
    @objc private func toggleEye() { flip("eye202020", default: false) }

    private func flip(_ key: String, default def: Bool) {
        let current = UserDefaults.standard.object(forKey: key) as? Bool ?? def
        UserDefaults.standard.set(!current, forKey: key)
    }

    @objc private func editBreakPlan() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Your break plan"
        alert.informativeText =
            "What will you do when the timer ends? A specific “when the timer ends, I'll ___” plan makes you far more likely to actually take the break (implementation intentions, Gollwitzer & Sheeran 2006)."
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 320, height: 24))
        field.stringValue = breakPlan
        alert.accessoryView = field
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            UserDefaults.standard.set(field.stringValue, forKey: "breakPlan")
        }
    }

    @objc private func toggleLogin() {
        if LoginItem.isEnabled { LoginItem.disable() } else { LoginItem.enable() }
    }

    @objc private func quit() { NSApp.terminate(nil) }

    // MARK: - Checklist nudge (once per day)

    private func maybeNotifyChecklist() {
        guard !fast else { return }
        let (done, total) = Checklist.progress()
        let key = "checklistNotifiedDate"
        guard done == 0, UserDefaults.standard.string(forKey: key) != Checklist.todayString() else { return }
        UserDefaults.standard.set(Checklist.todayString(), forKey: key)
        Notifier.notify(
            title: "Daily checklist 📋",
            body: "\(total) items to set up your day — open the menu bar to check them off.", sound: "Tink")
    }
}
