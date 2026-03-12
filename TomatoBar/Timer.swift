import KeyboardShortcuts
import SwiftState
import SwiftUI

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

    private var stateMachine = TBStateMachine(state: .idle)
    public let player = TBPlayer()
    private var consecutiveWorkIntervals: Int = 0
    private var notificationCenter = TBNotificationCenter()
    private var finishTime: Date!
    private var timerFormatter = DateComponentsFormatter()
    private var autoStartTimer: Timer?
    private var lastAutoStartDate: Date?
    @Published var timeLeftString: String = ""
    @Published var timer: DispatchSourceTimer?

    /// Converts minutes-since-midnight to/from a Date for
    /// DatePicker binding in the settings UI.
    var autoStartTime: Date {
        get {
            let hour = autoStartMinutesSinceMidnight / 60
            let minute = autoStartMinutesSinceMidnight % 60
            return Calendar.current.date(
                from: DateComponents(hour: hour, minute: minute)
            ) ?? Date()
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            autoStartMinutesSinceMidnight = (components.hour ?? 9) * 60 + (components.minute ?? 0)
        }
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
        stateMachine.addAnyHandler(.work => .any, order: 1, handler: onWorkEnd)
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

        setupAutoStartScheduler()
    }

    @objc func handleGetURLEvent(_ event: NSAppleEventDescriptor,
                                 withReplyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.forKeyword(AEKeyword(keyDirectObject))?.stringValue else {
            print("url handling error: cannot get url")
            return
        }
        let url = URL(string: urlString)
        guard url != nil,
              let scheme = url!.scheme,
              let host = url!.host else {
            print("url handling error: cannot parse url")
            return
        }
        guard scheme.caseInsensitiveCompare("tomatobar") == .orderedSame else {
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
        player.playWindup()
        player.startTicking()
        startTimer(seconds: workIntervalLength * 60)
    }

    private func onWorkFinish(context _: TBStateMachine.Context) {
        consecutiveWorkIntervals += 1
        player.playDing()
    }

    private func onWorkEnd(context _: TBStateMachine.Context) {
        player.stopTicking()
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
    /// whether to auto-start a session on weekday mornings.
    private func setupAutoStartScheduler() {
        autoStartTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.checkAutoStart()
        }
    }

    /// Starts a work session if: auto-start is enabled, the timer is
    /// idle, it's a weekday, the scheduled time has been reached, and
    /// auto-start hasn't already fired today.
    private func checkAutoStart() {
        guard autoStartEnabled else { return }
        guard stateMachine.state == .idle else { return }

        let now = Date()
        let calendar = Calendar.current
        // weekday: 1 = Sunday … 7 = Saturday; bit 0 = Sunday … bit 6 = Saturday
        let weekday = calendar.component(.weekday, from: now)
        let dayBit = 1 << (weekday - 1)
        guard autoStartDays & dayBit != 0 else { return }

        if let last = lastAutoStartDate, calendar.isDate(last, inSameDayAs: now) {
            return
        }

        let currentMinutes = calendar.component(.hour, from: now) * 60
            + calendar.component(.minute, from: now)
        if currentMinutes >= autoStartMinutesSinceMidnight {
            lastAutoStartDate = now
            startStop()
        }
    }
}
