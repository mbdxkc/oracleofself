//
//  HistoryView.swift
//  Oracle of Self
//
//  Insights tab. Lists saved oracle readings with question, outcome,
//  and date. Swipe right to try again, swipe left to delete.
//

import SwiftUI

struct HistoryView: View {
    let history: HistoryController
    let onTryAgain: (String) -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if history.isEmpty {
                emptyState
            } else {
                readingList
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundStyle(.gray)

            Text("No readings yet")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Saved oracle sessions appear here.")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }

    private var readingList: some View {
        List {
            ForEach(history.readings) { reading in
                ReadingCard(reading: reading, history: history, onTryAgain: onTryAgain)
                    .listRowBackground(Color.black)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.plain)
        .background(Color.black)
    }
}

// MARK: - Reading Card

private struct ReadingCard: View {
    let reading: OracleReading
    let history: HistoryController
    let onTryAgain: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text("\u{201C}\(reading.question)\u{201D}")
                    .font(.body)
                    .italic()
                    .foregroundStyle(.white)
                    .lineLimit(3)

                Spacer()

                Text(String(reading.score))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                    .frame(width: 28, height: 28)
                    .background(scoreColor)
                    .clipShape(Circle())
            }

            Text(reading.outcome)
                .font(.callout)
                .foregroundStyle(.gray)
                .lineLimit(4)

            HStack {
                Text(history.formattedDate(reading.date))
                    .font(.caption2)
                    .foregroundStyle(.gray.opacity(0.7))

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
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                onTryAgain(reading.question)
            } label: {
                Label("Try Again", systemImage: "arrow.counterclockwise")
            }
            .tint(Color.accent)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                history.delete(id: reading.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var scoreColor: Color {
        switch reading.score {
        case 0...3: return Color.red.opacity(0.8)
        case 4...6: return Color.yellow.opacity(0.8)
        default: return Color.accent
        }
    }
}

// MARK: - Preview

#Preview {
    let history = HistoryController()
    history.add(question: "Should I move to Portland?", outcome: "The stars are leaning yes.", score: 7)
    history.add(question: "Is this the right time to quit?", outcome: "The cosmos is not sure yet.", score: 5)

    return HistoryView(history: history, onTryAgain: { _ in })
}
