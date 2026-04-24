//
//  SettingsView.swift
//  TomatoBar
//
//  Created by Pierre Oosthuizen on 2026/04/24.
//


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