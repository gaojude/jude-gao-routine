import AppKit
import Foundation

// Stderr logging gated by BREAK_REMINDER_DEBUG=1 (used for headless verification).
func dlog(_ message: String) {
    guard ProcessInfo.processInfo.environment["BREAK_REMINDER_DEBUG"] == "1" else { return }
    FileHandle.standardError.write(Data(("[BR] " + message + "\n").utf8))
}

// Notifications via `osascript` (works for unsigned apps, never crashes) plus a
// native sound. UNUserNotificationCenter is intentionally avoided: it crashes in
// ad-hoc / unsigned command-line-built bundles.
enum Notifier {
    static func notify(title: String, body: String, sound: String = "Glass") {
        playSound(sound)
        let script = "display notification \"\(escape(body))\" with title \"\(escape(title))\""
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        p.arguments = ["-e", script]
        try? p.run()
    }

    static func playSound(_ name: String) {
        if let s = NSSound(named: NSSound.Name(name)) {
            s.play()
        } else {
            NSSound.beep()
        }
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
