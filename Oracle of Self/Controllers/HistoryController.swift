//
//  HistoryController.swift
//  Oracle of Self
//
//  Lightweight local store for saved oracle readings.
//  Persists to UserDefaults so the standalone app keeps a history
//  without depending on dezBot's dezLog.md.
//

import Foundation

struct OracleReading: Codable, Identifiable {
    let id: UUID
    let question: String
    let outcome: String
    let score: Int
    let date: Date
}

@Observable
final class HistoryController {

    private let key = "oracle_readings"

    var readings: [OracleReading] = []

    init() {
        load()
    }

    func add(question: String, outcome: String, score: Int) {
        let reading = OracleReading(
            id: UUID(),
            question: question,
            outcome: outcome,
            score: score,
            date: Date()
        )
        readings.insert(reading, at: 0)
        save()
    }

    func delete(id: UUID) {
        readings.removeAll { $0.id == id }
        save()
    }

    func clear() {
        readings.removeAll()
        save()
    }

    var isEmpty: Bool { readings.isEmpty }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    func formattedDate(_ date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(readings) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([OracleReading].self, from: data)
        else { return }
        readings = decoded
    }
}
