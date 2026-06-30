import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
final class CategoriesViewModel: ObservableObject {
    @Published var categories: [Category] = []
    var modelContext: ModelContext?
    
    func load(context: ModelContext) {
        self.modelContext = context
        refresh()
    }
    
    func refresh() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortOrder)])
        categories = (try? context.fetch(descriptor)) ?? []
    }
    
    func addCategory(name: String, colorHex: String, iconName: String) {
        guard let context = modelContext else { return }
        let order = categories.count
        let cat = Category(name: name, colorHex: colorHex, iconName: iconName, sortOrder: order)
        context.insert(cat)
        try? context.save()
        refresh()
    }
    
    func updateCategory(_ cat: Category, name: String, colorHex: String, iconName: String) {
        let oldName = cat.name
        cat.name     = name
        cat.colorHex = colorHex
        cat.iconName = iconName

        // Update denormalized names in Goals and Streaks
        if oldName != name, let context = modelContext {
            let goalDesc = FetchDescriptor<Goal>()
            if let goals = try? context.fetch(goalDesc) {
                for goal in goals where goal.categoryID == cat.id {
                    goal.categoryName = name
                }
            }
            let streakDesc = FetchDescriptor<Streak>()
            if let streaks = try? context.fetch(streakDesc) {
                for streak in streaks where streak.categoryID == cat.id {
                    streak.categoryName = name
                }
            }
        }

        try? modelContext?.save()
        refresh()
    }
    
    func deleteCategory(_ cat: Category, context: ModelContext) {
        // Nil out the categoryID on all logs that referenced this category
        let descriptor = FetchDescriptor<TimeLog>()
        if let logs = try? context.fetch(descriptor) {
            for log in logs where log.categoryID == cat.id {
                log.categoryID = nil
            }
        }

        // Also clean up goals and streaks
        let goalDesc = FetchDescriptor<Goal>()
        if let goals = try? context.fetch(goalDesc) {
            for goal in goals where goal.categoryID == cat.id {
                context.delete(goal)
            }
        }

        let streakDesc = FetchDescriptor<Streak>()
        if let streaks = try? context.fetch(streakDesc) {
            for streak in streaks where streak.categoryID == cat.id {
                context.delete(streak)
            }
        }

        context.delete(cat)
        try? context.save()
        refresh()
    }
    
    func move(from source: IndexSet, to destination: Int) {
        categories.move(fromOffsets: source, toOffset: destination)
        for (i, cat) in categories.enumerated() { cat.sortOrder = i }
        try? modelContext?.save()
    }
    
    func logCount(for cat: Category) -> Int {
        guard let context = modelContext else { return 0 }
        let descriptor = FetchDescriptor<TimeLog>()
        let logs = (try? context.fetch(descriptor)) ?? []
        return logs.filter { $0.categoryID == cat.id }.count
    }
}
