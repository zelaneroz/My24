import Foundation
import SwiftData
import SwiftUI

// MARK: - TimeLog Model

@Model
final class TimeLog {
    var id: UUID
    var startDate: Date
    var endDate: Date
    var duration: TimeInterval
    var categoryID: UUID?
    var notes: String
    var moodScore: Int  // 1–5
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date,
        categoryID: UUID? = nil,
        notes: String = "",
        moodScore: Int = 3
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.duration = endDate.timeIntervalSince(startDate)
        self.categoryID = categoryID
        self.notes = notes
        self.moodScore = moodScore
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func recalculateDuration() {
        duration = endDate.timeIntervalSince(startDate)
        updatedAt = Date()
    }
}

// MARK: - Category Model

@Model
final class Category {
    var id: UUID
    var name: String
    var colorHex: String
    var iconName: String
    var sortOrder: Int
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#E8A0B0",
        iconName: String = "circle.fill",
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
    
    var color: Color {
        Color(hex: colorHex) ?? AppTheme.blushPink
    }
    
    var textColor: Color {
        color.isLight ? AppTheme.deepRose : .white
    }
}

// MARK: - Goal Model

@Model
final class Goal {
    var id: UUID
    var categoryID: UUID?
    var categoryName: String  // denormalized for persistence
    var targetHours: Double
    var targetPeriod: String  // "daily", "weekly", "monthly"
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        categoryID: UUID? = nil,
        categoryName: String = "",
        targetHours: Double,
        targetPeriod: String = "weekly"
    ) {
        self.id = id
        self.categoryID = categoryID
        self.categoryName = categoryName
        self.targetHours = targetHours
        self.targetPeriod = targetPeriod
        self.createdAt = Date()
    }
}

// MARK: - Streak Model

@Model
final class Streak {
    var id: UUID
    var streakType: String   // "daily_logging", "category"
    var categoryID: UUID?
    var categoryName: String
    var currentCount: Int
    var longestCount: Int
    var lastUpdated: Date
    
    init(
        id: UUID = UUID(),
        streakType: String,
        categoryID: UUID? = nil,
        categoryName: String = "",
        currentCount: Int = 0,
        longestCount: Int = 0
    ) {
        self.id = id
        self.streakType = streakType
        self.categoryID = categoryID
        self.categoryName = categoryName
        self.currentCount = currentCount
        self.longestCount = longestCount
        self.lastUpdated = Date()
    }
}

// MARK: - Mood Helper

enum Mood: Int, CaseIterable {
    case terrible = 1
    case bad = 2
    case neutral = 3
    case good = 4
    case great = 5
    
    var emoji: String {
        switch self {
        case .terrible: return "😞"
        case .bad:      return "🙁"
        case .neutral:  return "😐"
        case .good:     return "😊"
        case .great:    return "😁"
        }
    }
    
    var label: String {
        switch self {
        case .terrible: return "Terrible"
        case .bad:      return "Bad"
        case .neutral:  return "Neutral"
        case .good:     return "Good"
        case .great:    return "Great"
        }
    }
    
    var color: Color {
        switch self {
        case .terrible: return Color(hex: "#D07070")!
        case .bad:      return Color(hex: "#D09070")!
        case .neutral:  return AppTheme.goldCat
        case .good:     return AppTheme.sage
        case .great:    return Color(hex: "#7DAFD0")!
        }
    }
}

// MARK: - Goal Period Helper

enum GoalPeriod: String, CaseIterable {
    case daily   = "daily"
    case weekly  = "weekly"
    case monthly = "monthly"
    
    var displayName: String {
        switch self {
        case .daily:   return "Daily"
        case .weekly:  return "Weekly"
        case .monthly: return "Monthly"
        }
    }
    
    var label: String {
        switch self {
        case .daily:   return "/day"
        case .weekly:  return "/week"
        case .monthly: return "/month"
        }
    }
}
