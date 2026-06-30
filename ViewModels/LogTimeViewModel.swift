import Foundation
import SwiftUI
import SwiftData
import Combine

// MARK: - Log Time ViewModel

@MainActor
final class LogTimeViewModel: ObservableObject {
    
    // MARK: - Timer State
    @Published var timerState: TimerState = .idle
    @Published var elapsedSeconds: Double = 0
    @Published var timerStartDate: Date? = nil
    
    // MARK: - Entry Form
    @Published var selectedCategory: Category? = nil
    @Published var notes: String = ""
    @Published var moodScore: Int = 3
    
    // Manual entry
    @Published var manualStartDate: Date = Date().addingTimeInterval(-3600)
    @Published var manualEndDate: Date = Date()
    
    // MARK: - UI
    @Published var showSaveModal: Bool = false
    @Published var activeMode: EntryMode = .timer
    
    // MARK: - Previous Logs (for this session)
    @Published var recentLogs: [TimeLog] = []
    @Published var categories: [Category] = []
    
    private var timer: Timer? = nil
    var modelContext: ModelContext?
    
    enum TimerState {
        case idle, running, paused
    }
    
    enum EntryMode: String, CaseIterable {
        case timer  = "Timer"
        case manual = "Manual"
    }
    
    func load(context: ModelContext) {
        self.modelContext = context
        refreshLogs()
    }
    
    func refreshLogs() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<TimeLog>(sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        recentLogs = (try? context.fetch(descriptor)) ?? []
        let catDescriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortOrder)])
        categories = (try? context.fetch(catDescriptor)) ?? []
    }
    
    // MARK: - Timer Actions
    
    func startTimer() {
        timerStartDate = Date()
        timerState = .running
        startTicking()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    func pauseTimer() {
        timerState = .paused
        stopTicking()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func resumeTimer() {
        timerState = .running
        startTicking()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func stopTimer() {
        timerState = .idle
        stopTicking()
        showSaveModal = true
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    
    func resetTimer() {
        timerState = .idle
        elapsedSeconds = 0
        timerStartDate = nil
        notes = ""
        moodScore = 3
        selectedCategory = nil
        stopTicking()
    }
    
    private func startTicking() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.elapsedSeconds += 1
            }
        }
    }
    
    private func stopTicking() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Save Timer Log
    
    func saveTimerLog() {
        guard let context = modelContext, let start = timerStartDate else { return }
        let end = Date()
        let log = TimeLog(
            startDate: start,
            endDate: end,
            categoryID: selectedCategory?.id,
            notes: notes,
            moodScore: moodScore
        )
        context.insert(log)
        try? context.save()
        refreshLogs()
        resetTimer()
        showSaveModal = false
    }
    
    // MARK: - Save Manual Log
    
    func saveManualLog() {
        guard let context = modelContext else { return }
        guard manualEndDate > manualStartDate else { return }
        let log = TimeLog(
            startDate: manualStartDate,
            endDate: manualEndDate,
            categoryID: selectedCategory?.id,
            notes: notes,
            moodScore: moodScore
        )
        context.insert(log)
        try? context.save()
        refreshLogs()
        resetForm()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    func duplicateLog(_ log: TimeLog) {
        guard let context = modelContext else { return }
        let duration = log.duration
        let end = Date()
        let start = end.addingTimeInterval(-duration)
        let newLog = TimeLog(
            startDate: start,
            endDate: end,
            categoryID: log.categoryID,
            notes: log.notes,
            moodScore: log.moodScore
        )
        context.insert(newLog)
        try? context.save()
        refreshLogs()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    func deleteLog(_ log: TimeLog) {
        guard let context = modelContext else { return }
        context.delete(log)
        try? context.save()
        refreshLogs()
    }
    
    // MARK: - Helpers
    
    var formattedElapsed: String {
        let h = Int(elapsedSeconds) / 3600
        let m = (Int(elapsedSeconds) % 3600) / 60
        let s = Int(elapsedSeconds) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
    
    private func resetForm() {
        notes = ""
        moodScore = 3
        selectedCategory = nil
    }
    
    func category(for log: TimeLog) -> Category? {
        guard let id = log.categoryID else { return nil }
        return categories.first { $0.id == id }
    }
    
    func logsForToday() -> [TimeLog] {
        recentLogs.filter { $0.startDate.isSameDay(as: Date()) }
    }
}
