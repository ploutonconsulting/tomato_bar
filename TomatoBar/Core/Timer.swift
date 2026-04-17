import KeyboardShortcuts
import SwiftState
import SwiftUI

/// A pure value type that decides whether a scheduled action (auto-start or
/// auto-stop) should fire "now". Kept free of `TBTimer` state so the same
/// rule type can power both schedules and be reasoned about in isolation.
struct TBScheduleRule {
    let enabled: Bool
    /// Scheduled time-of-day expressed as minutes since midnight (0–1439).
    let minutesSinceMidnight: Int
    /// Bitmask of allowed weekdays. Bit 0 = Sunday … bit 6 = Saturday,
    /// matching `Calendar.weekday - 1`.
    let daysBitmask: Int

    /// Returns true when `now` falls on an allowed weekday and the
    /// scheduled time-of-day has been reached. The caller is responsible
    /// for once-per-day deduplication and for any state-based guards
    /// (e.g. "only start if the timer is idle").
    func shouldFire(now: Date, calendar: Calendar = .current) -> Bool {
        guard enabled else { return false }
        let weekday = calendar.component(.weekday, from: now)
        let dayBit = 1 << (weekday - 1)
        guard daysBitmask & dayBit != 0 else { return false }
        let currentMinutes = calendar.component(.hour, from: now) * 60
            + calendar.component(.minute, from: now)
        return currentMinutes >= minutesSinceMidnight
    }
}

class TBTimer: ObservableObject {
    @AppStorage("stopAfterBreak") var stopAfterBreak = false
    @AppStorage("showTimerInMenuBar") var showTimerInMenuBar = true
    @AppStorage("workIntervalLength") var workIntervalLength = 25
    @AppStorage("shortRestIntervalLength") var shortRestIntervalLength = 5
    @AppStorage("longRestIntervalLength") var longRestIntervalLength = 15
    @AppStorage("workIntervalsInSet") var workIntervalsInSet = 4
    // This preference is "hidden"
    @AppStorage("overrunTimeLimit") var overrunTimeLimit = -60.0
    @AppStorage("autoStartEnabled") var autoStartEnabled = false
    // Minutes since midnight, default 540 = 9:00 AM
    @AppStorage("autoStartMinutesSinceMidnight") var autoStartMinutesSinceMidnight = 540
    // Bitmask: bit 0 = Sunday, bit 1 = Monday … bit 6 = Saturday
    // Default 0b0111110 (62) = Mon–Fri
    @AppStorage("autoStartDays") var autoStartDays = 0b0111110
    @AppStorage("autoStopEnabled") var autoStopEnabled = false
    // Minutes since midnight, default 1020 = 5:00 PM
    @AppStorage("autoStopMinutesSinceMidnight") var autoStopMinutesSinceMidnight = 1020
    // Same bitmask layout as autoStartDays. Default Mon–Fri.
    @AppStorage("autoStopDays") var autoStopDays = 0b0111110

    private var stateMachine = TBStateMachine(state: .idle)
    public let player = TBPlayer()
    private var consecutiveWorkIntervals: Int = 0
    @AppStorage("notificationsEnabled") var notificationsEnabled = true {
        didSet { notificationCenter.notificationsEnabled = notificationsEnabled }
    }
    private let notificationCenter = TBNotificationCenter()
    private var finishTime: Date!
    private var timerFormatter = DateComponentsFormatter()
    private var scheduleTimer: Timer?
    private var lastAutoStartDate: Date?
    private var lastAutoStopDate: Date?
    @Published var timeLeftString: String = ""
    @Published var timer: DispatchSourceTimer?

    /// Converts minutes-since-midnight to/from a Date for
    /// DatePicker binding in the settings UI.
    var autoStartTime: Date {
        get { Self.date(fromMinutes: autoStartMinutesSinceMidnight) }
        set { autoStartMinutesSinceMidnight = Self.minutes(from: newValue, defaultHour: 9) }
    }

    /// DatePicker binding for the auto-stop time-of-day.
    var autoStopTime: Date {
        get { Self.date(fromMinutes: autoStopMinutesSinceMidnight) }
        set { autoStopMinutesSinceMidnight = Self.minutes(from: newValue, defaultHour: 17) }
    }

    private var startRule: TBScheduleRule {
        TBScheduleRule(
            enabled: autoStartEnabled,
            minutesSinceMidnight: autoStartMinutesSinceMidnight,
            daysBitmask: autoStartDays
        )
    }

    private var stopRule: TBScheduleRule {
        TBScheduleRule(
            enabled: autoStopEnabled,
            minutesSinceMidnight: autoStopMinutesSinceMidnight,
            daysBitmask: autoStopDays
        )
    }

    /// Shared conversion from minutes-since-midnight to a `Date` whose
    /// hour and minute match. Used by both `autoStartTime` and `autoStopTime`.
    private static func date(fromMinutes minutes: Int) -> Date {
        let hour = minutes / 60
        let minute = minutes % 60
        return Calendar.current.date(
            from: DateComponents(hour: hour, minute: minute)
        ) ?? Date()
    }

    /// Shared conversion from a `Date` to minutes-since-midnight,
    /// substituting `defaultHour` if the Date has no hour component.
    private static func minutes(from date: Date, defaultHour: Int) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? defaultHour) * 60 + (components.minute ?? 0)
    }

    init() {
        /*
         * State diagram
         *
         *                 start/stop
         *       +--------------+-------------+
         *       |              |             |
         *       |  start/stop  |  timerFired |
         *       V    |         |    |        |
         * +--------+ |  +--------+  | +--------+
         * | idle   |--->| work   |--->| rest   |
         * +--------+    +--------+    +--------+
         *   A                  A        |    |
         *   |                  |        |    |
         *   |                  +--------+    |
         *   |  timerFired (!stopAfterBreak)  |
         *   |             skipRest           |
         *   |                                |
         *   +--------------------------------+
         *      timerFired (stopAfterBreak)
         *
         */
        stateMachine.addRoutes(event: .startStop, transitions: [
            .idle => .work, .work => .idle, .rest => .idle,
        ])
        stateMachine.addRoutes(event: .timerFired, transitions: [.work => .rest])
        stateMachine.addRoutes(event: .timerFired, transitions: [.rest => .idle]) { _ in
            self.stopAfterBreak
        }
        stateMachine.addRoutes(event: .timerFired, transitions: [.rest => .work]) { _ in
            !self.stopAfterBreak
        }
        stateMachine.addRoutes(event: .skipRest, transitions: [.rest => .work])

        /*
         * "Finish" handlers are called when time interval ended
         * "End"    handlers are called when time interval ended or was cancelled
         */
        stateMachine.addAnyHandler(.any => .work, handler: onWorkStart)
        stateMachine.addAnyHandler(.work => .rest, order: 0, handler: onWorkFinish)
        stateMachine.addAnyHandler(.any => .rest, handler: onRestStart)
        stateMachine.addAnyHandler(.rest => .work, handler: onRestFinish)
        stateMachine.addAnyHandler(.any => .idle, handler: onIdleStart)
        stateMachine.addAnyHandler(.any => .any, handler: { ctx in
            logger.append(event: TBLogEventTransition(fromContext: ctx))
        })

        stateMachine.addErrorHandler { ctx in fatalError("state machine context: <\(ctx)>") }

        timerFormatter.unitsStyle = .positional
        timerFormatter.allowedUnits = [.minute, .second]
        timerFormatter.zeroFormattingBehavior = .pad

        KeyboardShortcuts.onKeyUp(for: .startStopTimer, action: startStop)
        notificationCenter.setActionHandler(handler: onNotificationAction)

        let aem: NSAppleEventManager = NSAppleEventManager.shared()
        aem.setEventHandler(self,
                            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
                            forEventClass: AEEventClass(kInternetEventClass),
                            andEventID: AEEventID(kAEGetURL))

        setupScheduler()
    }

    @objc func handleGetURLEvent(_ event: NSAppleEventDescriptor,
                                 withReplyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.forKeyword(AEKeyword(keyDirectObject))?.stringValue else {
            print("url handling error: cannot get url")
            return
        }
        guard let url = URL(string: urlString),
              let scheme = url.scheme,
              let host = url.host else {
            print("url handling error: cannot parse url")
            return
        }
        guard scheme.caseInsensitiveCompare("veridian") == .orderedSame else {
            print("url handling error: unknown scheme \(scheme)")
            return
        }
        switch host.lowercased() {
        case "startstop":
            startStop()
        default:
            print("url handling error: unknown command \(host)")
            return
        }
    }

    func startStop() {
        stateMachine <-! .startStop
    }

    func skipRest() {
        stateMachine <-! .skipRest
    }

    func updateTimeLeft() {
        timeLeftString = timerFormatter.string(from: Date(), to: finishTime)!
        if timer != nil, showTimerInMenuBar {
            TBStatusItem.shared.setTitle(title: timeLeftString)
        } else {
            TBStatusItem.shared.setTitle(title: nil)
        }
    }

    private func startTimer(seconds: Int) {
        finishTime = Date().addingTimeInterval(TimeInterval(seconds))

        let queue = DispatchQueue(label: "Timer")
        timer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
        timer!.schedule(deadline: .now(), repeating: .seconds(1), leeway: .never)
        timer!.setEventHandler(handler: onTimerTick)
        timer!.setCancelHandler(handler: onTimerCancel)
        timer!.resume()
    }

    private func stopTimer() {
        timer!.cancel()
        timer = nil
    }

    private func onTimerTick() {
        /* Cannot publish updates from background thread */
        DispatchQueue.main.async { [self] in
            updateTimeLeft()
            let timeLeft = finishTime.timeIntervalSince(Date())
            if timeLeft <= 0 {
                /*
                 Ticks can be missed during the machine sleep.
                 Stop the timer if it goes beyond an overrun time limit.
                 */
                if timeLeft < overrunTimeLimit {
                    stateMachine <-! .startStop
                } else {
                    stateMachine <-! .timerFired
                }
            }
        }
    }

    private func onTimerCancel() {
        DispatchQueue.main.async { [self] in
            updateTimeLeft()
        }
    }

    private func onNotificationAction(action: TBNotification.Action) {
        if action == .skipRest, stateMachine.state == .rest {
            skipRest()
        }
    }

    private func onWorkStart(context _: TBStateMachine.Context) {
        TBStatusItem.shared.setIcon(name: .work)
        player.playStart()
        notificationCenter.send(
            title: NSLocalizedString("TBTimer.onWorkStart.title", comment: "Work started title"),
            body: NSLocalizedString("TBTimer.onWorkStart.body", comment: "Work started body"),
            category: .workStarted
        )
        startTimer(seconds: workIntervalLength * 60)
    }

    private func onWorkFinish(context _: TBStateMachine.Context) {
        consecutiveWorkIntervals += 1
        player.playEnd()
    }

    private func onRestStart(context _: TBStateMachine.Context) {
        var body = NSLocalizedString("TBTimer.onRestStart.short.body", comment: "Short break body")
        var length = shortRestIntervalLength
        var imgName = NSImage.Name.shortRest
        if consecutiveWorkIntervals >= workIntervalsInSet {
            body = NSLocalizedString("TBTimer.onRestStart.long.body", comment: "Long break body")
            length = longRestIntervalLength
            imgName = .longRest
            consecutiveWorkIntervals = 0
        }
        notificationCenter.send(
            title: NSLocalizedString("TBTimer.onRestStart.title", comment: "Time's up title"),
            body: body,
            category: .restStarted
        )
        TBStatusItem.shared.setIcon(name: imgName)
        startTimer(seconds: length * 60)
    }

    private func onRestFinish(context ctx: TBStateMachine.Context) {
        if ctx.event == .skipRest {
            return
        }
        notificationCenter.send(
            title: NSLocalizedString("TBTimer.onRestFinish.title", comment: "Break is over title"),
            body: NSLocalizedString("TBTimer.onRestFinish.body", comment: "Break is over body"),
            category: .restFinished
        )
    }

    private func onIdleStart(context _: TBStateMachine.Context) {
        stopTimer()
        TBStatusItem.shared.setIcon(name: .idle)
        consecutiveWorkIntervals = 0
    }

    /// Configures a repeating timer that checks every 30 seconds
    /// whether to auto-start or auto-stop a session based on the
    /// configured schedule rules.
    private func setupScheduler() {
        scheduleTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.checkSchedule()
        }
    }

    /// Consults `startRule` and `stopRule`. Auto-start and auto-stop
    /// each fire at most once per day.
    private func checkSchedule() {
        let now = Date()
        let calendar = Calendar.current

        // Auto-start: once per day, only while idle.
        if !isSameDayAsNow(lastAutoStartDate, calendar: calendar, now: now),
           stateMachine.state == .idle,
           startRule.shouldFire(now: now, calendar: calendar) {
            lastAutoStartDate = now
            startStop()
        }

        // Auto-stop: once per day. Record the "fired today" flag as soon as
        // the scheduled moment passes, even if nothing was running, so that
        // a later manual start isn't stopped again later the same day.
        if !isSameDayAsNow(lastAutoStopDate, calendar: calendar, now: now),
           stopRule.shouldFire(now: now, calendar: calendar) {
            lastAutoStopDate = now
            if stateMachine.state != .idle {
                startStop()
            }
        }
    }

    private func isSameDayAsNow(_ date: Date?, calendar: Calendar, now: Date) -> Bool {
        guard let date else { return false }
        return calendar.isDate(date, inSameDayAs: now)
    }
}
