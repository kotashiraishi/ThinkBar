import SwiftUI

struct DebugConsoleCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject var debugLogService: DebugLogService

    var body: some Commands {
        CommandGroup(after: .windowArrangement) {
            Button("Show Debug Console") {
                debugLogService.setEnabled(true)
                openWindow(id: "debug-console")
            }
        }
    }
}
