import UserNotifications

enum Notifier {
    static func requestAuth() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func schedule(_ tasks: [RoutineTask]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        for t in tasks where t.remind {
            let content = UNMutableNotificationContent()
            content.title = "Đến giờ: \(t.title)"
            content.body = "Hoàn thành để giữ chuỗi streak!"
            content.sound = .default
            var comps = DateComponents()
            comps.hour = t.hour
            comps.minute = t.minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            center.add(UNNotificationRequest(identifier: t.id.uuidString, content: content, trigger: trigger))
        }
    }
}
