import Foundation
import UserNotifications
import SwiftUI
import Combine

final class NotificationManager: ObservableObject {
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error { print("Notification permission error: \(error)") }
        }
    }
    
    func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["my24.daily.reminder"])
        
        let content = UNMutableNotificationContent()
        content.title = "My24"
        content.body  = "Don't forget to log the rest of today's activities."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour   = 23
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "my24.daily.reminder",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }
    
    func scheduleGapReminder(untrackedHours: Double) {
        guard untrackedHours > 0.25 else { return }
        
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Untracked Time"
        let h = Int(untrackedHours)
        let m = Int((untrackedHours - Double(h)) * 60)
        content.body  = "You still have \(h)h \(m)m untracked today."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "my24.gap.reminder", content: content, trigger: trigger)
        center.add(request)
    }
}
