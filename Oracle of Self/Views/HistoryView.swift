//
//  HistoryView.swift
//  Oracle of Self
//
//  Insights tab. Threaded truth diary: oracle readings and free-form notes
//  are parent entries. Comments on any entry become child entries linked by
//  parentId. Tap a parent to view the thread and add comments. Swipe right to
//  comment, swipe left to delete.
//
//  Close-ended questions get an "Ask Oracle" option. If the parent title is a
//  yes/no question, the thread view offers a direct consultation. If a comment
//  draft is a yes/no question or contains #oracle, a sparkle send button
//  appears. The oracle answer is posted as the next comment in the thread.
//

import SwiftUI

// MARK: - Question Detection

/// Checks whether a string looks like a closed-ended yes/no question.
/// Heuristic: ends with ?, under 200 chars, and starts with a yes/no word.
private func isClosedEndedQuestion(_ text: String) -> Bool {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.hasSuffix("?"), trimmed.count < 200 else { return false }
    let lower = trimmed.lowercased()
    let starters = [
        "is ", "are ", "will ", "should ", "can ", "do ", "does ", "did ",
        "am ", "was ", "were ", "would ", "could ", "has ", "have ",
        "isn't ", "aren't ", "won't ", "shouldn't ", "can't ", "don't ",
        "doesn't ", "didn't ", "wasn't ", "weren't ", "wouldn't ",
        "couldn't ", "hasn't ", "haven't "
    ]
    return starters.contains { lower.hasPrefix($0) }
}

// MARK: - Insights View

struct InsightsView: View {
    let diary: DiaryController
    let onTryAgain: (String) -> Void

    @State private var showAddSheet = false
    @State private var selectedEntry: DiaryEntry? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if diary.isEmpty {
                    emptyState
                } else {
                    entryList
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddEntrySheet(diary: diary)
        }
        .sheet(item: $selectedEntry) { entry in
            EntryDetailSheet(entry: entry, diary: diary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundStyle(.gray)

            Text("No entries yet")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Saved oracle sessions and diary notes appear here.")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add diary entry")
            }
        }
    }

    private var entryList: some View {
        List {
            ForEach(diary.topLevelEntries) { entry in
                EntryRow(entry: entry, diary: diary, onTryAgain: onTryAgain, onComment: { selectedEntry = entry })
                    .listRowBackground(Color.black)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedEntry = entry
                    }
            }
        }
        .listStyle(.plain)
        .background(Color.black)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add diary entry")
            }
        }
    }
}

// MARK: - Entry Row

private struct EntryRow: View {
    let entry: DiaryEntry
    let diary: DiaryController
    let onTryAgain: (String) -> Void
    let onComment: () -> Void

    private var commentCount: Int {
        diary.commentCount(for: entry.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text("\u{201C}\(entry.question)\u{201D}")
                    .font(.body)
                    .italic()
                    .foregroundStyle(.white)
                    .lineLimit(3)

                Spacer()

                kindBadge
            }

            bodyText

            HStack(spacing: 6) {
                Text(diary.formattedDate(entry.date))
                    .font(.caption2)
                    .foregroundStyle(.gray.opacity(0.7))

                if commentCount > 0 {
                    ZStack {
                        Circle()
                            .fill(Color.accent)
                            .frame(width: 18, height: 18)
                        Text(String(commentCount))
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.black)
                    }
                }

                Spacer()
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                diary.delete(id: entry.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                onComment()
            } label: {
                Label("Comment", systemImage: "bubble.left")
            }
            .tint(Color.accent)

            if case .oracle = entry.kind {
                Button {
                    onTryAgain(entry.question)
                } label: {
                    Label("Try Again", systemImage: "arrow.counterclockwise")
                }
                .tint(Color.blue)
            }
        }
    }

    @ViewBuilder
    private var kindBadge: some View {
        switch entry.kind {
        case .oracle(let score, _):
            Text(String(score))
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.black)
                .frame(width: 28, height: 28)
                .background(scoreColor(score))
                .clipShape(Circle())
        case .note:
            Image(systemName: "pencil")
                .font(.caption)
                .foregroundStyle(.black)
                .frame(width: 28, height: 28)
                .background(Color.gray.opacity(0.8))
                .clipShape(Circle())
        }
    }

    @ViewBuilder
    private var bodyText: some View {
        switch entry.kind {
        case .oracle(_, let outcome):
            Text(outcome)
                .font(.callout)
                .foregroundStyle(.gray)
                .lineLimit(4)
        case .note(let body):
            Text(body)
                .font(.callout)
                .foregroundStyle(.gray)
                .lineLimit(4)
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 0...3: return Color.red.opacity(0.8)
        case 4...6: return Color.yellow.opacity(0.8)
        default: return Color.accent
        }
    }
}

// MARK: - Add Entry Sheet

private struct AddEntrySheet: View {
    let diary: DiaryController
    @Environment(\.dismiss) private var dismiss

    @State private var question: String = ""
    @State private var bodyText: String = ""

    private var trimmedQuestion: String {
        question.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 16) {
                    TextField("Title or question", text: $question)
                        .font(.body)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )

                    TextEditor(text: $bodyText)
                        .font(.body)
                        .foregroundStyle(.white)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(height: 120)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
            .navigationTitle("New Entry")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            save()
                        }
                        .disabled(trimmedQuestion.isEmpty || bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
        }
    }

    private func save() {
        let trimmedBody = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuestion.isEmpty, !trimmedBody.isEmpty else { return }
        diary.addNote(question: trimmedQuestion, body: trimmedBody)
        dismiss()
    }
}

// MARK: - Entry Detail Sheet (Thread View)

private struct EntryDetailSheet: View {
    let entry: DiaryEntry
    let diary: DiaryController
    @Environment(\.dismiss) private var dismiss

    @State private var draft: String = ""
    @FocusState private var fieldFocused: Bool

    private var children: [DiaryEntry] {
        diary.children(of: entry.id)
    }

    private var shouldShowOracleOption: Bool {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        return !text.isEmpty && (isClosedEndedQuestion(text) || text.lowercased().contains("#oracle"))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Parent
                        VStack(spacing: 8) {
                            Text("\u{201C}\(entry.question)\u{201D}")
                                .font(.title3)
                                .italic()
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)

                            if case .oracle(_, let outcome) = entry.kind {
                                Text(outcome)
                                    .font(.callout)
                                    .foregroundStyle(.gray)
                                    .multilineTextAlignment(.center)
                            } else if case .note(let body) = entry.kind {
                                Text(body)
                                    .font(.callout)
                                    .foregroundStyle(.gray)
                                    .multilineTextAlignment(.center)
                            }

                            if isClosedEndedQuestion(entry.question) {
                                Button {
                                    consultOracle()
                                } label: {
                                    Label("Ask Oracle", systemImage: "sparkles")
                                        .font(.caption)
                                        .foregroundStyle(Color.accent)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )

                        // Children
                        if !children.isEmpty {
                            ForEach(children) { child in
                                VStack(alignment: .leading, spacing: 4) {
                                    if !child.question.isEmpty {
                                        Text(child.question)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.gray)
                                    }

                                    if case .note(let body) = child.kind {
                                        Text(body)
                                            .font(.body)
                                            .foregroundStyle(.white)
                                            .multilineTextAlignment(.leading)
                                    }

                                    Text(diary.formattedDate(child.date))
                                        .font(.caption2)
                                        .foregroundStyle(.gray.opacity(0.7))
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        // Add comment
                        HStack(spacing: 12) {
                            TextField("Add a thought...", text: $draft)
                                .font(.body)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .focused($fieldFocused)

                            if shouldShowOracleOption {
                                Button {
                                    postComment(askOracle: true)
                                } label: {
                                    Image(systemName: "sparkles")
                                        .font(.title3)
                                        .foregroundStyle(Color.accent)
                                }
                                .accessibilityLabel("Ask the oracle about this comment")
                            }

                            Button {
                                postComment(askOracle: false)
                            } label: {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.accent)
                            }
                            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
            }
            .navigationTitle("Thread")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func consultOracle() {
        let outcome = OracleController.consult(question: entry.question)
        diary.addComment(parentId: entry.id, body: outcome, title: "Oracle")
    }

    private func postComment(askOracle: Bool) {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let cleaned = text
            .replacingOccurrences(of: "#oracle", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let bodyToPost = cleaned.isEmpty ? text : cleaned
        diary.addComment(parentId: entry.id, body: bodyToPost)

        if askOracle {
            let question = cleaned.isEmpty ? text : cleaned
            let outcome = OracleController.consult(question: question)
            diary.addComment(parentId: entry.id, body: outcome, title: "Oracle")
        }

        draft = ""
    }
}

// MARK: - Preview

#Preview {
    let diary = DiaryController()
    diary.addOracle(question: "Should I move to Portland?", outcome: "The stars are leaning yes.", score: 7)
    diary.addNote(question: "Morning thought", body: "Clarity comes from action, not thought.")

    return InsightsView(diary: diary, onTryAgain: { _ in })
}
