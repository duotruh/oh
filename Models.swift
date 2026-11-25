import Foundation

struct RoutineTask: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var hour: Int
    var minute: Int
    var remind: Bool = true
}

struct AppState: Codable {
    var tasks: [RoutineTask] = []
    var done: [String: [UUID]] = [:]   // "yyyy-MM-dd" -> task ids completed
    var streak = 0
    var bestStreak = 0
    var points = 0
    var lastEvaluated: String? = nil
    var log: [String] = []
}
