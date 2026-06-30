import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
final class InsightsViewModel: ObservableObject {
    @Published var insights: [Insight] = []
    @Published var goals: [Goal] = []
    @Published var streaks: [Streak] = []
    @Published var lifetimeStats: LifetimeStats = LifetimeStats()
    @Published var categories: [Category] = []
    @Published var allLogs: [TimeLog] = []
    
    var modelContext: ModelContext?
    
    struct Insight: Identifiable {
        let id = UUID()
        let text: String
        let icon: String
        let color: Color
    }
    
    struct LifetimeStats {
        var totalHours: Double = 0
        var totalDays: Int = 0
        var totalLogs: Int = 0
        var averageHoursPerDay: Double = 0
        var longestSession: TimeInterval = 0
        var averageDuration: TimeInterval = 0
        var mostUsedCategory: String = "—"
        var longestStreak: Int = 0
        var mostProductiveDay: String = "—"
        var mostProductiveMonth: String = "—"
        var categoryTotals: [(name: String, hours: Double, color: Color)] = []
    }
    
    func load(context: ModelContext) {
        self.modelContext = context
        refresh()
    }
    
    func refresh() {
        guard let context = modelContext else { return }
        
        let logDesc = FetchDescriptor<TimeLog>(sortBy: [SortDescriptor(\.startDate)])
        let catDesc = FetchDescriptor<Category>()
        let goalDesc = FetchDescriptor<Goal>()
        let streakDesc = FetchDescriptor<Streak>()
        
        allLogs    = (try? context.fetch(logDesc)) ?? []
        categories = (try? context.fetch(catDesc)) ?? []
        goals      = (try? context.fetch(goalDesc)) ?? []
        streaks    = (try? context.fetch(streakDesc)) ?? []
        
        computeInsights()
        computeLifetimeStats()
        updateStreaks()
    }
    
    // MARK: - Goal Progress
    
    func progress(for goal: Goal) -> Double {
        let logs = logsForGoal(goal)
        let total = logs.reduce(0) { $0 + $1.duration } / 3600
        return min(total / goal.targetHours, 1.0)
    }
    
    func completedHours(for goal: Goal) -> Double {
        logsForGoal(goal).reduce(0) { $0 + $1.duration } / 3600
    }
    
    private func logsForGoal(_ goal: Goal) -> [TimeLog] {
        guard let catID = goal.categoryID else { return [] }
        let period = GoalPeriod(rawValue: goal.targetPeriod) ?? .weekly
        let startDate: Date
        switch period {
        case .daily:   startDate = Date().startOfDay
        case .weekly:  startDate = Date().startOfWeek
        case .monthly: startDate = Date().startOfMonth
        }
        return allLogs.filter { $0.categoryID == catID && $0.startDate >= startDate }
    }
    
    func categoryFor(goal: Goal) -> Category? {
        guard let id = goal.categoryID else { return nil }
        return categories.first { $0.id == id }
    }
    
    // MARK: - Insights
    
    private func computeInsights() {
        var result: [Insight] = []
        let cal = Calendar.current
        
        // Compare this week vs last week by category
        let thisWeekStart = Date().startOfWeek
        guard let lastWeekStart = cal.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart) else {
            insights = result; return
        }
        
        let thisWeekLogs = allLogs.filter { $0.startDate >= thisWeekStart }
        let lastWeekLogs = allLogs.filter { $0.startDate >= lastWeekStart && $0.startDate < thisWeekStart }
        
        var thisByCat:  [UUID: Double] = [:]
        var lastByCat:  [UUID: Double] = [:]
        
        for log in thisWeekLogs { if let id = log.categoryID { thisByCat[id, default: 0] += log.duration / 3600 } }
        for log in lastWeekLogs { if let id = log.categoryID { lastByCat[id, default: 0] += log.duration / 3600 } }
        
        for cat in categories {
            let thisH = thisByCat[cat.id] ?? 0
            let lastH = lastByCat[cat.id] ?? 0
            if lastH > 0 && thisH > 0 {
                let pct = ((thisH - lastH) / lastH) * 100
                if abs(pct) >= 10 {
                    let dir = pct > 0 ? "more" : "less"
                    let icon = pct > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
                    let color: Color = pct > 0 ? AppTheme.sage : AppTheme.blushPink
                    result.append(Insight(
                        text: "You spent \(Int(abs(pct)))% \(dir) time on \(cat.name) this week.",
                        icon: icon, color: color
                    ))
                }
            } else if thisH > 0 && lastH == 0 {
                result.append(Insight(
                    text: "Great start — you logged \(cat.name) time this week!",
                    icon: "star.fill", color: AppTheme.goldCat
                ))
            }
        }
        
        // Daily streak insight
        let uniqueDays = Set(allLogs.map { $0.startDate.startOfDay }).count
        if uniqueDays >= 7 {
            result.append(Insight(
                text: "You've tracked time on \(uniqueDays) days total. Keep it up!",
                icon: "flame.fill", color: AppTheme.softRose
            ))
        }
        
        // Most productive day
        var dayTotals: [Int: Double] = [:]
        for log in allLogs {
            let weekday = cal.component(.weekday, from: log.startDate)
            dayTotals[weekday, default: 0] += log.duration
        }
        if let bestDay = dayTotals.max(by: { $0.value < $1.value })?.key {
            let names = ["", "Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
            result.append(Insight(
                text: "\(names[bestDay]) is your most productive day of the week.",
                icon: "chart.bar.fill", color: AppTheme.lavender
            ))
        }
        
        // Today tracking
        let todayLogs = allLogs.filter { $0.startDate.isSameDay(as: Date()) }
        let todayHours = todayLogs.reduce(0) { $0 + $1.duration } / 3600
        if todayHours >= 8 {
            result.append(Insight(
                text: "You've tracked \(String(format: "%.1f", todayHours)) hours today. Impressive!",
                icon: "checkmark.seal.fill", color: AppTheme.sage
            ))
        }
        
        if result.isEmpty {
            result.append(Insight(
                text: "Keep logging to unlock personalized insights.",
                icon: "lightbulb.fill", color: AppTheme.goldCat
            ))
        }
        
        insights = result
    }
    
    // MARK: - Lifetime Stats
    
    private func computeLifetimeStats() {
        var stats = LifetimeStats()
        let cal = Calendar.current
        
        stats.totalLogs  = allLogs.count
        stats.totalHours = allLogs.reduce(0) { $0 + $1.duration } / 3600
        
        let uniqueDays = Set(allLogs.map { $0.startDate.startOfDay })
        stats.totalDays = uniqueDays.count
        stats.averageHoursPerDay = stats.totalDays > 0 ? stats.totalHours / Double(stats.totalDays) : 0
        stats.longestSession = allLogs.map(\.duration).max() ?? 0
        stats.averageDuration = stats.totalLogs > 0 ? allLogs.reduce(0) { $0 + $1.duration } / Double(stats.totalLogs) : 0
        
        // Category totals
        var catHours: [UUID: Double] = [:]
        for log in allLogs { if let id = log.categoryID { catHours[id, default: 0] += log.duration / 3600 } }
        stats.categoryTotals = catHours.compactMap { (id, hours) in
            guard let cat = categories.first(where: { $0.id == id }) else { return nil }
            return (cat.name, hours, cat.color)
        }.sorted { $0.hours > $1.hours }
        
        stats.mostUsedCategory = stats.categoryTotals.first?.name ?? "—"
        
        // Most productive weekday
        var weekdayH: [Int: Double] = [:]
        for log in allLogs {
            let d = cal.component(.weekday, from: log.startDate)
            weekdayH[d, default: 0] += log.duration
        }
        if let best = weekdayH.max(by: { $0.value < $1.value })?.key {
            let names = ["", "Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
            stats.mostProductiveDay = names[best]
        }
        
        // Most productive month
        var monthH: [Int: Double] = [:]
        for log in allLogs {
            let m = cal.component(.month, from: log.startDate)
            monthH[m, default: 0] += log.duration
        }
        if let best = monthH.max(by: { $0.value < $1.value })?.key {
            let names = ["","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
            stats.mostProductiveMonth = names[best]
        }
        
        // Longest streak (computed from unique days)
        let sortedDays = uniqueDays.sorted()
        var maxStreak = 0, cur = 0
        var prev: Date? = nil
        for day in sortedDays {
            if let p = prev, cal.dateComponents([.day], from: p, to: day).day == 1 {
                cur += 1
            } else { cur = 1 }
            maxStreak = max(maxStreak, cur)
            prev = day
        }
        stats.longestStreak = maxStreak
        
        lifetimeStats = stats
    }
    
    // MARK: - Streaks
    
    private func updateStreaks() {
        guard let context = modelContext else { return }
        let cal = Calendar.current
        
        // Daily logging streak
        let uniqueDays = Set(allLogs.map { $0.startDate.startOfDay }).sorted()
        var currentStreak = 0
        var longest = 0
        var cur = 0
        var prev: Date? = nil
        
        for day in uniqueDays {
            if let p = prev, cal.dateComponents([.day], from: p, to: day).day == 1 {
                cur += 1
            } else { cur = 1 }
            longest = max(longest, cur)
            if day.isSameDay(as: Date()) || day.isSameDay(as: cal.date(byAdding: .day, value: -1, to: Date())!) {
                currentStreak = cur
            }
            prev = day
        }
        
        let dailyDescriptor = FetchDescriptor<Streak>(predicate: #Predicate { $0.streakType == "daily_logging" })
        if let existing = try? context.fetch(dailyDescriptor).first {
            existing.currentCount = currentStreak
            existing.longestCount = longest
            existing.lastUpdated = Date()
        } else {
            let s = Streak(streakType: "daily_logging", currentCount: currentStreak, longestCount: longest)
            context.insert(s)
        }
        
        try? context.save()
        
        let streakDesc = FetchDescriptor<Streak>()
        streaks = (try? context.fetch(streakDesc)) ?? []
    }
    
    func addGoal(_ goal: Goal) {
        guard let context = modelContext else { return }
        context.insert(goal)
        try? context.save()
        refresh()
    }
    
    func deleteGoal(_ goal: Goal) {
        guard let context = modelContext else { return }
        context.delete(goal)
        try? context.save()
        refresh()
    }
}
