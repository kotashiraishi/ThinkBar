import Foundation
import Testing
@testable import ThinkBarCore

struct ConversationRenderingPerformanceTests {
    @Test func measuredFormatterReportsMarkdownAndAssembly() {
        let text = "Hello **world**\n\n```\ncode\n```\n"
        let measured = AssistantResponseFormatter
            .markdownPreservingWhitespaceMeasured(text)

        #expect(!String(measured.value.characters).isEmpty)
        #expect(measured.breakdown.proseSegmentCount >= 1)
        #expect(measured.breakdown.codeSegmentCount == 1)
        #expect(measured.breakdown.total >= measured.breakdown.markdownParse)
    }

    @Test func renderingReportHighlightsSlowestTurn() {
        let slowID = UUID()
        let report = ConversationRenderingPerformanceReport(
            experiment: .normalMarkdown,
            conversationID: UUID(),
            conversationTitle: "Sample",
            visibleTurnCount: 2,
            formattedTurnCount: 2,
            turnTimings: [
                .init(
                    id: UUID(),
                    index: 0,
                    characterCount: 10,
                    usedFormatter: true,
                    formatterTotal: .milliseconds(1)
                ),
                .init(
                    id: slowID,
                    index: 1,
                    characterCount: 500,
                    usedFormatter: true,
                    markdownParse: .milliseconds(8),
                    attributedStringCreation: .milliseconds(2),
                    formatterTotal: .milliseconds(12)
                ),
            ],
            formatterTotal: .milliseconds(13)
        )

        #expect(report.slowestTurn?.id == slowID)
        #expect(report.formattedSummary.contains("Experiment: A:"))
        #expect(report.formattedSummary.contains("Slowest turn:"))
        #expect(report.formattedSummary.contains("Markdown parse:"))
    }
}
