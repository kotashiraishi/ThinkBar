import Combine
import ThinkBarCore

@MainActor
final class DebugLogService: ObservableObject, DebugLogRecording {
    @Published private(set) var isEnabled = false
    @Published private(set) var entries: [DebugLogEntry] = []

    func loggingEnabled() async -> Bool {
        isEnabled
    }

    func record(_ entry: DebugLogEntry) async {
        guard isEnabled else { return }
        entries.insert(entry, at: 0)
    }

    func setEnabled(_ isEnabled: Bool) {
        guard self.isEnabled != isEnabled else { return }

        self.isEnabled = isEnabled
        if !isEnabled {
            clear()
        }
    }

    func clear() {
        entries.removeAll()
    }
}
