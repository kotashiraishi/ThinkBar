import Combine
import ThinkBarCore

@MainActor
final class DebugLogService: ObservableObject, DebugLogRecording {
    @Published var isEnabled = false
    @Published private(set) var entries: [DebugLogEntry] = []

    func loggingEnabled() async -> Bool {
        isEnabled
    }

    func record(_ entry: DebugLogEntry) async {
        guard isEnabled else { return }
        entries.insert(entry, at: 0)
    }

    func clear() {
        entries.removeAll()
    }
}
