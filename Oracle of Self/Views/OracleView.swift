//
//  OracleView.swift
//  Oracle of Self
//
//  Oracle of Self tab. The user types a question, answers 10 true/false
//  prompts, and sees a score-weighted verdict. Three screens — prompt,
//  question, result — selected by `OracleController.state`.
//
//  Layout: every screen uses `OracleContentLayout` so title, content,
//  and buttons land at fixed vertical anchors regardless of text length.
//  The user's typed question sits in the title slot on the question and
//  result screens so it stays anchored above every step. `MysticalFogView`
//  sits behind everything as ambient atmosphere.
//

import SwiftUI

// MARK: - Oracle View (Container)

/// Quiz root. Switches between the three screens based on controller state.
/// Black background with the fog overlay.
struct OracleView: View {
    let controller: OracleController
    let diary: DiaryController

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            MysticalFogView()
                .ignoresSafeArea()
                .zIndex(0)

            switch controller.state {
            case .prompt:
                PromptView(controller: controller)
                    .zIndex(1)
            case .asking:
                QuestionView(controller: controller)
                    .zIndex(1)
            case .result:
                ResultView(controller: controller, diary: diary)
                    .zIndex(1)
            }
        }
    }
}

// MARK: - Shared Layout

/// Fixed-anchor layout used by all three Oracle screens so the eye doesn't
/// jump between them. Title sits at 80pt down inside an 80pt band (taller
/// than before so the user's question can wrap), content is a 200pt centered
/// band, buttons sit at a fixed 50pt band with 40pt gap. Any of the three
/// slots can render `EmptyView()`.
private struct OracleContentLayout<Title: View, Content: View, Buttons: View>: View {
    @ViewBuilder let title: () -> Title
    @ViewBuilder let content: () -> Content
    @ViewBuilder let buttons: () -> Buttons

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 80)

            title()
                .frame(minHeight: 80, maxHeight: 80, alignment: .bottom)
                .frame(maxWidth: .infinity)

            Spacer().frame(height: 16)

            content()
                .frame(minHeight: 200, maxHeight: 200, alignment: .center)
                .frame(maxWidth: .infinity)

            Spacer().frame(height: 40)

            buttons()
                .frame(minHeight: 50, maxHeight: 50)
                .frame(maxWidth: .infinity)

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Question Title (shared)

/// Renders the user's question as the title slot on every quiz step and
/// on the result screen. Italic + quoted to read like an asked question;
/// two-line cap keeps the layout from drifting if the user types a
/// paragraph.
private struct OracleQuestionTitle: View {
    let question: String

    var body: some View {
        Text("\u{201C}\(question)\u{201D}")
            .font(.title3)
            .italic()
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineLimit(2)
    }
}

// MARK: - Prompt Screen

/// Pre-quiz landing. User types the question they want answered; pressing
/// return submits and transitions the controller into `asking(0)`.
struct PromptView: View {
    let controller: OracleController
    @State private var draft: String = ""
    @FocusState private var fieldFocused: Bool

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Text("Oracle of Self")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                VStack(spacing: 16) {
                    Text("Ask a question. Answer 10 prompts. There are no wrong answers. There are only answers.")
                        .font(.callout)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)

                    // Vertical TextField swallows .onSubmit (return inserts a
                    // newline instead of dismissing). Watch the bound text for
                    // a `\n` and treat it as submit so the keyboard's return key
                    // starts the quiz, while still allowing soft-wrapping for
                    // long questions.
                    TextField("", text: $draft, prompt: Text("What do you want to ask?").foregroundStyle(.gray), axis: .vertical)
                        .font(.body)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(1...3)
                        .focused($fieldFocused)
                        .submitLabel(.send)
                        .onChange(of: draft) { _, newValue in
                            guard newValue.contains("\n") else { return }
                            draft = newValue.replacingOccurrences(of: "\n", with: " ")
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            begin()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .accessibilityLabel("Your question for the oracle")
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func begin() {
        guard !trimmedDraft.isEmpty else { return }
        fieldFocused = false
        controller.start(question: trimmedDraft)
    }
}

// MARK: - Question Screen

/// Active quiz screen. The user's question sits in the title slot so they
/// stay grounded in what they asked. Cross-fades between true/false prompts
/// on every answer (transition keyed by `question.id`).
struct QuestionView: View {
    let controller: OracleController

    var body: some View {
        OracleContentLayout(
            title: {
                OracleQuestionTitle(question: controller.question)
            },
            content: {
                if let question = controller.currentQuestion {
                    VStack(spacing: 12) {
                        Text(controller.progressText)
                            .font(.caption)
                            .foregroundStyle(.gray)

                        Text(question.text)
                            .font(.title3)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.2), value: question.id)
                    }
                }
            },
            buttons: {
                HStack(spacing: 16) {
                    Button(action: { controller.answer(true) }) {
                        Text("True")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .accessibilityLabel("Answer true")

                    Button(action: { controller.answer(false) }) {
                        Text("False")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.systemGray5))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .accessibilityLabel("Answer false")
                }
            }
        )
    }
}

// MARK: - Result Screen

/// Post-quiz verdict. Shows the score-weighted outcome string under the
/// user's question, then asks "Save it?" with Yes/No. Either choice resets
/// the controller back to prompt; Yes additionally writes the reading into
/// local history via `HistoryController`.
struct ResultView: View {
    let controller: OracleController
    let diary: DiaryController

    var body: some View {
        OracleContentLayout(
            title: {
                OracleQuestionTitle(question: controller.question)
            },
            content: {
                VStack(spacing: 12) {
                    Text("The Oracle Speaks")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.gray)
                        .textCase(.uppercase)
                        .tracking(1.5)

                    Text(controller.outcomeText)
                        .font(.title3)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }
            },
            buttons: {
                VStack(spacing: 10) {
                    Text("Save it?")
                        .font(.subheadline)
                        .foregroundStyle(.gray)

                    HStack(spacing: 16) {
                        Button(action: saveAndReset) {
                            Text("Yes")
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .accessibilityLabel("Save this oracle reading to diary")

                        Button(action: { controller.reset() }) {
                            Text("No")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .accessibilityLabel("Skip saving and ask again")
                    }
                }
            }
        )
    }

    private func saveAndReset() {
        if case .result(let finalScore) = controller.state {
            diary.addOracle(
                question: controller.question,
                outcome: controller.outcomeText,
                score: finalScore
            )
        }
        controller.reset()
    }
}

// MARK: - Preview

#Preview {
    OracleView(controller: OracleController(), diary: DiaryController())
}
