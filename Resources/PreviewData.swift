import Foundation
import SwiftData
import SwiftUI

// MARK: - Preview Data

@MainActor
enum PreviewData {
    static var container: ModelContainer = {
        let schema = Schema([TimeLog.self, Category.self, Goal.self, Streak.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        
        // Insert categories
        let categories = sampleCategories
        for cat in categories { container.mainContext.insert(cat) }
        
        // Insert logs
        for log in sampleLogs(categories: categories) { container.mainContext.insert(log) }
        
        // Insert goals
        for goal in sampleGoals(categories: categories) { container.mainContext.insert(goal) }
        
        // Streak
        let streak = Streak(streakType: "daily_logging", currentCount: 7, longestCount: 14)
        container.mainContext.insert(streak)
        
        try! container.mainContext.save()
        return container
    }()
    
    static var sampleCategories: [Category] = [
        Category(name: "Work",      colorHex: "#A0B8C8", iconName: "briefcase.fill",       sortOrder: 0),
        Category(name: "Study",     colorHex: "#B8A0C8", iconName: "book.fill",             sortOrder: 1),
        Category(name: "Exercise",  colorHex: "#E8A0B0", iconName: "figure.run",            sortOrder: 2),
        Category(name: "Sleep",     colorHex: "#7DAF8C", iconName: "moon.fill",             sortOrder: 3),
        Category(name: "Reading",   colorHex: "#C8A878", iconName: "text.book.closed.fill", sortOrder: 4),
        Category(name: "Social",    colorHex: "#C8B0A0", iconName: "person.2.fill",         sortOrder: 5),
    ]
    
    static func sampleLogs(categories: [Category]) -> [TimeLog] {
        let now = Date()
        let cal = Calendar.current
        var logs: [TimeLog] = []
        
        func log(_ catIdx: Int, _ hoursAgo: Double, _ durationHours: Double, mood: Int = 3, notes: String = "") -> TimeLog {
            let end   = now.addingTimeInterval(-hoursAgo * 3600)
            let start = end.addingTimeInterval(-durationHours * 3600)
            return TimeLog(startDate: start, endDate: end, categoryID: categories[catIdx].id, notes: notes, moodScore: mood)
        }
        
        // Today
        logs += [
            log(3, 0,    8,  mood: 4, notes: "Restful night"),     // Sleep
            log(0, 0.5,  4,  mood: 4, notes: "Productive morning"),// Work
            log(2, 4,    1,  mood: 5, notes: "Morning jog"),        // Exercise
            log(4, 5,    0.5,mood: 3),                              // Reading
        ]
        
        // Past 6 days
        for dayOff in 1...6 {
            guard let dayStart = cal.date(byAdding: .day, value: -dayOff, to: now.startOfDay) else { continue }
            let offsets: [(Int, Double, Double, Int)] = [
                (3, 0,    7.5, 4),
                (0, 8,    6,   3),
                (1, 14,   2,   4),
                (2, 16,   1,   5),
            ]
            for (catIdx, hoursAfterMidnight, dur, mood) in offsets {
                let start = dayStart.addingTimeInterval(hoursAfterMidnight * 3600)
                let end   = start.addingTimeInterval(dur * 3600)
                logs.append(TimeLog(startDate: start, endDate: end, categoryID: categories[catIdx].id, moodScore: mood))
            }
        }
        
        return logs
    }
    
    static func sampleGoals(categories: [Category]) -> [Goal] {
        [
            Goal(categoryID: categories[2].id, categoryName: "Exercise",  targetHours: 5,  targetPeriod: "weekly"),
            Goal(categoryID: categories[4].id, categoryName: "Reading",   targetHours: 10, targetPeriod: "weekly"),
            Goal(categoryID: categories[0].id, categoryName: "Work",      targetHours: 40, targetPeriod: "weekly"),
        ]
    }
}
