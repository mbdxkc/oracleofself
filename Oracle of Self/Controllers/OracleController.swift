//
//  OracleController.swift
//  Oracle of Self
//
//  Drives the Oracle of Self quiz state machine.
//  Owns the active question set, the running true count, and the
//  welcome → asking → result transitions.
//
//  Lifecycle:
//    prompt   → start(question:) → asking(0)
//    asking(i)→ answer(true|false) → asking(i+1) or result(score)
//    result   → reset()         → prompt
//

import SwiftUI

@Observable
final class OracleController {

    // MARK: - State

    /// Which screen the view should render. Source of truth for navigation.
    var state: OracleState = .prompt

    /// Running count of true answers. Capped at the question count (10).
    var score: Int = 0

    /// The question the user typed on the prompt screen. Persists through
    /// the session so it can render as the title on every quiz step and
    /// the result screen, then ship into the journal entry if logged.
    private(set) var question: String = ""

    /// Questions for the current session. Empty before `start()` runs;
    /// regenerated on every `start()` so each session pulls fresh variants
    /// from `OracleData.questionSlots`.
    private(set) var questions: [OracleQuestion] = []

    // MARK: - Derived

    /// The active question while in `asking` state, otherwise nil.
    /// Returns nil if the state's index has somehow outrun the question
    /// array — defensive guard, should never trip in practice.
    var currentQuestion: OracleQuestion? {
        guard case .asking(let index) = state, index < questions.count else { return nil }
        return questions[index]
    }

    /// Progress label shown above the question, e.g. "3 / 10".
    /// Empty string outside the asking state.
    var progressText: String {
        guard case .asking(let index) = state else { return "" }
        return "\(index + 1) / \(questions.count)"
    }

    /// Final outcome message for the result screen.
    /// Empty string before the quiz finishes.
    var outcomeText: String {
        guard case .result(let finalScore) = state else { return "" }
        return OracleData.outcome(for: finalScore)
    }

    /// Markdown-friendly journal line written when the user opts to log
    /// the session. Empty until the result screen is reached.
    var journalEntry: String {
        guard case .result = state else { return "" }
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let q = trimmed.isEmpty ? "(no question)" : trimmed
        return "Oracle — \"\(q)\": \(outcomeText)"
    }

    // MARK: - Actions

    /// Begins a new quiz with the user's question: zeros the score, stores
    /// the question for later display + logging, generates a fresh question
    /// set, and advances to the first question. No-op on empty input so the
    /// caller can wire this directly to a Begin button.
    func start(question: String) {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        self.question = trimmed
        score = 0
        questions = OracleData.generateQuestions()
        state = .asking(currentQuestion: 0)
    }

    /// Records the user's true/false answer and advances. True increments
    /// the score; either answer moves to the next question or, if the last
    /// question was just answered, transitions to the result screen.
    /// No-op if called outside the asking state.
    func answer(_ value: Bool) {
        guard case .asking(let index) = state else { return }

        if value {
            score += 1
        }

        let nextIndex = index + 1
        if nextIndex < questions.count {
            state = .asking(currentQuestion: nextIndex)
        } else {
            state = .result(score: score)
        }
    }

    /// Returns to the prompt screen and clears the question set + typed
    /// question. Called after the user answers "Log it?" on the result
    /// screen, regardless of yes/no.
    func reset() {
        score = 0
        questions = []
        question = ""
        state = .prompt
    }

    // MARK: - Programmatic Consultation

    /// Runs a full oracle session in the background and returns the outcome
    /// string. Used when the user asks the oracle from within a diary thread.
    static func consult(question: String) -> String {
        let c = OracleController()
        c.start(question: question)
        while case .asking = c.state {
            c.answer(Bool.random())
        }
        return c.outcomeText
    }
}
