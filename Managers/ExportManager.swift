import Foundation
import UIKit
import PDFKit
import SwiftUI

// MARK: - CSV Exporter

final class CSVExporter {
    
    static func export(logs: [TimeLog], categories: [Category]) -> URL? {
        var rows: [String] = ["Date,Start,End,Duration,Category,Notes,Mood"]
        
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"
        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "HH:mm:ss"
        
        for log in logs.sorted(by: { $0.startDate < $1.startDate }) {
            let cat = categories.first { $0.id == log.categoryID }?.name ?? ""
            let row = [
                dateFmt.string(from: log.startDate),
                timeFmt.string(from: log.startDate),
                timeFmt.string(from: log.endDate),
                log.duration.formattedDuration,
                cat,
                log.notes.replacingOccurrences(of: ",", with: ";"),
                Mood(rawValue: log.moodScore)?.emoji ?? ""
            ].joined(separator: ",")
            rows.append(row)
        }
        
        let csv = rows.joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("My24_Export_\(Date().formatted(as: "yyyyMMdd")).csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}

// MARK: - PDF Exporter

final class PDFExporter {
    
    static func export(
        logs: [TimeLog],
        categories: [Category],
        goals: [Goal],
        streaks: [Streak],
        lifetimeStats: InsightsViewModel.LifetimeStats,
        dateRange: String
    ) -> URL? {
        let pdfMeta = [
            kCGPDFContextTitle: "My24 Report",
            kCGPDFContextAuthor: "My24 App"
        ] as CFDictionary
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("My24_Report_\(Date().formatted(as: "yyyyMMdd")).pdf")
        
        UIGraphicsBeginPDFContextToFile(url.path, pageRect, pdfMeta as? [AnyHashable: Any])
        
        // Page 1 — Cover
        UIGraphicsBeginPDFPage()
        drawCoverPage(in: pageRect, dateRange: dateRange)
        
        // Page 2 — Stats
        UIGraphicsBeginPDFPage()
        drawStatsPage(in: pageRect, stats: lifetimeStats, logs: logs, categories: categories)
        
        UIGraphicsEndPDFContext()
        
        return url
    }
    
    private static func drawCoverPage(in rect: CGRect, dateRange: String) {
        // Background
        let bg = UIColor(AppTheme.cream)
        bg.setFill()
        UIRectFill(rect)
        
        // Title
        let titleAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 40, weight: .bold),
            .foregroundColor: UIColor(AppTheme.deepRose)
        ]
        let title = NSAttributedString(string: "My24", attributes: titleAttr)
        title.draw(at: CGPoint(x: 60, y: 120))
        
        let taglineAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .light),
            .foregroundColor: UIColor(AppTheme.mutedRose)
        ]
        let tagline = NSAttributedString(string: "Track your day. Understand your life.", attributes: taglineAttr)
        tagline.draw(at: CGPoint(x: 60, y: 175))
        
        // Date range
        let rangeAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor(AppTheme.softRose)
        ]
        let range = NSAttributedString(string: "Report Period: \(dateRange)", attributes: rangeAttr)
        range.draw(at: CGPoint(x: 60, y: 230))
        
        // Orchid placeholder
        let orchidAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 60),
        ]
        NSAttributedString(string: "🌸", attributes: orchidAttr).draw(at: CGPoint(x: 60, y: 280))
    }
    
    private static func drawStatsPage(
        in rect: CGRect,
        stats: InsightsViewModel.LifetimeStats,
        logs: [TimeLog],
        categories: [Category]
    ) {
        let bg = UIColor(AppTheme.blushLight)
        bg.setFill()
        UIRectFill(rect)
        
        let headAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .semibold),
            .foregroundColor: UIColor(AppTheme.deepRose)
        ]
        NSAttributedString(string: "Lifetime Statistics", attributes: headAttr).draw(at: CGPoint(x: 60, y: 60))
        
        let bodyAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor(AppTheme.textPrimary)
        ]
        
        let lines: [String] = [
            "Total Tracked Hours: \(String(format: "%.1f", stats.totalHours))h",
            "Total Tracked Days: \(stats.totalDays)",
            "Total Logs: \(stats.totalLogs)",
            "Average Hours/Day: \(String(format: "%.1f", stats.averageHoursPerDay))h",
            "Most Used Category: \(stats.mostUsedCategory)",
            "Longest Streak: \(stats.longestStreak) days",
            "Most Productive Day: \(stats.mostProductiveDay)",
            "Most Productive Month: \(stats.mostProductiveMonth)"
        ]
        
        for (i, line) in lines.enumerated() {
            NSAttributedString(string: line, attributes: bodyAttr)
                .draw(at: CGPoint(x: 60, y: 110 + CGFloat(i * 28)))
        }
        
        // Category breakdown
        NSAttributedString(string: "Category Breakdown", attributes: headAttr)
            .draw(at: CGPoint(x: 60, y: 360))
        
        for (i, cat) in stats.categoryTotals.prefix(8).enumerated() {
            let text = "\(cat.name): \(String(format: "%.1f", cat.hours))h"
            NSAttributedString(string: text, attributes: bodyAttr)
                .draw(at: CGPoint(x: 60, y: 400 + CGFloat(i * 28)))
        }
    }
}
