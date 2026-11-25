import Foundation

@MainActor
final class Store: ObservableObject {
    @Published var state: AppState { didSet { save() } }

    private let url = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("state.json")

    // Điểm thưởng / phạt
    private let pointsPerTask = 10
    private let fullDayBonus = 20
    private let streakBonusPerDay = 2   // tối đa 30 ngày
    private let penaltyPerMissed = 5
    private let streakBreakPenalty = 10

    static func key(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }

    static func date(_ k: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: k)
    }

    init() {
        if let data = try? Data(contentsOf: url),
           let s = try? JSONDecoder().decode(AppState.self, from: data) {
            state = s
        } else {
            state = AppState()
        }
        evaluatePastDays()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(state) { try? data.write(to: url) }
        Notifier.schedule(state.tasks)
    }

    // MARK: - Công việc
    func add(title: String, hour: Int, minute: Int, remind: Bool) {
        state.tasks.append(RoutineTask(title: title, hour: hour, minute: minute, remind: remind))
    }

    func delete(ids: [UUID]) {
        state.tasks.removeAll { ids.contains($0.id) }
    }

    func isDone(_ t: RoutineTask) -> Bool {
        (state.done[Store.key(Date())] ?? []).contains(t.id)
    }

    func toggle(_ t: RoutineTask) {
        let k = Store.key(Date())
        var list = state.done[k] ?? []
        if let i = list.firstIndex(of: t.id) { list.remove(at: i) } else { list.append(t.id) }
        state.done[k] = list
    }

    // MARK: - Chấm điểm các ngày đã qua
    func evaluatePastDays() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        guard let last = state.lastEvaluated, let lastDate = Store.date(last) else {
            state.lastEvaluated = Store.key(yesterday)   // bắt đầu tính từ hôm nay
            return
        }
        var cursor = cal.date(byAdding: .day, value: 1, to: lastDate)!
        var s = state
        while cursor < today {
            evaluate(day: cursor, into: &s)
            s.lastEvaluated = Store.key(cursor)
            cursor = cal.date(byAdding: .day, value: 1, to: cursor)!
        }
        if s.lastEvaluated != state.lastEvaluated || s.log.count != state.log.count {
            state = s
        }
    }

    private func evaluate(day: Date, into s: inout AppState) {
        guard !s.tasks.isEmpty else { return }
        let k = Store.key(day)
        let doneIDs = Set(s.done[k] ?? [])
        let completed = s.tasks.filter { doneIDs.contains($0.id) }.count
        let total = s.tasks.count

        if completed == total {
            s.streak += 1
            s.bestStreak = max(s.bestStreak, s.streak)
            let gain = completed * pointsPerTask + fullDayBonus + min(s.streak, 30) * streakBonusPerDay
            s.points += gain
            s.log.insert("\(k): đủ \(total)/\(total) → +\(gain) điểm, chuỗi \(s.streak) 🔥", at: 0)
        } else {
            let missed = total - completed
            var loss = missed * penaltyPerMissed
            let hadStreak = s.streak > 0
            if hadStreak { loss += streakBreakPenalty }
            s.points = max(0, s.points + completed * pointsPerTask - loss)
            s.streak = 0
            s.log.insert("\(k): \(completed)/\(total) → bỏ lỡ \(missed), -\(loss) điểm\(hadStreak ? ", mất chuỗi 💔" : "")", at: 0)
        }
        if s.log.count > 60 { s.log.removeLast(s.log.count - 60) }
    }
}
