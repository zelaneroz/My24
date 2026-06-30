import SwiftUI
import SwiftData
import Foundation
import Combine

// MARK: - Log Time View

struct LogTimeView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var vm = LogTimeViewModel()
    @State private var selectedLog: TimeLog? = nil
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    LazyVStack(spacing: 24) {
                        DashboardHeader(subtitle: "Track your time")
                            .padding(.top, 4)
                        
                        NavigationLink(destination: CategoriesView()) {
                            HStack {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppTheme.mutedRose)
                                Text("Manage Categories")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppTheme.mutedRose)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.blushBorder)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(AppTheme.blushLight)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .padding(.horizontal, 20)
                            .cardShadow()
                        }
                        
                        // Mode Picker
                        modePicker
                        
                        // Content by mode
                        if vm.activeMode == .timer {
                            timerSection
                        } else {
                            manualEntrySection
                        }
                        
                        // Previous Logs
                        previousLogsSection
                        
                        Spacer(minLength: 100)
                    }
                }
                .background(AppTheme.cream)
                .scrollIndicators(.hidden)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $vm.showSaveModal) {
                SaveTimerSheet(vm: vm)
            }
            .sheet(item: $selectedLog) { log in
                EditLogSheet(log: log)
                    .onDisappear { vm.refreshLogs() }
            }
        }
        .onAppear { vm.load(context: modelContext) }
    }
    
    // MARK: - Mode Picker
    
    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach(LogTimeViewModel.EntryMode.allCases, id: \.rawValue) { mode in
                Button(mode.rawValue) {
                    withAnimation(.easeInOut(duration: 0.2)) { vm.activeMode = mode }
                }
                .font(.system(size: 15, weight: vm.activeMode == mode ? .semibold : .regular))
                .foregroundColor(vm.activeMode == mode ? AppTheme.deepRose : AppTheme.mutedRose)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    vm.activeMode == mode
                    ? AppTheme.blushMid
                    : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(4)
        .background(AppTheme.blushLight)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
        .cardShadow()
    }
    
    // MARK: - Timer Section
    
    private var timerSection: some View {
        VStack(spacing: 20) {
            // Timer Display
            VStack(spacing: 16) {
                Text(vm.formattedElapsed)
                    .font(.system(size: 56, weight: .ultraLight, design: .monospaced))
                    .foregroundColor(AppTheme.deepRose)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                
                // State badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(timerStateColor)
                        .frame(width: 8, height: 8)
                        .scaleEffect(vm.timerState == .running ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: vm.timerState == .running)
                    Text(timerStateLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.mutedRose)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .background(AppTheme.blushLight)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .cardShadow()
            .padding(.horizontal, 20)
            
            // Timer Controls
            HStack(spacing: 16) {
                if vm.timerState == .idle {
                    Button(action: vm.startTimer) {
                        Label("Start", systemImage: "play.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle(backgroundColor: AppTheme.sage))
                } else if vm.timerState == .running {
                    Button(action: vm.pauseTimer) {
                        Label("Pause", systemImage: "pause.fill")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button(action: vm.stopTimer) {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle(backgroundColor: AppTheme.deepRose))
                } else {
                    Button(action: vm.resumeTimer) {
                        Label("Resume", systemImage: "play.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle(backgroundColor: AppTheme.sage))
                    
                    Button(action: vm.stopTimer) {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle(backgroundColor: AppTheme.deepRose))
                }
            }
            .padding(.horizontal, 20)
        }
        .transition(.opacity.combined(with: .move(edge: .leading)))
    }
    
    private var timerStateColor: Color {
        switch vm.timerState {
        case .idle:    return AppTheme.blushBorder
        case .running: return AppTheme.sage
        case .paused:  return AppTheme.goldCat
        }
    }
    
    private var timerStateLabel: String {
        switch vm.timerState {
        case .idle:    return "Ready to track"
        case .running: return "Tracking..."
        case .paused:  return "Paused"
        }
    }
    
    // MARK: - Manual Entry Section
    
    private var manualEntrySection: some View {
        VStack(spacing: 16) {
            // Time pickers
            VStack(spacing: 12) {
                DatePickerRow(label: "Start", date: $vm.manualStartDate)
                DatePickerRow(label: "End", date: $vm.manualEndDate)
            }
            .themedCard()
            .padding(.horizontal, 20)
            
            // Category picker
            categoryPickerCard
            
            // Notes
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.deepRose)
                TextEditor(text: $vm.notes)
                    .frame(minHeight: 80)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textPrimary)
                    .scrollContentBackground(.hidden)
            }
            .themedCard()
            .padding(.horizontal, 20)
            
            // Mood
            VStack(alignment: .leading, spacing: 10) {
                Text("How are you feeling?")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.deepRose)
                MoodPicker(selectedMood: $vm.moodScore)
            }
            .themedCard()
            .padding(.horizontal, 20)
            
            // Save
            Button("Save Entry") { vm.saveManualLog() }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(vm.manualEndDate <= vm.manualStartDate)
                .padding(.horizontal, 20)
        }
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }
    
    private var categoryPickerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Category")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.deepRose)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(vm.categories) { cat in
                        CategoryChip(
                            category: cat,
                            isSelected: vm.selectedCategory?.id == cat.id
                        ) {
                            vm.selectedCategory = vm.selectedCategory?.id == cat.id ? nil : cat
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .themedCard()
        .padding(.horizontal, 20)
    }
    
    // MARK: - Previous Logs Section
    
    private var previousLogsSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "Previous Logs")
            
            if vm.recentLogs.isEmpty {
                EmptyStateView(
                    title: "No logs yet",
                    message: "Your logged activities will appear here.",
                    systemImage: "list.bullet.clipboard"
                )
                .padding(.horizontal, 20)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(vm.recentLogs.prefix(20)) { log in
                        LogEntryCard(log: log, category: vm.category(for: log))
                            .padding(.horizontal, 20)
                            .contextMenu {
                                Button(action: { selectedLog = log }) {
                                    Label("Edit", systemImage: "pencil")
                                }
                                Button(action: { vm.duplicateLog(log) }) {
                                    Label("Duplicate", systemImage: "doc.on.doc")
                                }
                                Button(role: .destructive, action: { vm.deleteLog(log) }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { vm.deleteLog(log) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button { selectedLog = log } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(AppTheme.mutedRose)
                            }
                            .swipeActions(edge: .leading) {
                                Button { vm.duplicateLog(log) } label: {
                                    Label("Duplicate", systemImage: "doc.on.doc")
                                }
                                .tint(AppTheme.sage)
                            }
                    }
                }
            }
        }
    }
}

// MARK: - Date Picker Row

struct DatePickerRow: View {
    let label: String
    @Binding var date: Date
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.deepRose)
                .frame(width: 40, alignment: .leading)
            Spacer()
            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
                .tint(AppTheme.deepRose)
        }
    }
}

// MARK: - Save Timer Sheet

struct SaveTimerSheet: View {
    @ObservedObject var vm: LogTimeViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Timer summary
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(AppTheme.sage)
                        Text("Session Complete")
                            .font(.playfairBold(22))
                            .foregroundColor(AppTheme.deepRose)
                        Text(vm.formattedElapsed)
                            .font(.system(size: 32, weight: .ultraLight, design: .monospaced))
                            .foregroundColor(AppTheme.mutedRose)
                    }
                    .padding(.top, 24)
                    
                    // Category
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Category")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.deepRose)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(vm.categories) { cat in
                                    CategoryChip(
                                        category: cat,
                                        isSelected: vm.selectedCategory?.id == cat.id
                                    ) {
                                        vm.selectedCategory = vm.selectedCategory?.id == cat.id ? nil : cat
                                    }
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                    }
                    .themedCard()
                    .padding(.horizontal, 20)
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (optional)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.deepRose)
                        TextField("What were you working on?", text: $vm.notes, axis: .vertical)
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    .themedCard()
                    .padding(.horizontal, 20)
                    
                    // Mood
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How did that feel?")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.deepRose)
                        MoodPicker(selectedMood: $vm.moodScore)
                    }
                    .themedCard()
                    .padding(.horizontal, 20)
                    
                    // Save / Discard
                    VStack(spacing: 12) {
                        Button("Save Session") { vm.saveTimerLog() }
                            .buttonStyle(PrimaryButtonStyle())
                        Button("Discard") {
                            vm.resetTimer()
                            dismiss()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(AppTheme.cream)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled()
        }
    }
}

// MARK: - Log Time Sheet (quick add from FAB)

struct LogTimeSheet: View {
    let initialMode: LogTimeViewModel.EntryMode
    @StateObject private var vm = LogTimeViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if initialMode == .timer {
                        LogTimeView()
                    } else {
                        // Manual entry embedded
                        VStack(spacing: 20) {
                            DatePickerRow(label: "Start", date: $vm.manualStartDate)
                                .themedCard()
                            DatePickerRow(label: "End", date: $vm.manualEndDate)
                                .themedCard()
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(vm.categories) { cat in
                                        CategoryChip(
                                            category: cat,
                                            isSelected: vm.selectedCategory?.id == cat.id
                                        ) { vm.selectedCategory = cat }
                                    }
                                }
                            }
                            .themedCard()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppTheme.deepRose)
                                TextField("Optional notes...", text: $vm.notes)
                                    .font(.system(size: 14))
                            }
                            .themedCard()
                            
                            MoodPicker(selectedMood: $vm.moodScore)
                                .themedCard()
                            
                            Button("Save") {
                                vm.saveManualLog()
                                dismiss()
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .background(AppTheme.cream)
            .navigationTitle(initialMode == .timer ? "Start Timer" : "Add Past Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.deepRose)
                }
            }
        }
        .onAppear { vm.refreshLogs() }
        .task { vm.load(context: modelContext) }
    }
}

// MARK: - Edit Log Sheet

struct EditLogSheet: View {
    let log: TimeLog
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var catVM = CategoriesViewModel()
    
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var notes: String
    @State private var moodScore: Int
    @State private var selectedCategoryID: UUID?
    
    init(log: TimeLog) {
        self.log = log
        _startDate        = State(initialValue: log.startDate)
        _endDate          = State(initialValue: log.endDate)
        _notes            = State(initialValue: log.notes)
        _moodScore        = State(initialValue: log.moodScore)
        _selectedCategoryID = State(initialValue: log.categoryID)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    DatePickerRow(label: "Start", date: $startDate)
                        .themedCard()
                        .padding(.horizontal, 20)
                    
                    DatePickerRow(label: "End", date: $endDate)
                        .themedCard()
                        .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Category")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.deepRose)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(catVM.categories) { cat in
                                    CategoryChip(
                                        category: cat,
                                        isSelected: selectedCategoryID == cat.id
                                    ) { selectedCategoryID = cat.id }
                                }
                            }
                        }
                    }
                    .themedCard()
                    .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.deepRose)
                        TextField("Optional notes...", text: $notes, axis: .vertical)
                            .font(.system(size: 14))
                    }
                    .themedCard()
                    .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Mood")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.deepRose)
                        MoodPicker(selectedMood: $moodScore)
                    }
                    .themedCard()
                    .padding(.horizontal, 20)
                    
                    Button("Save Changes") { saveChanges() }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
                .padding(.top, 16)
            }
            .background(AppTheme.cream)
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.mutedRose)
                }
            }
        }
        .onAppear { catVM.load(context: modelContext) }
    }
    
    private func saveChanges() {
        log.startDate  = startDate
        log.endDate    = endDate
        log.categoryID = selectedCategoryID
        log.notes      = notes
        log.moodScore  = moodScore
        log.recalculateDuration()
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Duplicate Picker Sheet

struct DuplicatePickerSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = LogTimeViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 10) {
                    if vm.recentLogs.isEmpty {
                        EmptyStateView(
                            title: "No logs yet",
                            message: "Log some activities first.",
                            systemImage: "clock"
                        )
                    } else {
                        ForEach(vm.recentLogs.prefix(20)) { log in
                            Button(action: {
                                vm.duplicateLog(log)
                                dismiss()
                            }) {
                                LogEntryCard(log: log, category: vm.category(for: log))
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.top, 16)
            }
            .background(AppTheme.cream)
            .navigationTitle("Duplicate Previous")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.mutedRose)
                }
            }
        }
        .onAppear { vm.load(context: modelContext) }
    }
}

#Preview {
    LogTimeView()
        .modelContainer(PreviewData.container)
}
