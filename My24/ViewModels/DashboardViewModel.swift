import Foundation
import SwiftUI
import SwiftData
import Combine

// MARK: - Dashboard ViewModel

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var selectedPeriod: ChartPeriod = .today
    @Published var todayLogs: [TimeLog] = []
    @Published var allLogs: [TimeLog] = []
    @Published var categories: [Category] = []
    
    // Summary stats
    @Published var trackedHoursToday: Double = 0
    @Published var untrackedHoursToday: Double = 0
    @Published var mostUsedCategory: Category? = nil
    @Published var longestSession: TimeInterval = 0
    @Published var averageSessionLength: TimeInterval = 0
    
    // Chart data
    @Published var barChartData: [ChartDataPoint] = []
    @Published var pieChartData: [PieSlice] = []
    @Published var weeklyTrend: [TrendPoint] = []
    @Published var heatmapData: [HeatmapDay] = []
    
    var modelContext: ModelContext?
    
    enum ChartPeriod: String, CaseIterable {
        case today  = "Today"
        case week   = "Week"
        case month  = "Month"
        case year   = "Year"
    }
    
    func load(context: ModelContext) {
        self.modelContext = context
        refresh()
    }
    
    func refresh() {
        guard let context = modelContext else { return }
        
        let allDescriptor = FetchDescriptor<TimeLog>(sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        let catDescriptor  = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortOrder)])
        
        allLogs    = (try? context.fetch(allDescriptor)) ?? []
        categories = (try? context.fetch(catDescriptor)) ?? []
        
        let today = Date()
        todayLogs = allLogs.filter { $0.startDate.isSameDay(as: today) }
        
        computeSummary()
        computeChartData()
    }
    
    private func computeSummary() {
        let totalSeconds = todayLogs.reduce(0) { $0 + $1.duration }
        trackedHoursToday   = totalSeconds / 3600
        untrackedHoursToday = max(0, 24 - trackedHoursToday)
        
        // Most used category
        var categoryDuration: [UUID: Double] = [:]
        for log in todayLogs {
            if let id = log.categoryID {
                categoryDuration[id, default: 0] += log.duration
            }
        }
        if let topID = categoryDuration.max(by: { $0.value < $1.value })?.key {
            mostUsedCategory = categories.first { $0.id == topID }
        }
        
        longestSession       = todayLogs.map(\.duration).max() ?? 0
        averageSessionLength = todayLogs.isEmpty ? 0 : totalSeconds / Double(todayLogs.count)
    }
    
    func computeChartData() {
        switch selectedPeriod {
        case .today:  buildTodayBarChart(); buildPieChart(logs: todayLogs)
        case .week:   buildWeekBarChart();  buildPieChart(logs: weekLogs())
        case .month:  buildMonthBarChart(); buildPieChart(logs: monthLogs())
        case .year:   buildYearBarChart();  buildPieChart(logs: yearLogs())
        }
        buildWeeklyTrend()
        buildHeatmap()
    }
    
    // MARK: - Bar Charts
    
    private func buildTodayBarChart() {
        // Group by hour
        var hourlyData: [Int: Double] = [:]
        for log in todayLogs {
            let hour = Calendar.current.component(.hour, from: log.startDate)
            hourlyData[hour, default: 0] += log.duration / 3600
        }
        barChartData = (6...23).map { h in
            ChartDataPoint(label: "\(h)", value: hourlyData[h] ?? 0, date: Date())
        }
    }
    
    private func buildWeekBarChart() {
        let logs = weekLogs()
        let cal = Calendar.current
        var daily: [Int: Double] = [:]
        for log in logs {
            let day = cal.component(.weekday, from: log.startDate)
            daily[day, default: 0] += log.duration / 3600
        }
        let names = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
        barChartData = (1...7).map { d in
            ChartDataPoint(label: names[d-1], value: daily[d] ?? 0, date: Date())
        }
    }
    
    private func buildMonthBarChart() {
        let logs = monthLogs()
        let cal = Calendar.current
        var daily: [Int: Double] = [:]
        for log in logs {
            let day = cal.component(.day, from: log.startDate)
            daily[day, default: 0] += log.duration / 3600
        }
        let range = cal.range(of: .day, in: .month, for: Date())!
        barChartData = range.map { d in
            ChartDataPoint(label: "\(d)", value: daily[d] ?? 0, date: Date())
        }
    }
    
    private func buildYearBarChart() {
        let logs = yearLogs()
        let cal = Calendar.current
        var monthly: [Int: Double] = [:]
        for log in logs {
            let month = cal.component(.month, from: log.startDate)
            monthly[month, default: 0] += log.duration / 3600
        }
        let monthNames = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        barChartData = (1...12).map { m in
            ChartDataPoint(label: monthNames[m-1], value: monthly[m] ?? 0, date: Date())
        }
    }
    
    // MARK: - Pie Chart
    
    private func buildPieChart(logs: [TimeLog]) {
        var catDurations: [UUID: Double] = [:]
        for log in logs {
            if let id = log.categoryID {
                catDurations[id, default: 0] += log.duration / 3600
            }
        }
        let total = catDurations.values.reduce(0, +)
        guard total > 0 else { pieChartData = []; return }
        
        pieChartData = catDurations.compactMap { (catID, hours) in
            guard let cat = categories.first(where: { $0.id == catID }) else { return nil }
            return PieSlice(
                label: cat.name,
                value: hours,
                percentage: hours / total,
                color: cat.color
            )
        }.sorted { $0.value > $1.value }
    }
    
    // MARK: - Trend Line
    
    private func buildWeeklyTrend() {
        let cal = Calendar.current
        weeklyTrend = (0..<7).map { daysAgo in
            let date = cal.date(byAdding: .day, value: -daysAgo, to: Date())!
            let dayLogs = allLogs.filter { $0.startDate.isSameDay(as: date) }
            let hours = dayLogs.reduce(0) { $0 + $1.duration } / 3600
            return TrendPoint(date: date, value: hours)
        }.reversed()
    }
    
    // MARK: - Heatmap
    
    func buildHeatmap() {
        let cal = Calendar.current
        var loggedDays: [Date: Double] = [:]
        for log in allLogs {
            let day = log.startDate.startOfDay
            loggedDays[day, default: 0] += log.duration / 3600
        }
        
        let today = Date().startOfDay
        heatmapData = (0..<365).compactMap { i in
            guard let date = cal.date(byAdding: .day, value: -i, to: today) else { return nil }
            return HeatmapDay(date: date, hours: loggedDays[date] ?? 0)
        }.reversed()
    }
    
    // MARK: - Log Filters
    
    private func weekLogs() -> [TimeLog] {
        let start = Date().startOfWeek
        return allLogs.filter { $0.startDate >= start }
    }
    
    private func monthLogs() -> [TimeLog] {
        let start = Date().startOfMonth
        return allLogs.filter { $0.startDate >= start }
    }
    
    private func yearLogs() -> [TimeLog] {
        let start = Date().startOfYear
        return allLogs.filter { $0.startDate >= start }
    }
    
    // MARK: - Helper to get category
    
    func category(for log: TimeLog) -> Category? {
        guard let id = log.categoryID else { return nil }
        return categories.first { $0.id == id }
    }
    
    func logsForCategory(_ catID: UUID, in period: ChartPeriod) -> [TimeLog] {
        let periodLogs: [TimeLog]
        switch period {
        case .today:  periodLogs = todayLogs
        case .week:   periodLogs = weekLogs()
        case .month:  periodLogs = monthLogs()
        case .year:   periodLogs = yearLogs()
        }
        return periodLogs.filter { $0.categoryID == catID }
    }
}

// MARK: - Chart Data Structures

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let date: Date
}

struct PieSlice: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let percentage: Double
    let color: Color
}

struct TrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct HeatmapDay: Identifiable {
    let id = UUID()
    let date: Date
    let hours: Double
    
    var intensity: Double {
        min(hours / 8.0, 1.0)
    }
}
