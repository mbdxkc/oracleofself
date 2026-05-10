//
//  DiaryController.swift
//  Oracle of Self
//
//  Unified truth diary store. Oracle readings and free-form notes are
//  parent entries. Comments saved on any entry become child entries linked
//  by parentId. Persists to UserDefaults with Codable.
//

import Foundation

// MARK: - Entry Kind

enum EntryKind: Codable {
    case oracle(score: Int, outcome: String)
    case note(body: String)
}

// MARK: - Diary Entry

struct DiaryEntry: Codable, Identifiable {
    let id: UUID
    let parentId: UUID?  // nil = parent, set = child comment
    var question: String
    var commentary: String?  // deprecated — migrated to child entries
    let kind: EntryKind
    let date: Date
}

// MARK: - Old Model (migration only)

private struct OldOracleReading: Codable, Identifiable {
    let id: UUID
    let question: String
    let outcome: String
    let score: Int
    let date: Date
}

// MARK: - Controller

@Observable
final class DiaryController {

    private let key = "diary_entries_v2"

    var entries: [DiaryEntry] = []

    var topLevelEntries: [DiaryEntry] {
        entries.filter { $0.parentId == nil }.sorted { $0.date > $1.date }
    }

    init() {
        load()
        migrateCommentary()
    }

    // MARK: - Queries

    func children(of parentId: UUID) -> [DiaryEntry] {
        entries.filter { $0.parentId == parentId }.sorted { $0.date > $1.date }
    }

    func commentCount(for parentId: UUID) -> Int {
        entries.filter { $0.parentId == parentId }.count
    }

    // MARK: - Mutations

    func addOracle(question: String, outcome: String, score: Int) {
        let entry = DiaryEntry(
            id: UUID(),
            parentId: nil,
            question: question,
            commentary: nil,
            kind: .oracle(score: score, outcome: outcome),
            date: Date()
        )
        entries.insert(entry, at: 0)
        save()
    }

    func addNote(question: String, body: String) {
        let entry = DiaryEntry(
            id: UUID(),
            parentId: nil,
            question: question,
            commentary: nil,
            kind: .note(body: body),
            date: Date()
        )
        entries.insert(entry, at: 0)
        save()
    }

    func addComment(parentId: UUID, body: String, title: String = "") {
        let entry = DiaryEntry(
            id: UUID(),
            parentId: parentId,
            question: title,
            commentary: nil,
            kind: .note(body: body),
            date: Date()
        )
        entries.insert(entry, at: 0)
        save()
    }

    func delete(id: UUID) {
        entries.removeAll { $0.id == id || $0.parentId == id }
        save()
    }

    func clear() {
        entries.removeAll()
        save()
    }

    var isEmpty: Bool { entries.filter { $0.parentId == nil }.isEmpty }

    // MARK: - Formatting

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    func formattedDate(_ date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([DiaryEntry].self, from: data)
        else {
            migrateOldReadings()
            return
        }
        entries = decoded
    }

    private func migrateOldReadings() {
        guard let data = UserDefaults.standard.data(forKey: "oracle_readings"),
              let old = try? JSONDecoder().decode([OldOracleReading].self, from: data)
        else { return }

        entries = old.map { reading in
            DiaryEntry(
                id: reading.id,
                parentId: nil,
                question: reading.question,
                commentary: nil,
                kind: .oracle(score: reading.score, outcome: reading.outcome),
                date: reading.date
            )
        }
        save()
        UserDefaults.standard.removeObject(forKey: "oracle_readings")
    }

    /// Legacy commentary field is replaced by child entries.
    /// Any parent with non-nil commentary gets a child note and clears the field.
    private func migrateCommentary() {
        var mutated = false
        for index in entries.indices {
            guard entries[index].parentId == nil,
                  let commentary = entries[index].commentary,
                  !commentary.isEmpty else { continue }

            let child = DiaryEntry(
                id: UUID(),
                parentId: entries[index].id,
                question: "Reflection",
                commentary: nil,
                kind: .note(body: commentary),
                date: entries[index].date.addingTimeInterval(1)
            )
            entries.insert(child, at: 0)
            entries[index].commentary = nil
            mutated = true
        }
        if mutated { save() }
    }
}
