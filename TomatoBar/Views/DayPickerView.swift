//
//  DayPickerView.swift
//  TomatoBar
//
//  Created by Pierre Oosthuizen on 2026/04/24.
//

import SwiftUI


/// A row of 7 single-letter day-toggle buttons ordered by the locale's first weekday.
///
/// Bit 0 (Sunday) through bit 6 (Saturday) in `days` represent selected days.
/// Used for both the auto-start and auto-stop schedule day pickers.
///
/// - Parameter days: Bitmask binding where each bit represents a day of the week.
private struct DayPickerView: View {
    @Binding var days: Int
    private let calendar: Calendar
    // Symbols computed once from the injected calendar (index 0 = Sunday)
    private let symbols: [String]

    init(days: Binding<Int>, calendar: Calendar = .current) {
        self._days = days
        self.calendar = calendar
        self.symbols = calendar.veryShortWeekdaySymbols
    }

    /// Returns weekday indices (1-based) in the locale's preferred order.
    /// Shifts the 0–6 range so the locale's first weekday appears first.
    private var orderedWeekdays: [Int] {
        let first = calendar.firstWeekday // 1 = Sunday, 2 = Monday, etc.
        return (0 ..< 7).map { (first - 1 + $0) % 7 + 1 }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(orderedWeekdays, id: \.self) { weekday in
                let bit = 1 << (weekday - 1)
                let isOn = days & bit != 0
                Button(symbols[weekday - 1]) {
                    days ^= bit // XOR toggles exactly this day's bit
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .background(isOn ? Color.accentColor.opacity(0.2) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
