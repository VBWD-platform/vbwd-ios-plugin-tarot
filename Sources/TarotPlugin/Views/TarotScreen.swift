import SwiftUI
import VBWDCore

/// Tarot reading screen. Minimal v0.1 port — daily-limits banner +
/// "Start Reading" button + drawn-cards list with interpretations.
/// Follow-up conversation flow is a follow-up sprint.
struct TarotScreen: View {
    @StateObject private var viewModel: TarotViewModel
    @Environment(\.appTheme) private var theme

    init(service: TarotServiceProtocol) {
        _viewModel = StateObject(wrappedValue: TarotViewModel(service: service))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                limitsCard
                if let session = viewModel.currentSession {
                    sessionCard(session: session)
                } else {
                    startCard
                }
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(theme.destructive)
                        .accessibilityIdentifier("tarot_error_message")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("Tarot")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { await viewModel.loadLimits() }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Tarot Card Reading")
                .font(.title2.weight(.semibold))
            Text("Get AI-powered tarot interpretations and insights")
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
        }
    }

    @ViewBuilder
    private var limitsCard: some View {
        if viewModel.isLoadingLimits {
            HStack { ProgressView(); Text("Loading limits…") }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else if let limits = viewModel.limits {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Daily Sessions").font(.caption).foregroundStyle(theme.textSecondary)
                    Spacer()
                    Text(limits.planName).font(.caption.weight(.semibold))
                }
                HStack(spacing: 12) {
                    cell("Total", "\(limits.dailyTotal)")
                    cell("Used", "\(limits.dailyUsed)")
                    cell("Remaining", "\(limits.dailyRemaining)")
                }
            }
            .padding()
            .background(theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityIdentifier("tarot_limits_card")
        } else {
            EmptyView()
        }
    }

    private func cell(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.title3.weight(.semibold))
            Text(label).font(.caption2).foregroundStyle(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var startCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Start a New Reading").font(.headline)
            Text("Begin a new tarot reading session. Each session includes up to 3 cards and AI-powered interpretations.")
                .font(.footnote)
                .foregroundStyle(theme.textSecondary)
            Button {
                Task { await viewModel.startReading() }
            } label: {
                HStack {
                    if viewModel.isCreatingSession {
                        ProgressView().tint(.white)
                    }
                    Text(viewModel.isCreatingSession ? "Creating session…" : "Start Reading")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(canStart ? theme.accent : theme.textSecondary.opacity(0.3))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(!canStart || viewModel.isCreatingSession)
            .accessibilityIdentifier("tarot_start_reading_button")
            if viewModel.limits?.canCreate == false {
                Text("You've reached your daily session limit. Try again tomorrow.")
                    .font(.footnote)
                    .foregroundStyle(theme.destructive)
            }
        }
        .padding()
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var canStart: Bool {
        viewModel.limits?.canCreate ?? false
    }

    private func sessionCard(session: TaroSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Active Session", systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button("End", role: .destructive) {
                    viewModel.endSession()
                }
                .accessibilityIdentifier("tarot_end_session_button")
            }

            if session.cards.isEmpty {
                Text("No cards drawn yet.")
                    .font(.footnote)
                    .foregroundStyle(theme.textSecondary)
            } else {
                ForEach(session.cards) { card in
                    cardRow(card)
                }
            }

            // Chat transcript — user prompts + Oracle replies (markdown-rendered).
            if !viewModel.messages.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.messages) { msg in
                        chatBubble(msg)
                    }
                }
                .accessibilityIdentifier("tarot_chat_transcript")
            }

            if viewModel.isSubmittingSituation {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Oracle is thinking…")
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
            }

            // Situation prompt — input + submit at the bottom of the card.
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Situation").font(.caption.weight(.semibold))
                TextField("Describe what's on your mind…", text: $viewModel.situationText, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(10)
                    .background(theme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityIdentifier("tarot_situation_field")
                Button {
                    Task { await viewModel.submitSituation() }
                } label: {
                    HStack {
                        if viewModel.isSubmittingSituation { ProgressView().tint(.white) }
                        Text("Submit").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(theme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(viewModel.situationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                          || viewModel.isSubmittingSituation)
                .accessibilityIdentifier("tarot_submit_situation_button")
            }
        }
        .padding()
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityIdentifier("tarot_session_card")
    }

    @ViewBuilder
    private func cardRow(_ card: TaroCard) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(positionLabel(card.position))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.accent)
                Spacer()
                Text(card.orientation == .upright ? "Upright" : "Reversed")
                    .font(.caption2)
                    .foregroundStyle(theme.textSecondary)
            }
            Text(card.arcana?.name ?? card.arcanaId)
                .font(.subheadline.weight(.semibold))
            if let interp = card.aiInterpretation ?? card.interpretation, !interp.isEmpty {
                Text(interp).font(.footnote)
            }
        }
        .padding(.vertical, 6)
    }

    private func positionLabel(_ position: CardPosition) -> String {
        switch position {
        case .past: return "Past"
        case .present: return "Present"
        case .future: return "Future"
        case .additional: return "Additional"
        }
    }

    // MARK: - Chat bubble

    @ViewBuilder
    private func chatBubble(_ msg: TarotChatMessage) -> some View {
        let isUser = msg.role == .user
        HStack {
            if isUser { Spacer(minLength: 24) }
            VStack(alignment: .leading, spacing: 6) {
                if !isUser {
                    Label("Oracle", systemImage: "sparkles")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(theme.accent)
                }
                if isUser {
                    Text(msg.content)
                        .font(.footnote)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                } else {
                    MarkdownBlocksView(raw: msg.content, accent: theme.accent)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isUser ? theme.accent.opacity(0.15) : theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .accessibilityIdentifier(isUser ? "tarot_chat_user_bubble" : "tarot_chat_oracle_bubble")
            if !isUser { Spacer(minLength: 24) }
        }
    }
}

// MARK: - Markdown block renderer

/// Block-level markdown renderer. `Text(AttributedString)` only handles
/// inline syntax, so headings, paragraphs and bullet lists need to be
/// split into separate `Text` views so SwiftUI can lay them out as
/// distinct blocks with their own fonts.
private struct MarkdownBlocksView: View {
    let raw: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(Self.parse(raw).enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
    }

    @ViewBuilder
    private func blockView(_ block: Block) -> some View {
        switch block {
        case .heading(let level, let text):
            Text(inline(text))
                .font(headingFont(level: level))
                .foregroundStyle(level <= 2 ? accent : Color.primary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        case .paragraph(let text):
            Text(inline(text))
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
        case .bullet(let text):
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("•").font(.footnote).foregroundStyle(accent)
                Text(inline(text))
                    .font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func headingFont(level: Int) -> Font {
        switch level {
        case 1: return .headline
        case 2: return .subheadline.weight(.semibold)
        default: return .footnote.weight(.semibold)
        }
    }

    /// Inline markdown only (bold/italic). Block syntax is already
    /// stripped by `parse(_:)`.
    private func inline(_ s: String) -> AttributedString {
        var opts = AttributedString.MarkdownParsingOptions()
        opts.interpretedSyntax = .inlineOnlyPreservingWhitespace
        if let a = try? AttributedString(markdown: s, options: opts) { return a }
        return AttributedString(s)
    }

    fileprivate enum Block {
        case heading(level: Int, text: String)
        case paragraph(String)
        case bullet(String)
    }

    /// Cheap block parser — splits on blank lines, recognises ATX
    /// headings (`#`, `##`, `###`) and dash/star bullets. Anything else
    /// is a paragraph. Adjacent non-blank lines are joined with a space
    /// so soft wraps render naturally.
    fileprivate static func parse(_ raw: String) -> [Block] {
        var result: [Block] = []
        var paragraph: [String] = []

        func flushParagraph() {
            let joined = paragraph.joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !joined.isEmpty { result.append(.paragraph(joined)) }
            paragraph.removeAll()
        }

        for rawLine in raw.components(separatedBy: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                flushParagraph()
                continue
            }
            if line.hasPrefix("### ") {
                flushParagraph()
                result.append(.heading(level: 3, text: String(line.dropFirst(4))))
            } else if line.hasPrefix("## ") {
                flushParagraph()
                result.append(.heading(level: 2, text: String(line.dropFirst(3))))
            } else if line.hasPrefix("# ") {
                flushParagraph()
                result.append(.heading(level: 1, text: String(line.dropFirst(2))))
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                flushParagraph()
                result.append(.bullet(String(line.dropFirst(2))))
            } else {
                paragraph.append(line)
            }
        }
        flushParagraph()
        return result
    }
}
