import Foundation

public struct AssistantResponseFormatBreakdown: Equatable, Sendable {
    public var markdownParse: Duration
    public var attributedStringCreation: Duration
    public var assembly: Duration
    public var total: Duration
    public var proseSegmentCount: Int
    public var codeSegmentCount: Int

    public init(
        markdownParse: Duration = .zero,
        attributedStringCreation: Duration = .zero,
        assembly: Duration = .zero,
        total: Duration = .zero,
        proseSegmentCount: Int = 0,
        codeSegmentCount: Int = 0
    ) {
        self.markdownParse = markdownParse
        self.attributedStringCreation = attributedStringCreation
        self.assembly = assembly
        self.total = total
        self.proseSegmentCount = proseSegmentCount
        self.codeSegmentCount = codeSegmentCount
    }
}

public enum AssistantResponseFormatter {
    public static func markdownPreservingWhitespace(
        _ text: String
    ) -> AttributedString {
        markdownPreservingWhitespaceMeasured(text).value
    }

    public static func markdownPreservingWhitespaceMeasured(
        _ text: String
    ) -> (value: AttributedString, breakdown: AssistantResponseFormatBreakdown) {
        let clock = ContinuousClock()
        let started = clock.now
        var output = AttributedString()
        var cursor = text.startIndex
        var breakdown = AssistantResponseFormatBreakdown()

        while let openingRange = text.range(
            of: "```",
            range: cursor..<text.endIndex
        ) {
            guard let closingRange = text.range(
                of: "```",
                range: openingRange.upperBound..<text.endIndex
            ) else {
                appendProseMeasured(
                    String(text[cursor...]),
                    to: &output,
                    breakdown: &breakdown,
                    clock: clock
                )
                breakdown.total = clock.now - started
                return (output, breakdown)
            }

            appendProseMeasured(
                String(text[cursor..<openingRange.lowerBound]),
                to: &output,
                breakdown: &breakdown,
                clock: clock
            )
            appendCodeMeasured(
                String(text[openingRange.upperBound..<closingRange.lowerBound]),
                to: &output,
                breakdown: &breakdown,
                clock: clock
            )
            cursor = closingRange.upperBound
        }

        appendProseMeasured(
            String(text[cursor...]),
            to: &output,
            breakdown: &breakdown,
            clock: clock
        )
        breakdown.total = clock.now - started
        return (output, breakdown)
    }

    private static func appendProseMeasured(
        _ text: String,
        to output: inout AttributedString,
        breakdown: inout AssistantResponseFormatBreakdown,
        clock: ContinuousClock
    ) {
        guard !text.isEmpty else { return }
        breakdown.proseSegmentCount += 1

        let parseStarted = clock.now
        let attributed = try? AttributedString(
            markdown: text,
            options: .init(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        )
        breakdown.markdownParse += clock.now - parseStarted

        let createStarted = clock.now
        var fragment = attributed ?? AttributedString(text)
        let expectedTrailingNewlines = text.reversed().prefix(while: {
            $0 == "\n"
        }).count
        let actualTrailingNewlines = String(fragment.characters)
            .reversed()
            .prefix(while: { $0 == "\n" })
            .count
        if expectedTrailingNewlines > actualTrailingNewlines {
            fragment.append(AttributedString(String(
                repeating: "\n",
                count: expectedTrailingNewlines - actualTrailingNewlines
            )))
        }
        breakdown.attributedStringCreation += clock.now - createStarted

        let assemblyStarted = clock.now
        output.append(fragment)
        breakdown.assembly += clock.now - assemblyStarted
    }

    private static func appendCodeMeasured(
        _ fencedContent: String,
        to output: inout AttributedString,
        breakdown: inout AssistantResponseFormatBreakdown,
        clock: ContinuousClock
    ) {
        breakdown.codeSegmentCount += 1
        let code: String
        if let firstNewline = fencedContent.firstIndex(of: "\n") {
            code = String(fencedContent[fencedContent.index(after: firstNewline)...])
        } else {
            code = fencedContent
        }

        let createStarted = clock.now
        var attributed = AttributedString(code)
        attributed.inlinePresentationIntent = .code
        breakdown.attributedStringCreation += clock.now - createStarted

        let assemblyStarted = clock.now
        output.append(attributed)
        breakdown.assembly += clock.now - assemblyStarted
    }
}
