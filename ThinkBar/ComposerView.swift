import AppKit
import SwiftUI

struct ComposerView: View {
    @Binding var input: String
    @Binding var attachments: [Attachment]
    @Binding var imageAttachments: [ImageAttachment]

    let attachmentError: String?
    let isSending: Bool
    let focusRequest: Int
    let onSend: () -> Void
    let onPasteImage: () -> Bool

    @State private var inputHeight = ComposerMetrics.minHeight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(attachments) { attachment in
                HStack {
                    Text("📎 \(attachment.fileName)")
                    Spacer()
                    Button {
                        attachments.removeAll { $0.id == attachment.id }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .disabled(isSending)
                    .accessibilityLabel("Remove \(attachment.fileName)")
                }
            }

            ForEach(imageAttachments) { imageAttachment in
                HStack {
                    Text("🖼 Screenshot")
                    Spacer()
                    Button {
                        imageAttachments.removeAll { $0.id == imageAttachment.id }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .disabled(isSending)
                    .accessibilityLabel("Remove screenshot")
                }
            }

            if let attachmentError {
                Text(attachmentError)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            IMESafeTextEditor(
                text: $input,
                isEnabled: !isSending,
                focusRequest: focusRequest,
                preferredHeight: $inputHeight,
                onSend: onSend,
                onPasteImage: onPasteImage
            )
            .frame(height: inputHeight)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.08))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2))
            }

            HStack {
                Spacer()
                Button("Send", action: onSend)
                    .disabled(isSending)
            }
        }
        .onChange(of: input) { _, newValue in
            if newValue.isEmpty {
                inputHeight = ComposerMetrics.minHeight
            }
        }
    }
}

private enum ComposerMetrics {
    static let minHeight: CGFloat = 44
    static let maxLines = 10
    static let font = NSFont.systemFont(ofSize: 20)
    static let textContainerInset = NSSize(width: 4, height: 8)

    static var maxHeight: CGFloat {
        let lineHeight = NSLayoutManager().defaultLineHeight(for: font)
        return ceil(lineHeight * CGFloat(maxLines) + textContainerInset.height * 2)
    }
}

private struct IMESafeTextEditor: NSViewRepresentable {
    @Binding var text: String

    let isEnabled: Bool
    let focusRequest: Int
    @Binding var preferredHeight: CGFloat
    let onSend: () -> Void
    let onPasteImage: () -> Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, preferredHeight: $preferredHeight)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = SendingTextView()
        textView.delegate = context.coordinator
        textView.font = ComposerMetrics.font
        textView.isRichText = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: 0,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainerInset = ComposerMetrics.textContainerInset
        textView.minSize = NSSize(width: 0, height: ComposerMetrics.minHeight)
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        textView.drawsBackground = false
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? SendingTextView else { return }

        context.coordinator.text = $text
        context.coordinator.preferredHeight = $preferredHeight

        if textView.string != text {
            textView.string = text
        }
        textView.isEditable = isEnabled
        textView.onSend = onSend
        textView.onPasteImage = onPasteImage
        context.coordinator.updatePreferredHeight(for: textView)

        if context.coordinator.lastFocusRequest != focusRequest {
            context.coordinator.lastFocusRequest = focusRequest
            scrollView.window?.makeFirstResponder(textView)
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        var preferredHeight: Binding<CGFloat>
        var lastFocusRequest: Int?

        init(text: Binding<String>, preferredHeight: Binding<CGFloat>) {
            self.text = text
            self.preferredHeight = preferredHeight
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            // Keep marked text intact for Japanese IME composition.
            text.wrappedValue = textView.string
            updatePreferredHeight(for: textView)
        }

        func updatePreferredHeight(for textView: NSTextView) {
            guard
                let layoutManager = textView.layoutManager,
                let textContainer = textView.textContainer
            else { return }

            layoutManager.ensureLayout(for: textContainer)
            let usedHeight = layoutManager.usedRect(for: textContainer).height
            let contentHeight = ceil(
                usedHeight + textView.textContainerInset.height * 2
            )
            let clampedHeight = min(
                max(contentHeight, ComposerMetrics.minHeight),
                ComposerMetrics.maxHeight
            )

            if abs(preferredHeight.wrappedValue - clampedHeight) > 0.5 {
                preferredHeight.wrappedValue = clampedHeight
            }
        }
    }
}

private final class SendingTextView: NSTextView {
    private static let returnKeyCode: UInt16 = 36
    private static let keypadEnterKeyCode: UInt16 = 76

    var onSend: (() -> Void)?
    var onPasteImage: (() -> Bool)?

    override func keyDown(with event: NSEvent) {
        let isEnter = event.keyCode == Self.returnKeyCode
            || event.keyCode == Self.keypadEnterKeyCode
        guard isEnter, !hasMarkedText() else {
            super.keyDown(with: event)
            return
        }

        let modifiers = event.modifierFlags.intersection([
            .command, .control, .option, .shift,
        ])
        if (modifiers.isEmpty || modifiers == .command), let onSend {
            onSend()
            return
        }

        super.keyDown(with: event)
    }

    override func paste(_ sender: Any?) {
        if onPasteImage?() == true {
            return
        }
        super.paste(sender)
    }
}
