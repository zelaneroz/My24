import SwiftUI

// MARK: - Color Hex Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0
        
        let length = hexSanitized.count
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }
        
        self.init(red: r, green: g, blue: b, opacity: a)
    }
    
    var hexString: String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
    
    /// Returns whether the color is considered "light" (for text contrast)
    var isLight: Bool {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: nil)
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return luminance > 0.5
    }
}

// MARK: - Date Extensions

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
    
    var startOfWeek: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return cal.date(from: comps)!
    }
    
    var startOfMonth: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: self)
        return cal.date(from: comps)!
    }
    
    var startOfYear: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year], from: self)
        return cal.date(from: comps)!
    }
    
    func formatted(as format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    var timeString: String {
        formatted(as: "h:mm a")
    }
    
    var shortDateString: String {
        formatted(as: "MMM d")
    }
    
    var dayString: String {
        formatted(as: "EEEE")
    }
    
    var monthYearString: String {
        formatted(as: "MMMM yyyy")
    }
    
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
}

// MARK: - TimeInterval Extensions

extension TimeInterval {
    var hours: Double { self / 3600 }
    var minutes: Double { (self / 60).truncatingRemainder(dividingBy: 60) }
    
    var formattedDuration: String {
        let totalMinutes = Int(self / 60)
        let hrs = totalMinutes / 60
        let mins = totalMinutes % 60
        
        if hrs == 0 {
            return "\(mins)m"
        } else if mins == 0 {
            return "\(hrs)h"
        } else {
            return "\(hrs)h \(mins)m"
        }
    }
    
    var formattedLong: String {
        let totalMinutes = Int(self / 60)
        let hrs = totalMinutes / 60
        let mins = totalMinutes % 60
        
        if hrs == 0 {
            return "\(mins) min"
        } else if mins == 0 {
            return "\(hrs) hr"
        } else {
            return "\(hrs) hr \(mins) min"
        }
    }
    
    var decimalHours: Double {
        self / 3600
    }
}

// MARK: - View Extensions

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - String Extensions

extension String {
    var isNotEmpty: Bool { !isEmpty }
}
