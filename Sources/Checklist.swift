import Foundation

// A daily checklist. Item titles live in a JSON file the user can edit; per-item
// "done" state lives in UserDefaults and resets automatically at each new day.
enum Checklist {
    static let defaults = [
        "Ensure room lighting is good",
        "Adjust monitor to eye level",
        "Fill up water bottle",
        "Clear desk clutter",
        "Set posture: back straight, feet flat",
    ]

    static let supportDir: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("JudeGaoRoutine", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static var itemsFile: URL { supportDir.appendingPathComponent("checklist.json") }

    // MARK: - Items (editable)

    static func loadItems() -> [String] {
        if let data = try? Data(contentsOf: itemsFile),
           let arr = try? JSONDecoder().decode([String].self, from: data),
           !arr.isEmpty {
            return arr
        }
        saveItems(defaults)
        return defaults
    }

    static func saveItems(_ items: [String]) {
        let data = try? JSONEncoder().encode(items)
        try? data?.write(to: itemsFile)
    }

    // MARK: - Daily completion state

    private static let doneKey = "checklistDone"
    private static let dateKey = "checklistDate"

    static func todayString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: Date())
    }

    private static func resetIfNewDay() {
        let d = UserDefaults.standard
        if d.string(forKey: dateKey) != todayString() {
            d.set(todayString(), forKey: dateKey)
            d.set([String](), forKey: doneKey)
        }
    }

    static func doneItems() -> Set<String> {
        resetIfNewDay()
        return Set(UserDefaults.standard.stringArray(forKey: doneKey) ?? [])
    }

    static func toggle(_ item: String) {
        var set = doneItems()
        if set.contains(item) { set.remove(item) } else { set.insert(item) }
        UserDefaults.standard.set(Array(set), forKey: doneKey)
    }

    static func resetToday() {
        UserDefaults.standard.set(todayString(), forKey: dateKey)
        UserDefaults.standard.set([String](), forKey: doneKey)
    }

    /// "2/5"
    static func progress() -> (done: Int, total: Int) {
        let items = loadItems()
        let done = doneItems().intersection(items)
        return (done.count, items.count)
    }
}
