import Foundation

struct Attachment: Identifiable {
    let id = UUID()
    let fileName: String
    let content: String
}
