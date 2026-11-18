import SwiftUI
import AuthenticationServices

private let midnight = Color(red: 0.035, green: 0.085, blue: 0.14)
private let ocean = Color(red: 0.065, green: 0.18, blue: 0.22)
private let mint = Color(red: 0.51, green: 0.92, blue: 0.79)

private struct Page<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ZStack {
            LinearGradient(colors: [ocean, midnight, midnight], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            ScrollView { VStack(alignment: .leading, spacing: 19) { content }.padding(20).frame(maxWidth: 650) }
        }.toolbarBackground(midnight, for: .navigationBar)
    }
}
private extension View {
    func panel(_ color: Color = .white) -> some View {
        padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(color.opacity(0.20)))
    }
}
private func editorial(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .serif) }

struct StudyTabs: View {
    var body: some View {
        TabView {
            NavigationStack { Home() }.tabItem { Label("Home", systemImage: "house") }
            NavigationStack { Library() }.tabItem { Label("Cards", systemImage: "rectangle.stack") }
            NavigationStack { QuizStart() }.tabItem { Label("Quiz", systemImage: "checkmark.circle") }
            NavigationStack { ProgressPage() }.tabItem { Label("Progress", systemImage: "chart.bar") }
            NavigationStack { ReferencePage() }.tabItem { Label("Guide", systemImage: "book") }
        }.tint(mint)
    }
}

private struct Home: View {
    @EnvironmentObject var store: StudyStore
    var body: some View {
        Page {
            HStack { Image("Emblem").resizable().frame(width: 46, height: 46).clipShape(RoundedRectangle(cornerRadius: 11))
                Text("Counseling Theory Pro").font(.headline)
                Spacer()
                NavigationLink { Library() } label: { Image(systemName: "magnifyingglass").padding(10) }.accessibilityLabel("Search cards")
            }
            Text("Counseling theories").font(editorial(38))
            NavigationLink { Plan() } label: {
                VStack(alignment: .leading, spacing: 12) {
                    Label("DAILY STUDY PLAN", systemImage: "calendar").font(.caption.bold()).tracking(1.4)
                    Text(Plan.todayTitle).font(editorial(27))
                    Label("Open study plan", systemImage: "arrow.right.circle").font(.subheadline)
                }.panel(mint)
            }
            Text("Theory decks").font(editorial(24))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 12)], spacing: 12) {
                ForEach(Deck.all) { deck in
                    let cards = store.cards.filter { $0.theory == deck.name }
                    NavigationLink { Reader(cards: cards, name: deck.name) } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            Image(systemName: deck.symbol).font(.title2).foregroundStyle(deck.tint)
                            Text(deck.name).font(.headline).foregroundStyle(.white)
                            Text("\(cards.count) cards").font(.caption).foregroundStyle(deck.tint)
                        }.frame(maxWidth: .infinity, minHeight: 102, alignment: .leading).panel(deck.tint)
                    }
                }
            }
            if let error = store.loadError { Text(error).foregroundStyle(.orange) }
        }.buttonStyle(.plain)
    }
}

private struct Reader: View {
    @EnvironmentObject var store: StudyStore
    @Environment(\.accessibilityReduceMotion) var reducedMotion
    let cards: [Card]
    let name: String
    @State private var index: Int
    @State private var back = false
    init(cards: [Card], name: String, start: Int = 0) {
        self.cards = cards; self.name = name; _index = State(initialValue: start)
    }
    var body: some View {
        Page {
            if cards.indices.contains(index) {
                let card = cards[index]
                let mark = store.history.marks[card.id] ?? Mark()
                HStack {
                    Text("Card \(index + 1) of \(cards.count)").font(.subheadline.monospacedDigit())
                    Spacer()
                    Button { store.mark(card) { $0.favorite.toggle() } } label: {
                        Image(systemName: mark.favorite ? "bookmark.fill" : "bookmark").padding(10)
                    }.accessibilityLabel(mark.favorite ? "Remove favorite" : "Save favorite")
                }
                ProgressView(value: Double(index + 1), total: Double(cards.count))
                Button {
                    withAnimation(reducedMotion ? nil : .easeInOut(duration: 0.27)) { back.toggle() }
                    if back { store.mark(card) { $0.reviewed = true } }
                } label: {
                    VStack(alignment: .leading, spacing: 22) {
                        Text(card.theory.uppercased()).font(.caption.bold()).tracking(1.5)
                        Spacer(minLength: 20)
                        Text(back ? card.term : card.question).font(editorial(29))
                        if back { Text(card.answer).font(.body) }
                        Spacer(minLength: 20)
                        Label(back ? "Tap for question" : "Tap to reveal", systemImage: "arrow.triangle.2.circlepath").font(.footnote)
                    }.frame(maxWidth: .infinity, minHeight: 290, alignment: .leading)
                        .padding(24).foregroundStyle(midnight)
                        .background(back ? Color(red: 0.81, green: 0.94, blue: 0.88) : Color(red: 0.96, green: 0.94, blue: 0.88), in: RoundedRectangle(cornerRadius: 24))
                        .rotation3DEffect(.degrees(back && !reducedMotion ? 360 : 0), axis: (x: 0, y: 1, z: 0))
                }.buttonStyle(.plain)
                Button(mark.mastered ? "Marked as learned ✓" : "Mark as learned") { store.mark(card) { $0.mastered.toggle(); $0.reviewed = true } }.buttonStyle(.bordered)
                HStack {
                    Button("Previous") { index -= 1; back = false }.disabled(index == 0)
                    Spacer()
                    Button("Next") { index += 1; back = false }.disabled(index + 1 >= cards.count)
                }.buttonStyle(.bordered)
            } else { Text("This deck is empty.") }
        }.navigationTitle(name).navigationBarTitleDisplayMode(.inline)
    }
}

private struct Library: View {
    @EnvironmentObject var store: StudyStore
    @State private var query = ""
    @State private var savedOnly = false
    private var filtered: [Card] {
        store.cards.filter { card in
            (!savedOnly || store.history.marks[card.id]?.favorite == true) &&
            (query.isEmpty || [card.term, card.theory, card.question, card.answer].joined(separator: " ").localizedCaseInsensitiveContains(query))
        }
    }
    var body: some View {
        List {
            Toggle("Favorites only", isOn: $savedOnly)
            let result = filtered
            if result.isEmpty { Text(savedOnly ? "Bookmark a flashcard to find it here." : "No cards match your search.").foregroundStyle(.secondary) }
            ForEach(Array(result.enumerated()), id: \.element.id) { index, card in
                NavigationLink { Reader(cards: result, name: card.theory, start: index) } label: {
                    VStack(alignment: .leading, spacing: 4) { Text(card.theory).font(.caption).foregroundStyle(mint); Text(card.question) }
                }
            }
        }.navigationTitle("Card library").searchable(text: $query, prompt: "Search theories and concepts")
    }
}

private struct Plan: View {
    @EnvironmentObject var store: StudyStore
    static let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    static let names = Deck.all.map(\.name) + ["Mixed review", "Practice quiz"]
    static var today: Int { (Calendar.current.component(.weekday, from: Date()) + 5) % 7 }
    static var todayTitle: String { names[today] }
    var body: some View {
        Page {
            ForEach(0..<7) { day in
                NavigationLink {
                    if day == 6 { QuizStart() }
                    else {
                        let deck = day < 5 ? store.cards.filter { $0.theory == Self.names[day] } : store.cards
                        let pending = deck.sorted { lhs, rhs in
                            let left = store.history.marks[lhs.id], right = store.history.marks[rhs.id]
                            if (left?.mastered == true) != (right?.mastered == true) { return right?.mastered == true }
                            return (left?.changed ?? .distantPast) < (right?.changed ?? .distantPast)
                        }
                        Reader(cards: Array((pending.isEmpty ? deck : pending).prefix(10)), name: Self.names[day])
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(Self.days[day] + (day == Self.today ? " · Today" : "")).font(.caption).foregroundStyle(mint)
                        Text(Self.names[day]).font(.headline)
                        Text(day < 6 ? "10-card study session" : "Mixed theory questions").font(.footnote).foregroundStyle(.secondary)
                    }.panel(day < 5 ? Deck.all[day].tint : mint)
                }
            }
        }.buttonStyle(.plain).navigationTitle("Daily study plan")
    }
}

private struct Round: Identifiable {
    let id = UUID()
    let card: Card
    let choices: [String]
    init(card: Card, bank: [Card]) {
        self.card = card
        var terms = [card.term]
        for candidate in bank.filter({ $0.theory == card.theory }).shuffled() + bank.shuffled()
            where !terms.contains(candidate.term) {
            terms.append(candidate.term)
            if terms.count == 4 { break }
        }
        choices = terms.shuffled()
    }
}
private struct QuizStart: View {
    @EnvironmentObject var store: StudyStore
    @State private var scope = "All theories"
    var body: some View {
        Page {
            Text("Practice quiz").font(editorial(36))
            Text("Answer ten questions. After each choice, read the explanation before moving on.")
            Picker("Question pool", selection: $scope) {
                ForEach(["All theories"] + Deck.all.map(\.name), id: \.self) { Text($0) }
            }.pickerStyle(.menu)
            let pool = store.cards.filter { scope == "All theories" || $0.theory == scope }
            NavigationLink("Start quiz") { QuizSession(pool: pool, bank: store.cards) }
                .buttonStyle(.borderedProminent).disabled(pool.isEmpty)
        }
    }
}
private struct QuizSession: View {
    @EnvironmentObject var store: StudyStore
    @State private var rounds: [Round]
    @State private var index = 0
    @State private var picked: String?
    @State private var score = 0
    init(pool: [Card], bank: [Card]) {
        _rounds = State(initialValue: pool.shuffled().prefix(10).map { Round(card: $0, bank: bank) })
    }
    var body: some View {
        Page {
            if index == rounds.count {
                Text("Quiz complete").font(editorial(32))
                Text("\(score) of \(rounds.count) correct").font(.title2)
                Text("Your score is saved in Progress.")
            } else {
                let item = rounds[index]
                Text("Question \(index + 1) of \(rounds.count)").foregroundStyle(mint)
                Text(item.card.question).font(editorial(26))
                ForEach(item.choices, id: \.self) { choice in
                    Button {
                        guard picked == nil else { return }
                        picked = choice
                        if choice == item.card.term { score += 1 }
                        store.mark(item.card) { $0.reviewed = true }
                    } label: {
                        HStack {
                            Text(choice)
                            Spacer()
                            if picked != nil && choice == item.card.term { Image(systemName: "checkmark.circle.fill") }
                            else if picked == choice { Image(systemName: "xmark.circle") }
                        }.panel(picked != nil && choice == item.card.term ? mint : .white)
                    }.buttonStyle(.plain).disabled(picked != nil)
                }
                if let picked {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(picked == item.card.term ? "Correct" : "Answer · " + item.card.term).bold()
                        Text(item.card.answer)
                    }.panel(mint)
                    Button(index + 1 == rounds.count ? "Save result" : "Next question") {
                        if index + 1 == rounds.count { store.record(correct: score, total: rounds.count) }
                        self.picked = nil
                        index += 1
                    }.buttonStyle(.borderedProminent)
                }
            }
        }.navigationTitle("Quiz").navigationBarTitleDisplayMode(.inline)
    }
}
private struct ProgressPage: View {
    @EnvironmentObject var store: StudyStore
    var body: some View {
        Page {
            Text("Study progress").font(editorial(34))
            ForEach(Deck.all) { deck in
                let cards = store.cards.filter { $0.theory == deck.name }
                let reviewed = cards.filter { store.history.marks[$0.id]?.reviewed == true }.count
                let learned = cards.filter { store.history.marks[$0.id]?.mastered == true }.count
                VStack(alignment: .leading, spacing: 9) {
                    Label(deck.name, systemImage: deck.symbol).font(.headline)
                    ProgressView(value: Double(learned), total: Double(max(1, cards.count))).tint(deck.tint)
                    Text("\(reviewed) reviewed · \(learned) of \(cards.count) learned").font(.caption)
                }.panel(deck.tint)
            }
            Text("Recent quizzes").font(editorial(25))
            if store.history.quizzes.isEmpty { Text("Complete a quiz to see your first result.").foregroundStyle(.secondary) }
            ForEach(Array(store.history.quizzes.suffix(10).reversed())) { result in
                HStack { Text(result.date, style: .date); Spacer(); Text("\(result.correct) / \(result.total)").bold() }.panel()
            }
        }
    }
}
private struct ReferencePage: View {
    #if CLOUD_STUDY
    @AppStorage("apple-study-user") private var user = ""
    @State private var signInMessage = ""
    #endif
    var body: some View {
        List {
            Section("NCE exam review") {
                Text("Use your exam date to select the matching NBCC outline. Review a domain, practice a vignette, then explain why you ruled out each distractor.")
                Link("Official NCE outlines and candidate resources", destination: URL(string: "https://www.nbcc.org/exams/nce")!)
                NavigationLink("Six practice vignettes") { ExamCases() }
                NavigationLink("Practice counseling theory questions") { QuizStart() }
            }
            Section("DSM-5-TR quick reference") {
                Text("Differential diagnosis compares plausible explanations. A specifier adds detail to a diagnosis. Comorbidity describes disorders present together.")
                Text("When reading a study vignette, identify onset, duration, impairment, context, and possible substance or medical contributions. Consult the manual for the full criteria.")
                Link("APA educational resources", destination: URL(string: "https://www.psychiatry.org/psychiatrists/practice/dsm/educational-resources")!)
                Link("DSM text and criteria updates", destination: URL(string: "https://www.psychiatry.org/psychiatrists/practice/dsm/updates-to-dsm/updates-to-dsm-5-tr-criteria-text")!)
            }
            Section("Test-taking strategies") {
                Text("Before reading the choices, identify the task. A question about the first response tests sequence. A question about the best reflection tests how closely you follow the client's meaning.")
                Text("Write a one-sentence reason for every missed answer. Revisit it in two days and solve the question again from memory.")
            }
            #if CLOUD_STUDY
            Section("Account") {
                if user.isEmpty {
                    SignInWithAppleButton(.signIn, onRequest: { _ in }, onCompletion: { result in
                        switch result {
                        case .success(let auth):
                            if let credential = auth.credential as? ASAuthorizationAppleIDCredential { user = credential.user; signInMessage = "" }
                        case .failure(let error): signInMessage = error.localizedDescription
                        }
                    }).frame(height: 44)
                } else { Button("Sign out of app") { user = "" } }
                if !signInMessage.isEmpty { Text(signInMessage) }
                Text("Study history syncs through the device’s iCloud account when iCloud is available.")
            }.onAppear {
                guard !user.isEmpty else { return }
                ASAuthorizationAppleIDProvider().getCredentialState(forUserID: user) { state, _ in
                    if state == .revoked || state == .notFound { DispatchQueue.main.async { user = "" } }
                }
            }
            #endif
        }.navigationTitle("Study guide")
    }
}

private struct ExamCase: Codable {
    let domain, prompt: String
    let choices: [String]
    let correct: Int
    let rationale: String
}
private struct ExamCases: View {
    private let cases: [ExamCase] = {
        guard let url = Bundle.main.url(forResource: "exam", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([ExamCase].self, from: data)) ?? []
    }()
    @State private var selections: [Int: Int] = [:]
    var body: some View {
        Page {
            Text("Practice vignettes").font(editorial(32))
            Text("Original practice questions. Select an answer to see the reasoning.")
            ForEach(cases.indices, id: \.self) { i in
                let item = cases[i]
                VStack(alignment: .leading, spacing: 12) {
                    Text(item.domain).font(.caption.bold()).foregroundStyle(mint)
                    Text(item.prompt).font(.headline)
                    ForEach(item.choices.indices, id: \.self) { j in
                        Button(item.choices[j]) { selections[i] = j }.buttonStyle(.bordered).disabled(selections[i] != nil)
                    }
                    if let pick = selections[i] {
                        Text(pick == item.correct ? "Correct" : "Answer · " + item.choices[item.correct]).bold()
                        Text(item.rationale)
                    }
                }.panel()
            }
        }.navigationTitle("NCE review").navigationBarTitleDisplayMode(.inline)
    }
}
