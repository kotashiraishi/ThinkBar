import SwiftUI

struct DebugConsoleCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject var debugLogService: DebugLogService

    var body: some Commands {
        CommandGroup(after: .windowArrangement) {
            Button("Show Debug Console") {
                guard debugLogService.isEnabled else { return }
                openWindow(id: "debug-console")
            }
            .disabled(!debugLogService.isEnabled)
        }
    }
}
