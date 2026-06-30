import SwiftUI
import SwiftData
import Charts

// MARK: - Insights View
import Foundation
import SwiftUI
import SwiftData
import Combine

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var vm = InsightsViewModel()
    @State private var showAddGoal = false
    @State private var showExportSheet = false
    @State private var exportURL: URL? = nil
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    DashboardHeader(subtitle: "Trends & Progress")
                        .padding(.top, 4)
                    
                    // Insights
                    insightsSection
                    
                    // Goals
                    goalsSection
                    
                    // Streaks
                    streaksSection
                    
                    // Lifetime Stats
                    lifetimeStatsSection
                    
                    // Category Totals Chart
                    if !vm.lifetimeStats.categoryTotals.isEmpty {
                        categoryTotalsChart
                    }
                    
                    // Export
                    exportSection
                    
                    Spacer(minLength: 80)
                }
            }
            .background(AppTheme.cream)
            .scrollIndicators(.hidden)
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddGoal) {
                AddGoalSheet(vm: vm)
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(url: url)
                }
            }
        }
        .onAppear { vm.load(context: modelContext) }
    }
    
    // MARK: - Sections
    
    private var insightsSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "Your Insights")
            
            LazyVStack(spacing: 10) {
                ForEach(vm.insights) { insight in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(insight.color.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: insight.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(insight.color)
                        }
                        Text(insight.text)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(AppTheme.deepRose)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .themedCard()
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    private var goalsSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "Goals", action: { showAddGoal = true }, actionLabel: "+ Add")
            
            if vm.goals.isEmpty {
                EmptyStateView(
                    title: "No goals yet",
                    message: "Set goals to track your progress.",
                    systemImage: "target",
                    action: { showAddGoal = true },
                    actionLabel: "Add Goal"
                )
                .padding(.horizontal, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(vm.goals) { goal in
                        GoalProgressCard(
                            goal: goal,
                            category: vm.categoryFor(goal: goal),
                            progress: vm.progress(for: goal),
                            completedHours: vm.completedHours(for: goal)
                        )
                        .padding(.horizontal, 20)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { vm.deleteGoal(goal) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var streaksSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "Streaks")
            
            if vm.streaks.isEmpty {
                Text("Log time daily to start your streak!")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.mutedRose)
                    .padding(.horizontal, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(vm.streaks) { streak in
                        StreakCard(streak: streak)
                            .padding(.horizontal, 20)
                    }
                }
            }
        }
    }
    
    private var lifetimeStatsSection: some View {
        let stats = vm.lifetimeStats
        return VStack(spacing: 8) {
            SectionHeader(title: "Lifetime Statistics")
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                LifetimeStatCard(
                    label: "Total Hours",
                    value: String(format: "%.0f", stats.totalHours),
                    icon: "clock.fill",
                    accent: AppTheme.blushPink
                )
                LifetimeStatCard(
                    label: "Days Tracked",
                    value: "\(stats.totalDays)",
                    icon: "calendar",
                    accent: AppTheme.sage
                )
                LifetimeStatCard(
                    label: "Total Logs",
                    value: "\(stats.totalLogs)",
                    icon: "list.bullet.clipboard",
                    accent: AppTheme.lavender
                )
                LifetimeStatCard(
                    label: "Avg hrs/day",
                    value: String(format: "%.1f", stats.averageHoursPerDay),
                    icon: "chart.bar.fill",
                    accent: AppTheme.goldCat
                )
                LifetimeStatCard(
                    label: "Longest Session",
                    value: stats.longestSession.formattedDuration,
                    icon: "timer",
                    accent: AppTheme.softRose
                )
                LifetimeStatCard(
                    label: "Best Streak",
                    value: "\(stats.longestStreak)d",
                    icon: "flame.fill",
                    accent: AppTheme.blushPink
                )
                LifetimeStatCard(
                    label: "Top Category",
                    value: stats.mostUsedCategory,
                    icon: "star.fill",
                    accent: AppTheme.goldCat
                )
                LifetimeStatCard(
                    label: "Best Day",
                    value: stats.mostProductiveDay,
                    icon: "sun.max.fill",
                    accent: AppTheme.sage
                )
            }
            .padding(.horizontal, 20)
            
            LazyVGrid(columns: [GridItem(.flexible())], spacing: 12) {
                LifetimeStatCard(
                    label: "Most Productive Month",
                    value: stats.mostProductiveMonth,
                    icon: "calendar.badge.clock",
                    accent: AppTheme.lavender
                )
                .padding(.horizontal, 20)
                
                LifetimeStatCard(
                    label: "Average Session Length",
                    value: stats.averageDuration.formattedDuration,
                    icon: "stopwatch",
                    accent: AppTheme.mutedRose
                )
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var categoryTotalsChart: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "All Time by Category")
            
            ChartCard(title: "Category Totals", subtitle: "All tracked time") {
                Chart(vm.lifetimeStats.categoryTotals, id: \.name) { cat in
                    BarMark(
                        x: .value("Hours", cat.hours),
                        y: .value("Category", cat.name)
                    )
                    .foregroundStyle(cat.color)
                    .cornerRadius(6)
                }
                .chartXAxis {
                    AxisMarks { v in
                        AxisValueLabel {
                            if let h = v.as(Double.self) {
                                Text("\(Int(h))h")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.mutedRose)
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(AppTheme.blushBorder)
                    }
                }
                .chartYAxis {
                    AxisMarks { v in
                        AxisValueLabel {
                            if let name = v.as(String.self) {
                                Text(name)
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.deepRose)
                            }
                        }
                    }
                }
                .frame(height: CGFloat(vm.lifetimeStats.categoryTotals.count) * 44)
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var exportSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "Export")
            
            HStack(spacing: 12) {
                Button(action: exportCSV) {
                    Label("Export CSV", systemImage: "tablecells")
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button(action: exportPDF) {
                    Label("Export PDF", systemImage: "doc.text.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Export Actions
    
    private func exportCSV() {
        if let url = CSVExporter.export(logs: vm.allLogs, categories: vm.categories) {
            exportURL = url
            showShareSheet = true
        }
    }
    
    private func exportPDF() {
        let url = PDFExporter.export(
            logs: vm.allLogs,
            categories: vm.categories,
            goals: vm.goals,
            streaks: vm.streaks,
            lifetimeStats: vm.lifetimeStats,
            dateRange: "All Time"
        )
        exportURL = url
        showShareSheet = true
    }
}

// MARK: - Add Goal Sheet

struct AddGoalSheet: View {
    @ObservedObject var vm: InsightsViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: Category? = nil
    @State private var targetHours: Double = 5
    @State private var selectedPeriod: GoalPeriod = .weekly
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Category picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Category")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.deepRose)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(vm.categories) { cat in
                                    CategoryChip(
                                        category: cat,
                                        isSelected: selectedCategory?.id == cat.id
                                    ) { selectedCategory = cat }
                                }
                            }
                        }
                    }
                    .themedCard()
                    .padding(.horizontal, 20)
                    
                    // Target hours
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Target Hours")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.deepRose)
                        
                        HStack {
                            Text(String(format: "%.0f hours", targetHours))
                                .font(.playfairBold(24))
                                .foregroundColor(AppTheme.deepRose)
                            Spacer()
                        }
                        
                        Slider(value: $targetHours, in: 1...80, step: 1)
                            .tint(AppTheme.deepRose)
                    }
                    .themedCard()
                    .padding(.horizontal, 20)
                    
                    // Period picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Period")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.deepRose)
                        
                        HStack(spacing: 12) {
                            ForEach(GoalPeriod.allCases, id: \.rawValue) { period in
                                Button(period.displayName) {
                                    selectedPeriod = period
                                }
                                .font(.system(size: 14, weight: selectedPeriod == period ? .semibold : .regular))
                                .foregroundColor(selectedPeriod == period ? .white : AppTheme.mutedRose)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(selectedPeriod == period ? AppTheme.deepRose : AppTheme.blushMid)
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .themedCard()
                    .padding(.horizontal, 20)
                    
                    Button("Create Goal") {
                        guard let cat = selectedCategory else { return }
                        let goal = Goal(
                            categoryID: cat.id,
                            categoryName: cat.name,
                            targetHours: targetHours,
                            targetPeriod: selectedPeriod.rawValue
                        )
                        vm.addGoal(goal)
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(selectedCategory == nil)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .padding(.top, 16)
            }
            .background(AppTheme.cream)
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.mutedRose)
                }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Categories Management View
struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var vm = CategoriesViewModel()
    @State private var showAddSheet = false
    @State private var editingCategory: Category? = nil
    @State private var categoryToDelete: Category? = nil
    @State private var showDeleteAlert = false

    
    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.categories) { cat in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(cat.color.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: cat.iconName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(cat.color)
                        }
                        Text(cat.name)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppTheme.deepRose)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .swipeActions {
                        Button(role: .destructive) {
                            categoryToDelete = cat
                            showDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button { editingCategory = cat } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(AppTheme.mutedRose)
                    }
                }
                .onMove { vm.move(from: $0, to: $1) }
                .alert("Delete Category", isPresented: $showDeleteAlert) {
                    Button("Delete", role: .destructive) {
                        if let cat = categoryToDelete {
                            vm.deleteCategory(cat, context: modelContext)
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    if let cat = categoryToDelete {
                        let count = vm.logCount(for: cat)
                        if count > 0 {
                            Text("This will remove the category from \(count) past log\(count == 1 ? "" : "s"). The logs themselves won't be deleted.")
                        } else {
                            Text("This cannot be undone.")
                        }
                    }
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { EditButton() }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                    .foregroundColor(AppTheme.deepRose)
                }
            }
            .sheet(isPresented: $showAddSheet) {
                CategoryFormSheet(vm: vm)
            }
            .sheet(item: $editingCategory) { cat in
                CategoryFormSheet(vm: vm, editingCategory: cat)
            }
        }
        .onAppear { vm.load(context: modelContext) }
    }
}

// MARK: - Category Form Sheet

struct CategoryFormSheet: View {
    @ObservedObject var vm: CategoriesViewModel
    var editingCategory: Category? = nil
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var colorHex: String = "#E8A0B0"
    @State private var iconName: String = "circle.fill"
    
    let iconOptions = [
        "briefcase.fill", "book.fill", "magnifyingglass", "text.book.closed.fill",
        "figure.run", "moon.fill", "person.2.fill", "music.note",
        "paintbrush.fill", "fork.knife", "car.fill", "house.fill",
        "gamecontroller.fill", "heart.fill", "star.fill", "flame.fill",
        "bolt.fill", "leaf.fill", "pawprint.fill", "graduationcap.fill"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Preview
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill((Color(hex: colorHex) ?? AppTheme.blushPink).opacity(0.15))
                                .frame(width: 56, height: 56)
                            Image(systemName: iconName)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(Color(hex: colorHex) ?? AppTheme.blushPink)
                        }
                        Text(name.isEmpty ? "Category Name" : name)
                            .font(.playfairBold(20))
                            .foregroundColor(AppTheme.deepRose)
                        Spacer()
                    }
                    .themedCard()
                    .padding(.horizontal, 20)
                    
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.deepRose)
                        TextField("e.g. Deep Work", text: $name)
                            .font(.system(size: 15))
                    }
                    .themedCard()
                    .padding(.horizontal, 20)
                    
                    // Color picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Color")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.deepRose)
                        ColorSwatchPicker(selectedHex: $colorHex)
                    }
                    .themedCard()
                    .padding(.horizontal, 20)
                    
                    // Icon picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Icon")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.deepRose)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(iconOptions, id: \.self) { icon in
                                Button(action: { iconName = icon }) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(iconName == icon ? (Color(hex: colorHex) ?? AppTheme.blushPink).opacity(0.2) : AppTheme.blushMid)
                                            .frame(width: 44, height: 44)
                                        Image(systemName: icon)
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(iconName == icon ? (Color(hex: colorHex) ?? AppTheme.blushPink) : AppTheme.mutedRose)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .themedCard()
                    .padding(.horizontal, 20)
                    
                    Button(editingCategory == nil ? "Create Category" : "Save Changes") {
                        if let cat = editingCategory {
                            vm.updateCategory(cat, name: name, colorHex: colorHex, iconName: iconName)
                        } else {
                            vm.addCategory(name: name, colorHex: colorHex, iconName: iconName)
                        }
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .padding(.top, 16)
            }
            .background(AppTheme.cream)
            .navigationTitle(editingCategory == nil ? "New Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.mutedRose)
                }
            }
        }
        .onAppear {
            if let cat = editingCategory {
                name     = cat.name
                colorHex = cat.colorHex
                iconName = cat.iconName
            }
        }
    }
}

#Preview {
    InsightsView()
        .modelContainer(PreviewData.container)
}
