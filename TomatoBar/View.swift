import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI

extension KeyboardShortcuts.Name {
    static let startStopTimer = Self("startStopTimer")
}

private struct IntervalsView: View {
    @EnvironmentObject var timer: TBTimer
    private var minStr = NSLocalizedString("IntervalsView.min", comment: "min")

    var body: some View {
        VStack {
            Stepper(value: $timer.workIntervalLength, in: 1 ... 60) {
                HStack {
                    Text(NSLocalizedString("IntervalsView.workIntervalLength.label",
                                           comment: "Work interval label"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(String.localizedStringWithFormat(minStr, timer.workIntervalLength))
                }
            }
            Stepper(value: $timer.shortRestIntervalLength, in: 1 ... 60) {
                HStack {
                    Text(NSLocalizedString("IntervalsView.shortRestIntervalLength.label",
                                           comment: "Short rest interval label"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(String.localizedStringWithFormat(minStr, timer.shortRestIntervalLength))
                }
            }
            Stepper(value: $timer.longRestIntervalLength, in: 1 ... 60) {
                HStack {
                    Text(NSLocalizedString("IntervalsView.longRestIntervalLength.label",
                                           comment: "Long rest interval label"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(String.localizedStringWithFormat(minStr, timer.longRestIntervalLength))
                }
            }
            .help(NSLocalizedString("IntervalsView.longRestIntervalLength.help",
                                    comment: "Long rest interval hint"))
            Stepper(value: $timer.workIntervalsInSet, in: 1 ... 10) {
                HStack {
                    Text(NSLocalizedString("IntervalsView.workIntervalsInSet.label",
                                           comment: "Work intervals in a set label"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(timer.workIntervalsInSet)")
                }
            }
            .help(NSLocalizedString("IntervalsView.workIntervalsInSet.help",
                                    comment: "Work intervals in set hint"))
            Spacer().frame(minHeight: 0)
        }
        .padding(4)
    }
}

/// A row of 7 single-letter day buttons, ordered by locale's first weekday.
/// Each button toggles a bit in the bound `Int` bitmask (bit 0 = Sunday,
/// bit 6 = Saturday). Used for both the auto-start and auto-stop day pickers.
private struct DayPickerView: View {
    @Binding var days: Int

    // Calendar weekday symbols: index 0 = Sunday, ordered Sun–Sat
    private let symbols = Calendar.current.veryShortWeekdaySymbols
    // Locale-ordered weekday indices (1-based, matching Calendar.weekday)
    private var orderedWeekdays: [Int] {
        let first = Calendar.current.firstWeekday // 1 = Sunday, 2 = Monday, etc.
        return (0 ..< 7).map { (first - 1 + $0) % 7 + 1 }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(orderedWeekdays, id: \.self) { weekday in
                let bit = 1 << (weekday - 1)
                let isOn = days & bit != 0
                Button(symbols[weekday - 1]) {
                    days ^= bit
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

private struct SettingsView: View {
    @EnvironmentObject var timer: TBTimer
    var body: some View {
        VStack {
            KeyboardShortcuts.Recorder(for: .startStopTimer) {
                Text(NSLocalizedString("SettingsView.shortcut.label",
                                       comment: "Shortcut label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Toggle(isOn: $timer.stopAfterBreak) {
                Text(NSLocalizedString("SettingsView.stopAfterBreak.label",
                                       comment: "Stop after break label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
            Toggle(isOn: $timer.showTimerInMenuBar) {
                Text(NSLocalizedString("SettingsView.showTimerInMenuBar.label",
                                       comment: "Show timer in menu bar label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
                .onChange(of: timer.showTimerInMenuBar) { _ in
                    timer.updateTimeLeft()
                }
            Toggle(isOn: $timer.notificationsEnabled) {
                Text(NSLocalizedString("SettingsView.notificationsEnabled.label",
                                       comment: "Show notifications label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
            LaunchAtLogin.Toggle {
                Text(NSLocalizedString("SettingsView.launchAtLogin.label",
                                       comment: "Launch at login label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
            Toggle(isOn: $timer.autoStartEnabled) {
                Text(NSLocalizedString("SettingsView.autoStartEnabled.label",
                                       comment: "Auto-start label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
            if timer.autoStartEnabled {
                DayPickerView(days: $timer.autoStartDays)
                DatePicker(
                    NSLocalizedString("SettingsView.autoStartTime.label",
                                      comment: "Auto-start time label"),
                    selection: Binding(
                        get: { timer.autoStartTime },
                        set: { timer.autoStartTime = $0 }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }
            Toggle(isOn: $timer.autoStopEnabled) {
                Text(NSLocalizedString("SettingsView.autoStopEnabled.label",
                                       comment: "Auto-stop label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
            if timer.autoStopEnabled {
                DayPickerView(days: $timer.autoStopDays)
                DatePicker(
                    NSLocalizedString("SettingsView.autoStopTime.label",
                                      comment: "Auto-stop time label"),
                    selection: Binding(
                        get: { timer.autoStopTime },
                        set: { timer.autoStopTime = $0 }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }
            Spacer().frame(minHeight: 0)
        }
        .padding(4)
    }
}

private struct SoundsView: View {
    @EnvironmentObject var player: TBPlayer

    var body: some View {
        VStack {
            Toggle(isOn: $player.startSoundEnabled) {
                Text(NSLocalizedString("SoundsView.startSoundEnabled.label",
                                       comment: "Start sound label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
            if player.startSoundEnabled {
                Picker(NSLocalizedString("SoundsView.startSoundName.label",
                                         comment: "Start sound picker label"),
                       selection: $player.startSoundName) {
                    ForEach(systemSoundNames, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
            }
            Toggle(isOn: $player.endSoundEnabled) {
                Text(NSLocalizedString("SoundsView.endSoundEnabled.label",
                                       comment: "End sound label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
            if player.endSoundEnabled {
                Picker(NSLocalizedString("SoundsView.endSoundName.label",
                                         comment: "End sound picker label"),
                       selection: $player.endSoundName) {
                    ForEach(systemSoundNames, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
            }
            Toggle(isOn: $player.useCustomVolume) {
                Text(NSLocalizedString("SoundsView.useCustomVolume.label",
                                       comment: "Custom volume label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
            if player.useCustomVolume {
                HStack {
                    Text(NSLocalizedString("SoundsView.customVolumeLevel.label",
                                           comment: "Volume label"))
                    Slider(value: $player.customVolumeLevel, in: 0.0 ... 1.0) { editing in
                        if !editing { player.playStart() }
                    }
                }
            }
            Spacer().frame(minHeight: 0)
        }.padding(4)
    }
}

private enum ChildView {
    case intervals, settings, sounds
}

struct TBPopoverView: View {
    @ObservedObject var timer = TBTimer()
    @State private var buttonHovered = false
    @State private var activeChildView = ChildView.intervals

    private var startLabel = NSLocalizedString("TBPopoverView.start.label", comment: "Start label")
    private var stopLabel = NSLocalizedString("TBPopoverView.stop.label", comment: "Stop label")

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                timer.startStop()
                TBStatusItem.shared.closePopover(nil)
            } label: {
                Text(timer.timer != nil ?
                     (buttonHovered ? stopLabel : timer.timeLeftString) :
                        startLabel)
                    /*
                      When appearance is set to "Dark" and accent color is set to "Graphite"
                      "defaultAction" button label's color is set to the same color as the
                      button, making the button look blank. #24
                     */
                    .foregroundColor(Color.white)
                    .font(.system(.body).monospacedDigit())
                    .frame(maxWidth: .infinity)
            }
            .onHover { over in
                buttonHovered = over
            }
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)

            Picker("", selection: $activeChildView) {
                Text(NSLocalizedString("TBPopoverView.intervals.label",
                                       comment: "Intervals label")).tag(ChildView.intervals)
                Text(NSLocalizedString("TBPopoverView.settings.label",
                                       comment: "Settings label")).tag(ChildView.settings)
                Text(NSLocalizedString("TBPopoverView.sounds.label",
                                       comment: "Sounds label")).tag(ChildView.sounds)
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .pickerStyle(.segmented)

            GroupBox {
                switch activeChildView {
                case .intervals:
                    IntervalsView().environmentObject(timer)
                case .settings:
                    SettingsView().environmentObject(timer)
                case .sounds:
                    SoundsView().environmentObject(timer.player)
                }
            }

            Group {
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.orderFrontStandardAboutPanel()
                } label: {
                    Text(NSLocalizedString("TBPopoverView.about.label",
                                           comment: "About label"))
                    Spacer()
                    Text("⌘ A").foregroundColor(Color.gray)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("a")
                Button {
                    NSApplication.shared.terminate(self)
                } label: {
                    Text(NSLocalizedString("TBPopoverView.quit.label",
                                           comment: "Quit label"))
                    Spacer()
                    Text("⌘ Q").foregroundColor(Color.gray)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("q")
            }
        }
        #if DEBUG
            /*
             After several hours of Googling and trying various StackOverflow
             recipes I still haven't figured a reliable way to auto resize
             popover to fit all it's contents (pull requests are welcome!).
             The following code block is used to determine the optimal
             geometry of the popover.
             */
            .overlay(
                GeometryReader { proxy in
                    debugSize(proxy: proxy)
                }
            )
        #endif
            /* Use values from GeometryReader */
//            .frame(width: 240, height: 276)
            .padding(12)
    }
}

#if DEBUG
    func debugSize(proxy: GeometryProxy) -> some View {
        print("Optimal popover size:", proxy.size)
        return Color.clear
    }
#endif
