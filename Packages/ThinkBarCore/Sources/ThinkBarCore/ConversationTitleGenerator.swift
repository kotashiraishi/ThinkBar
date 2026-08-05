import Foundation

/// Lightweight local title generation from the first user message.
/// Does not call an AI provider.
public enum ConversationTitleGenerator: Sendable {
    public static let placeholder = "New Conversation"
    public static let maxLength = 24

    public static func title(
        fromUserMessage message: String
    ) -> String {
        var text = firstLine(of: message)
        guard !text.isEmpty else { return placeholder }

        text = stripTrailingNoise(from: text)
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return placeholder }

        if text.count <= maxLength {
            return text
        }

        let end = text.index(text.startIndex, offsetBy: maxLength)
        return String(text[..<end]) + "…"
    }

    public static func title(
        from turns: [ConversationRecord]
    ) -> String {
        guard let firstUser = turns.first?.user else {
            return placeholder
        }
        return title(fromUserMessage: firstUser)
    }

    private static func firstLine(of message: String) -> String {
        let trimmed = message.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard let line = trimmed.split(
            whereSeparator: \.isNewline
        ).first else {
            return ""
        }
        return String(line).trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private static func stripTrailingNoise(from text: String) -> String {
        let suffixes = [
            "を相談したい",
            "について相談したい",
            "について聞きたい",
            "について",
            "を教えてください",
            "を教えて",
            "してください",
            "したいです",
            "したい",
            "ですか",
            "でしょうか",
            "？",
            "?",
            "。",
        ]

        var result = text
        for suffix in suffixes {
            if result.hasSuffix(suffix) {
                result = String(result.dropLast(suffix.count))
                break
            }
        }
        return result
    }
}
