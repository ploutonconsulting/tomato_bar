//
//  SoundsView.swift
//  TomatoBar
//
//  Created by Pierre Oosthuizen on 2026/04/24.
//


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
                    ForEach(bundledSoundNames, id: \.self) { name in
                        Text(name).tag(name)
                    }
                    Divider()
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
                    ForEach(bundledSoundNames, id: \.self) { name in
                        Text(name).tag(name)
                    }
                    Divider()
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