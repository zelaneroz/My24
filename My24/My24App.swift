import SwiftUI
import SwiftData
import UserNotifications

@main
struct My24App: App {
    @StateObject private var notificationManager = NotificationManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TimeLog.self,
            Category.self,
            Goal.self,
            Streak.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notificationManager)
                .onAppear {
                    notificationManager.requestPermission()
                    notificationManager.scheduleDailyReminder()
                    insertDefaultCategoriesIfNeeded()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func insertDefaultCategoriesIfNeeded() {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<Category>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }
        
        let defaults: [(String, String, String)] = [
            ("Work", "#A0B8C8", "briefcase.fill"),
            ("Study", "#B8A0C8", "book.fill"),
            ("Research", "#C8A878", "magnifyingglass"),
            ("Reading", "#7DAF8C", "text.book.closed.fill"),
            ("Exercise", "#E8A0B0", "figure.run"),
            ("Sleep", "#B8A0C8", "moon.fill"),
            ("Social", "#C8B0A0", "person.2.fill"),
            ("Miscellaneous", "#A0B8C8", "square.grid.2x2.fill")
        ]
        
        for (name, color, icon) in defaults {
            let cat = Category(name: name, colorHex: color, iconName: icon)
            context.insert(cat)
        }
        try? context.save()
    }
}
