import Foundation
import SwiftUI
#if CLOUD_STUDY
import AuthenticationServices
#endif

struct Card: Codable, Identifiable, Hashable {
    let id, theory, term, question, answer: String
}

struct Deck: Identifiable {
    let name, symbol: String
    let tint: Color
    var id: String { name }
    static let all = [
        Deck(name: "Person-Centered", symbol: "person.crop.circle", tint: Color(red: 0.36, green: 0.86, blue: 0.66)),
        Deck(name: "CBT", symbol: "brain.head.profile", tint: Color(red: 0.48, green: 0.75, blue: 1)),
        Deck(name: "Solution-Focused", symbol: "sun.max", tint: Color(red: 1, green: 0.78, blue: 0.37)),
        Deck(name: "Reality Therapy", symbol: "scope", tint: Color(red: 1, green: 0.59, blue: 0.53)),
        Deck(name: "Psychodynamic", symbol: "tree", tint: Color(red: 0.77, green: 0.66, blue: 1))
    ]
}

struct Mark: Codable {
    var favorite = false
    var reviewed = false
    var mastered = false
    var changed = Date()
}

struct QuizRecord: Codable, Identifiable {
    var id = UUID()
    let correct, total: Int
    var date = Date()
}

struct StudyHistory: Codable {
    var marks: [String: Mark] = [:]
    var quizzes: [QuizRecord] = []
    mutating func merge(_ other: Self) {
        marks.merge(other.marks) { $0.changed >= $1.changed ? $0 : $1 }
        let ids = Set(quizzes.map(\.id))
        quizzes.append(contentsOf: other.quizzes.filter { !ids.contains($0.id) })
        quizzes.sort { $0.date < $1.date }
    }
}

final class StudyStore: ObservableObject {
    let cards: [Card]
    @Published private(set) var history: StudyHistory
    @Published var loadError: String?
    private static let key = "study-history-v1"
    #if CLOUD_STUDY
    private var observer: NSObjectProtocol?
    #endif

    init() {
        var issue: String?
        do {
            guard let url = Bundle.main.url(forResource: "cards", withExtension: "json") else {
                throw CocoaError(.fileNoSuchFile)
            }
            cards = try JSONDecoder().decode([Card].self, from: Data(contentsOf: url))
        } catch {
            cards = []
            issue = "The card library could not be loaded."
        }
        loadError = issue
        let saved = UserDefaults.standard.data(forKey: Self.key)
        history = saved.flatMap { try? JSONDecoder().decode(StudyHistory.self, from: $0) } ?? StudyHistory()
        #if CLOUD_STUDY
        let cloud = NSUbiquitousKeyValueStore.default
        observer = NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: cloud, queue: .main) { [weak self] note in
            if let reason = note.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int,
               reason == NSUbiquitousKeyValueStoreAccountChange {
                self?.history = StudyHistory()
                UserDefaults.standard.removeObject(forKey: StudyStore.key)
            }
            self?.receiveCloud()
        }
        cloud.synchronize()
        receiveCloud()
        #endif
    }
    func mark(_ card: Card, _ change: (inout Mark) -> Void) {
        var value = history.marks[card.id] ?? Mark()
        change(&value)
        value.changed = Date()
        history.marks[card.id] = value
        save()
    }
    func record(correct: Int, total: Int) {
        history.quizzes.append(QuizRecord(correct: correct, total: total))
        save()
    }
    private func save() {
        guard let data = try? JSONEncoder().encode(history) else { return }
        UserDefaults.standard.set(data, forKey: Self.key)
        #if CLOUD_STUDY
        NSUbiquitousKeyValueStore.default.set(data, forKey: Self.key)
        #endif
    }
    #if CLOUD_STUDY
    private func receiveCloud() {
        guard let data = NSUbiquitousKeyValueStore.default.data(forKey: Self.key),
              let other = try? JSONDecoder().decode(StudyHistory.self, from: data) else { return }
        history.merge(other)
        if let local = try? JSONEncoder().encode(history) { UserDefaults.standard.set(local, forKey: Self.key) }
    }
    deinit { if let observer { NotificationCenter.default.removeObserver(observer) } }
    #endif
}

@main
struct CounselingTheoryProApp: App {
    @StateObject private var store = StudyStore()
    var body: some Scene {
        WindowGroup { StudyTabs().environmentObject(store).preferredColorScheme(.dark) }
    }
}
