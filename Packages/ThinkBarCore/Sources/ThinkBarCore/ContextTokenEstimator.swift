import Foundation

public struct ContextTokenEstimator: Sendable {
    public init() {}

    public func estimateTokens(in text: String) -> Int {
        guard !text.isEmpty else { return 0 }

        var cjkCharacters = 0
        var otherCharacters = 0
        for scalar in text.unicodeScalars {
            if CharacterSet.whitespacesAndNewlines.contains(scalar) {
                continue
            }
            if isCJK(scalar) {
                cjkCharacters += 1
            } else {
                otherCharacters += 1
            }
        }

        return cjkCharacters + Int(ceil(Double(otherCharacters) / 4))
    }

    private func isCJK(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x3040...0x30FF,
             0x3400...0x4DBF,
             0x4E00...0x9FFF,
             0xAC00...0xD7AF:
            true
        default:
            false
        }
    }
}

public struct ContextSizeEstimate: Equatable, Sendable {
    public let characters: Int
    public let estimatedTokens: Int

    public init(characters: Int, estimatedTokens: Int) {
        self.characters = characters
        self.estimatedTokens = estimatedTokens
    }
}

public struct ContextHistoryStatistics: Equatable, Sendable {
    public let turns: Int
    public let size: ContextSizeEstimate

    public init(turns: Int, size: ContextSizeEstimate) {
        self.turns = turns
        self.size = size
    }
}

public struct ConversationContextStatistics: Equatable, Sendable {
    public let summary: ContextSizeEstimate
    public let recentHistory: ContextHistoryStatistics
    public let currentMessage: ContextSizeEstimate
    public let total: ContextSizeEstimate

    public init(
        summary: ContextSizeEstimate,
        recentHistory: ContextHistoryStatistics,
        currentMessage: ContextSizeEstimate,
        total: ContextSizeEstimate
    ) {
        self.summary = summary
        self.recentHistory = recentHistory
        self.currentMessage = currentMessage
        self.total = total
    }
}
