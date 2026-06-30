import SwiftUI
import SwiftData
import Charts
import Foundation
import Combine

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var vm = DashboardViewModel()
    @State private var showFAB = false
    @State private var showLogSheet = false
    @State private var showManualEntry = false
    @State private var showDuplicateSheet = false
    @State private var selectedLog: TimeLog? = nil
    @State private var selectedPieSlice: PieSlice? = nil
    @State private var showSliceDetail = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    LazyVStack(spacing: 24) {
                        DashboardHeader(subtitle: headerSubtitle)
                            .padding(.top, 4)
                        
                        // Summary Cards
                        summarySection
                        
                        // Chart Period Picker
                        chartPeriodPicker
                        
                        // Bar Chart
                        barChartSection
                        
                        // Pie Chart
                        pieChartSection
                        
                        // Recent Logs
                        recentLogsSection
                        
                        Spacer(minLength: 100)
                    }
                }
                .background(AppTheme.cream)
                .scrollIndicators(.hidden)
                
                // FAB
                FloatingAddButton(
                    isExpanded: $showFAB,
                    onStartTimer: { showLogSheet = true },
                    onAddPast: { showManualEntry = true },
                    onDuplicate: { showDuplicateSheet = true }
                )
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showLogSheet) {
                LogTimeSheet(initialMode: .timer)
                    .onDisappear { vm.refresh() }
            }
            .sheet(isPresented: $showManualEntry) {
                LogTimeSheet(initialMode: .manual)
                    .onDisappear { vm.refresh() }
            }
            .sheet(isPresented: $showDuplicateSheet) {
                DuplicatePickerSheet()
                    .onDisappear { vm.refresh() }
            }
            .sheet(item: $selectedLog) { log in
                LogDetailSheet(log: log, category: vm.category(for: log))
                    .onDisappear { vm.refresh() }
            }
        }
        .onAppear { vm.load(context: modelContext) }
    }
    
    // MARK: - Subviews
    
    private var headerSubtitle: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMMM d"
        return fmt.string(from: Date())
    }
    
    private var summarySection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "Today's Summary")
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                SummaryStatCard(
                    label: "Hours Tracked",
                    value: String(format: "%.1fh", vm.trackedHoursToday),
                    icon: "checkmark.circle.fill",
                    accent: AppTheme.sage
                )
                SummaryStatCard(
                    label: "Hours Remaining",
                    value: String(format: "%.1fh", vm.untrackedHoursToday),
                    icon: "clock.fill",
                    accent: AppTheme.blushPink
                )
                SummaryStatCard(
                    label: "Top Category",
                    value: vm.mostUsedCategory?.name ?? "—",
                    icon: vm.mostUsedCategory?.iconName ?? "star.fill",
                    accent: vm.mostUsedCategory?.color ?? AppTheme.lavender
                )
                SummaryStatCard(
                    label: "Longest Session",
                    value: vm.longestSession > 0 ? vm.longestSession.formattedDuration : "—",
                    icon: "timer",
                    accent: AppTheme.goldCat
                )
            }
            .padding(.horizontal, 20)
            
            if vm.todayLogs.count > 0 {
                SummaryStatCard(
                    label: "Average Session",
                    value: vm.averageSessionLength.formattedDuration,
                    icon: "chart.bar.fill",
                    accent: AppTheme.lavender,
                    isWide: true
                )
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var chartPeriodPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(DashboardViewModel.ChartPeriod.allCases, id: \.rawValue) { period in
                    Button(period.rawValue) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            vm.selectedPeriod = period
                            vm.computeChartData()
                        }
                    }
                    .font(.system(size: 14, weight: vm.selectedPeriod == period ? .semibold : .regular))
                    .foregroundColor(vm.selectedPeriod == period ? .white : AppTheme.mutedRose)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(vm.selectedPeriod == period ? AppTheme.deepRose : AppTheme.blushMid)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var barChartSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "Time Distribution")
            
            ChartCard(title: "Hours by \(vm.selectedPeriod.rawValue)", subtitle: "Tap a bar for details") {
                if vm.barChartData.isEmpty || vm.barChartData.allSatisfy({ $0.value == 0 }) {
                    EmptyStateView(
                        title: "No data yet",
                        message: "Start logging time to see your chart.",
                        systemImage: "chart.bar"
                    )
                } else {
                    Chart(vm.barChartData) { point in
                        BarMark(
                            x: .value("Label", point.label),
                            y: .value("Hours", point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.blushPink, AppTheme.softRose],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .cornerRadius(6)
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(AppTheme.blushBorder)
                            AxisValueLabel {
                                if let h = value.as(Double.self) {
                                    Text(String(format: "%.0fh", h))
                                        .font(.system(size: 10))
                                        .foregroundColor(AppTheme.mutedRose)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let label = value.as(String.self) {
                                    Text(label)
                                        .font(.system(size: 10))
                                        .foregroundColor(AppTheme.mutedRose)
                                }
                            }
                        }
                    }
                    .frame(height: 180)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var pieChartSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "Category Breakdown")
            
            ChartCard(title: "By Category", subtitle: "Tap a slice to see details") {
                if vm.pieChartData.isEmpty {
                    EmptyStateView(
                        title: "No categories yet",
                        message: "Log some time to see your breakdown.",
                        systemImage: "chart.pie"
                    )
                } else {
                    HStack(alignment: .top, spacing: 20) {
                        Chart(vm.pieChartData) { slice in
                            SectorMark(
                                angle: .value("Hours", slice.value),
                                innerRadius: .ratio(0.55),
                                angularInset: 2
                            )
                            .foregroundStyle(slice.color)
                            .opacity(selectedPieSlice?.id == slice.id ? 0.7 : 1.0)
                        }
                        .frame(width: 140, height: 140)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(vm.pieChartData.prefix(6)) { slice in
                                Button(action: {
                                    selectedPieSlice = slice
                                    showSliceDetail = true
                                }) {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(slice.color)
                                            .frame(width: 10, height: 10)
                                        Text(slice.label)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(AppTheme.deepRose)
                                        Spacer()
                                        Text("\(Int(slice.percentage * 100))%")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(AppTheme.mutedRose)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $showSliceDetail) {
            if let slice = selectedPieSlice {
                PieSliceDetailSheet(slice: slice, period: vm.selectedPeriod, vm: vm)
            }
        }
    }
    
    private var recentLogsSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "Today's Logs")
            
            if vm.todayLogs.isEmpty {
                EmptyStateView(
                    title: "Nothing logged yet",
                    message: "Tap the + button to log your first activity.",
                    systemImage: "clock.badge.plus"
                )
                .padding(.horizontal, 20)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(vm.todayLogs) { log in
                        LogEntryCard(log: log, category: vm.category(for: log))
                            .padding(.horizontal, 20)
                            .onTapGesture { selectedLog = log }
                            .transition(.opacity)
                    }
                }
            }
        }
    }
}

// MARK: - Pie Slice Detail Sheet

struct PieSliceDetailSheet: View {
    let slice: PieSlice
    let period: DashboardViewModel.ChartPeriod
    @ObservedObject var vm: DashboardViewModel
    @Environment(\.dismiss) private var dismiss
    
    private var cat: Category? {
        vm.categories.first { $0.name == slice.label }
    }
    
    private var logs: [TimeLog] {
        guard let id = cat?.id else { return [] }
        return vm.logsForCategory(id, in: period)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Category header
                    VStack(spacing: 12) {
                        if let cat {
                            ZStack {
                                Circle()
                                    .fill(cat.color.opacity(0.2))
                                    .frame(width: 64, height: 64)
                                Image(systemName: cat.iconName)
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(cat.color)
                            }
                        }
                        
                        Text(slice.label)
                            .font(.playfairBold(24))
                            .foregroundColor(AppTheme.deepRose)
                        
                        HStack(spacing: 24) {
                            VStack(spacing: 2) {
                                Text(String(format: "%.1fh", slice.value))
                                    .font(.playfairBold(20))
                                    .foregroundColor(AppTheme.deepRose)
                                Text("Total")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.mutedRose)
                            }
                            VStack(spacing: 2) {
                                Text("\(Int(slice.percentage * 100))%")
                                    .font(.playfairBold(20))
                                    .foregroundColor(AppTheme.deepRose)
                                Text("of \(period.rawValue)")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.mutedRose)
                            }
                        }
                    }
                    .padding(.vertical, 24)
                    
                    Divider().padding(.horizontal, 20)
                    
                    SectionHeader(title: "Sessions")
                        .padding(.top, 8)
                    
                    ForEach(logs) { log in
                        LogEntryCard(log: log, category: cat)
                            .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .background(AppTheme.cream)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.deepRose)
                }
            }
        }
    }
}

// MARK: - Log Detail Sheet

struct LogDetailSheet: View {
    let log: TimeLog
    let category: Category?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Category icon
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill((category?.color ?? AppTheme.blushPink).opacity(0.2))
                                .frame(width: 72, height: 72)
                            Image(systemName: category?.iconName ?? "clock.fill")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(category?.color ?? AppTheme.blushPink)
                        }
                        .padding(.top, 20)
                        
                        Text(category?.name ?? "Uncategorized")
                            .font(.playfairBold(24))
                            .foregroundColor(AppTheme.deepRose)
                        
                        Text(log.duration.formattedLong)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.mutedRose)
                    }
                    
                    // Details
                    VStack(spacing: 12) {
                        DetailRow(icon: "calendar", label: "Date", value: log.startDate.shortDateString)
                        DetailRow(icon: "clock", label: "Start", value: log.startDate.timeString)
                        DetailRow(icon: "clock.badge.checkmark", label: "End", value: log.endDate.timeString)
                        if let mood = Mood(rawValue: log.moodScore) {
                            DetailRow(icon: "face.smiling", label: "Mood", value: "\(mood.emoji) \(mood.label)")
                        }
                        if log.notes.isNotEmpty {
                            DetailRow(icon: "text.alignleft", label: "Notes", value: log.notes)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button("Edit Entry") { showEditSheet = true }
                            .buttonStyle(PrimaryButtonStyle())
                        Button("Delete Entry") { showDeleteAlert = true }
                            .buttonStyle(SecondaryButtonStyle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(AppTheme.cream)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.deepRose)
                }
            }
            .sheet(isPresented: $showEditSheet) {
                EditLogSheet(log: log)
                    .onDisappear { dismiss() }
            }
            .alert("Delete Entry", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(log)
                    try? modelContext.save()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.blushPink)
                .frame(width: 24)
            
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.mutedRose)
                .frame(width: 60, alignment: .leading)
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.deepRose)
            
            Spacer()
        }
        .padding(12)
        .background(AppTheme.blushLight)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    DashboardView()
        .modelContainer(PreviewData.container)
}
