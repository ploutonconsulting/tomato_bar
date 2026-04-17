import AppKit
@testable import TomatoBar
import Testing
import Foundation

// MARK: - TBScheduleRule Tests

struct ScheduleRuleTests {
    /// Fixed calendar (Monday = day 2) for deterministic tests.
    private static func calendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    /// Builds a Date at the given hour:minute on a specific weekday.
    /// weekday: 1=Sun, 2=Mon, …, 7=Sat (Calendar convention).
    private static func date(weekday: Int, hour: Int, minute: Int) -> Date {
        let cal = calendar()
        // 2026-04-13 is a Monday (weekday 2). Offset to desired weekday.
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 4
        comps.day = 13 + (weekday - 2) // Mon=13, Tue=14, ..., Sun=12
        comps.hour = hour
        comps.minute = minute
        comps.timeZone = TimeZone(secondsFromGMT: 0)
        return cal.date(from: comps)!
    }

    // -- Enabled / disabled --

    /// Disabled rule never fires regardless of matching time and day.
    @Test func disabledRuleNeverFires() {
        let rule = TBScheduleRule(enabled: false, minutesSinceMidnight: 540, daysBitmask: 0b1111111)
        let now = Self.date(weekday: 2, hour: 9, minute: 0) // Mon 09:00
        #expect(!rule.shouldFire(now: now, calendar: Self.calendar()))
    }

    // -- Day matching --

    /// Fires on Monday when Monday bit is set.
    @Test func firesOnMatchingWeekday() {
        let mondayBit = 1 << 1 // bit 1 = Monday
        let rule = TBScheduleRule(enabled: true, minutesSinceMidnight: 540, daysBitmask: mondayBit)
        let now = Self.date(weekday: 2, hour: 9, minute: 0)
        #expect(rule.shouldFire(now: now, calendar: Self.calendar()))
    }

    /// Does not fire on Tuesday when only Monday bit is set.
    @Test func doesNotFireOnWrongWeekday() {
        let mondayBit = 1 << 1
        let rule = TBScheduleRule(enabled: true, minutesSinceMidnight: 540, daysBitmask: mondayBit)
        let now = Self.date(weekday: 3, hour: 9, minute: 0) // Tuesday
        #expect(!rule.shouldFire(now: now, calendar: Self.calendar()))
    }

    /// Fires on Sunday (bit 0) — edge of bitmask.
    @Test func firesOnSunday() {
        let sundayBit = 1 << 0
        let rule = TBScheduleRule(enabled: true, minutesSinceMidnight: 600, daysBitmask: sundayBit)
        let now = Self.date(weekday: 1, hour: 10, minute: 0)
        #expect(rule.shouldFire(now: now, calendar: Self.calendar()))
    }

    /// Fires on Saturday (bit 6) — other edge of bitmask.
    @Test func firesOnSaturday() {
        let saturdayBit = 1 << 6
        let rule = TBScheduleRule(enabled: true, minutesSinceMidnight: 600, daysBitmask: saturdayBit)
        let now = Self.date(weekday: 7, hour: 10, minute: 0)
        #expect(rule.shouldFire(now: now, calendar: Self.calendar()))
    }

    /// Empty bitmask (no days selected) never fires.
    @Test func emptyBitmaskNeverFires() {
        let rule = TBScheduleRule(enabled: true, minutesSinceMidnight: 540, daysBitmask: 0)
        let now = Self.date(weekday: 2, hour: 9, minute: 0)
        #expect(!rule.shouldFire(now: now, calendar: Self.calendar()))
    }

    /// All-days bitmask fires on every weekday.
    @Test func allDaysBitmaskFiresEveryDay() {
        let rule = TBScheduleRule(enabled: true, minutesSinceMidnight: 540, daysBitmask: 0b1111111)
        for weekday in 1...7 {
            let now = Self.date(weekday: weekday, hour: 9, minute: 0)
            #expect(rule.shouldFire(now: now, calendar: Self.calendar()),
                    "Should fire on weekday \(weekday)")
        }
    }

    /// Default Mon–Fri bitmask (0b0111110) fires weekdays, not weekends.
    @Test func monFriBitmask() {
        let rule = TBScheduleRule(enabled: true, minutesSinceMidnight: 540, daysBitmask: 0b0111110)
        // Mon(2)–Fri(6) should fire
        for weekday in 2...6 {
            let now = Self.date(weekday: weekday, hour: 9, minute: 0)
            #expect(rule.shouldFire(now: now, calendar: Self.calendar()),
                    "Should fire on weekday \(weekday)")
        }
        // Sun(1) and Sat(7) should not
        for weekday in [1, 7] {
            let now = Self.date(weekday: weekday, hour: 9, minute: 0)
            #expect(!rule.shouldFire(now: now, calendar: Self.calendar()),
                    "Should not fire on weekday \(weekday)")
        }
    }

    // -- Time matching --

    /// Fires when current time equals scheduled time exactly.
    @Test func firesAtExactTime() {
        let rule = TBScheduleRule(enabled: true, minutesSinceMidnight: 540, daysBitmask: 0b1111111)
        let now = Self.date(weekday: 2, hour: 9, minute: 0) // 540 min
        #expect(rule.shouldFire(now: now, calendar: Self.calendar()))
    }

    /// Fires when current time is after scheduled time (same day).
    @Test func firesAfterScheduledTime() {
        let rule = TBScheduleRule(enabled: true, minutesSinceMidnight: 540, daysBitmask: 0b1111111)
        let now = Self.date(weekday: 2, hour: 10, minute: 30) // 630 min
        #expect(rule.shouldFire(now: now, calendar: Self.calendar()))
    }

    /// Does not fire before scheduled time.
    @Test func doesNotFireBeforeScheduledTime() {
        let rule = TBScheduleRule(enabled: true, minutesSinceMidnight: 540, daysBitmask: 0b1111111)
        let now = Self.date(weekday: 2, hour: 8, minute: 59) // 539 min
        #expect(!rule.shouldFire(now: now, calendar: Self.calendar()))
    }

    /// Midnight schedule (0 minutes) fires at 00:00.
    @Test func midnightSchedule() {
        let rule = TBScheduleRule(enabled: true, minutesSinceMidnight: 0, daysBitmask: 0b1111111)
        let now = Self.date(weekday: 2, hour: 0, minute: 0)
        #expect(rule.shouldFire(now: now, calendar: Self.calendar()))
    }

    /// Late-night schedule (23:59 = 1439 minutes) fires at 23:59.
    @Test func lateNightSchedule() {
        let rule = TBScheduleRule(enabled: true, minutesSinceMidnight: 1439, daysBitmask: 0b1111111)
        let now = Self.date(weekday: 2, hour: 23, minute: 59)
        #expect(rule.shouldFire(now: now, calendar: Self.calendar()))
    }

    /// Late-night schedule does not fire one minute early.
    @Test func lateNightScheduleOneMinuteEarly() {
        let rule = TBScheduleRule(enabled: true, minutesSinceMidnight: 1439, daysBitmask: 0b1111111)
        let now = Self.date(weekday: 2, hour: 23, minute: 58)
        #expect(!rule.shouldFire(now: now, calendar: Self.calendar()))
    }
}

// MARK: - Log Event Encoding Tests

struct LogEventEncodingTests {
    /// AppStart event encodes with correct type field.
    @Test func appStartEventType() throws {
        let event = TBLogEventAppStart()
        let data = try JSONEncoder().encode(event)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(json["type"] as? String == "appstart")
        #expect(json["timestamp"] != nil)
    }

    /// AppStart event timestamp is close to now.
    @Test func appStartTimestamp() throws {
        let before = Date()
        let event = TBLogEventAppStart()
        let after = Date()
        #expect(event.timestamp >= before)
        #expect(event.timestamp <= after)
    }
}

// MARK: - Notification Enum Tests

struct NotificationEnumTests {
    /// Category raw values match what UNNotificationCategory expects.
    @Test func categoryRawValues() {
        #expect(TBNotification.Category.workStarted.rawValue == "workStarted")
        #expect(TBNotification.Category.restStarted.rawValue == "restStarted")
        #expect(TBNotification.Category.restFinished.rawValue == "restFinished")
    }

    /// Action raw value matches UNNotificationAction identifier.
    @Test func actionRawValue() {
        #expect(TBNotification.Action.skipRest.rawValue == "skipRest")
    }
}

// MARK: - System Sound Names Tests

struct SystemSoundTests {
    /// All declared system sounds exist at the expected path.
    @Test func allSystemSoundsExist() {
        for name in systemSoundNames {
            let path = "/System/Library/Sounds/\(name).aiff"
            #expect(FileManager.default.fileExists(atPath: path),
                    "Missing system sound: \(name)")
        }
    }

    /// All declared system sounds load as NSSound instances.
    @Test func allSystemSoundsLoadAsNSSound() {
        for name in systemSoundNames {
            let url = URL(fileURLWithPath: "/System/Library/Sounds/\(name).aiff")
            let sound = NSSound(contentsOf: url, byReference: true)
            #expect(sound != nil, "Failed to load NSSound: \(name)")
        }
    }
}
