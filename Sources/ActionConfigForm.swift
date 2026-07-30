import SwiftUI

// MARK: - Action Config Form

struct ActionConfigForm: View {
    @Binding var action: Action?
    @ObservedObject private var l10n = LocalizationManager.shared

    var body: some View {
        VStack(spacing: 0) {
            if let a = action {
                Form {
                    Section(L("form.preview")) {
                        Text(a.displayName)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }

                    Section(L("form.parameters")) {
                        actionParamFields
                    }
                }
                .formStyle(.grouped)
            }
        }
    }

    @ViewBuilder
    private var actionParamFields: some View {
        if let a = action {
            switch a {
            case .ppTrigger:
                ppTriggerFields
            case .ppGoToSlide:
                ppGoToSlideFields
            case .ppAnnounceTriggerAt(let idx):
                Stepper(L("form.index", idx), value: Binding(
                    get: { idx },
                    set: { action = .ppAnnounceTriggerAt(index: $0) }
                ), in: 0...99)
            case .ppLookTriggerById:
                textField(L("form.look_id"), value: Binding(
                    get: {
                        if case .ppLookTriggerById(let id) = a { return id }
                        return ""
                    },
                    set: { action = .ppLookTriggerById(id: $0) }
                ))
            case .ppClearLayer:
                layerPicker
            case .ppClearGroup:
                textField(L("form.group_id"), value: Binding(
                    get: {
                        if case .ppClearGroup(let id) = a { return id }
                        return ""
                    },
                    set: { action = .ppClearGroup(id: $0) }
                ))
            case .ppAudioTrigger:
                textField(L("form.playlist_id_optional"), value: Binding(
                    get: {
                        if case .ppAudioTrigger(let id) = a { return id ?? "" }
                        return ""
                    },
                    set: { action = .ppAudioTrigger(playlistId: $0.isEmpty ? nil : $0) }
                ))
            case .ppGroupTrigger:
                textField(L("form.group_id"), value: Binding(
                    get: {
                        if case .ppGroupTrigger(let id) = a { return id }
                        return ""
                    },
                    set: { action = .ppGroupTrigger(groupId: $0) }
                ))
            case .ppOperationTrigger:
                textField(L("form.operation_name"), value: Binding(
                    get: {
                        if case .ppOperationTrigger(let name) = a { return name }
                        return ""
                    },
                    set: { action = .ppOperationTrigger(name: $0) }
                ))
            case .x32Fader(let channel, let level):
                HStack {
                    Stepper(L("form.channel", channel), value: Binding(
                        get: { channel },
                        set: { action = .x32Fader(channel: $0, level: level) }
                    ), in: 1...32)
                    Text(String(format: "%.0f%%", level * 100))
                        .font(.caption.monospacedDigit())
                        .frame(width: 36)
                }
                Slider(value: Binding(
                    get: { level },
                    set: { action = .x32Fader(channel: channel, level: $0) }
                ), in: 0...1)
                Text(String(format: "%.0f%%", level * 100))
                    .font(.caption.monospacedDigit())
            case .x32FaderAdjust(let channel, let delta):
                HStack {
                    Stepper(L("form.channel", channel), value: Binding(
                        get: { channel },
                        set: { action = .x32FaderAdjust(channel: $0, delta: delta) }
                    ), in: 1...32)
                }
                x32FaderAdjustButtons(selectedDelta: delta) {
                    action = .x32FaderAdjust(channel: channel, delta: $0)
                }
            case .x32Osc(let addr, let val):
                HStack {
                    TextField(L("form.address"), text: Binding(
                        get: { addr },
                        set: { action = .x32Osc(address: $0, value: val) }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 150)
                    TextField(L("form.value"), value: Binding(
                        get: { val },
                        set: { action = .x32Osc(address: addr, value: $0) }
                    ), format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 70)
                }
            case .x32Mute(let channel, let muted):
                HStack {
                    Toggle(L("form.muted"), isOn: Binding(
                        get: { muted },
                        set: { action = .x32Mute(channel: channel, muted: $0) }
                    ))
                    Stepper(L("form.channel", channel), value: Binding(
                        get: { channel },
                        set: { action = .x32Mute(channel: $0, muted: muted) }
                    ), in: 1...32)
                }
            case .x32MuteToggle(let channel):
                let selectedChannel = channel ?? 1
                Stepper(L("form.channel", selectedChannel), value: Binding(
                    get: { selectedChannel },
                    set: { action = .x32MuteToggle(channel: $0) }
                ), in: 1...32)
            case .x32TargetFader(let target, let level):
                x32TargetPicker(target: target) {
                    action = .x32TargetFader(target: $0, level: level)
                }
                Slider(value: Binding(
                    get: { level },
                    set: { action = .x32TargetFader(target: target, level: $0) }
                ), in: 0...1)
                Text(String(format: "%.0f%%", level * 100))
                    .font(.caption.monospacedDigit())
            case .x32TargetFaderAdjust(let target, let delta):
                x32TargetPicker(target: target) {
                    action = .x32TargetFaderAdjust(target: $0, delta: delta)
                }
                x32FaderAdjustButtons(selectedDelta: delta) {
                    action = .x32TargetFaderAdjust(target: target, delta: $0)
                }
            case .x32TargetMute(let target, let muted):
                x32TargetPicker(target: target) {
                    action = .x32TargetMute(target: $0, muted: muted)
                }
                Toggle(L("form.muted"), isOn: Binding(
                    get: { muted },
                    set: { action = .x32TargetMute(target: target, muted: $0) }
                ))
            case .x32TargetMuteToggle(let target):
                x32TargetPicker(target: target) {
                    action = .x32TargetMuteToggle(target: $0)
                }
            case .x32Recording(let start):
                Toggle(L("form.start_recording"), isOn: Binding(
                    get: { start },
                    set: { action = .x32Recording(start: $0) }
                ))
            default:
                Text(L("form.no_parameters"))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var ppTriggerFields: some View {
        Group {
            if case .ppTrigger(let pres, let slide) = action {
                HStack {
                    Stepper(L("form.presentation", pres), value: Binding(
                        get: { pres },
                        set: { action = .ppTrigger(presentationIndex: $0, slideIndex: slide) }
                    ), in: 0...99)
                    Stepper(L("form.slide", slide), value: Binding(
                        get: { slide },
                        set: { action = .ppTrigger(presentationIndex: pres, slideIndex: $0) }
                    ), in: 0...99)
                }
            }
        }
    }

    private var ppGoToSlideFields: some View {
        Group {
            if case .ppGoToSlide(let pres, let slide) = action {
                HStack {
                    Stepper(L("form.presentation", pres), value: Binding(
                        get: { pres },
                        set: { action = .ppGoToSlide(presentationIndex: $0, slideIndex: slide) }
                    ), in: 0...99)
                    Stepper(L("form.slide", slide), value: Binding(
                        get: { slide },
                        set: { action = .ppGoToSlide(presentationIndex: pres, slideIndex: $0) }
                    ), in: 0...99)
                }
            }
        }
    }

    private var layerPicker: some View {
        Picker(L("form.layer"), selection: Binding(
            get: {
                if case .ppClearLayer(let layer) = action ?? .ppClearLayer(layer: "all") { return layer }
                return "all"
            },
            set: { action = .ppClearLayer(layer: $0) }
        )) {
            Text("all").tag("all")
            Text("background").tag("background")
            Text("props").tag("props")
            Text("stage").tag("stage")
            Text("audio").tag("audio")
            Text("video").tag("video")
            Text("lights").tag("lights")
        }
    }

    private func textField(_ label: String, value: Binding<String>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", text: value)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
        }
    }

    private func x32FaderAdjustButtons(selectedDelta: Double, onSelect: @escaping (Double) -> Void) -> some View {
        HStack(spacing: 8) {
            ForEach([FaderAdjustOption(label: "-10%", delta: -0.10),
                     FaderAdjustOption(label: "-5%", delta: -0.05),
                     FaderAdjustOption(label: "+5%", delta: 0.05),
                     FaderAdjustOption(label: "+10%", delta: 0.10)]) { option in
                if isSelected(option.delta, selectedDelta) {
                    Button(option.label) {
                        onSelect(option.delta)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .frame(width: 64)
                } else {
                    Button(option.label) {
                        onSelect(option.delta)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .frame(width: 64)
                }
            }
        }
    }

    private func isSelected(_ lhs: Double, _ rhs: Double) -> Bool {
        abs(lhs - rhs) < 0.0001
    }

    private func x32TargetPicker(target: X32Target, onChange: @escaping (X32Target) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(L("form.target"))
                Spacer()
                Picker("", selection: Binding(
                    get: { X32TargetKind(target: target) },
                    set: { onChange($0.defaultTarget) }
                )) {
                    ForEach(X32TargetKind.allCases, id: \.self) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                .labelsHidden()
                .frame(width: 170)
            }

            let kind = X32TargetKind(target: target)
            if let range = kind.range {
                HStack {
                    Text(kind.numberLabel)
                    Spacer()
                    TextField("", text: targetNumberTextBinding(target: target, kind: kind, range: range, onChange: onChange))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 52)
                        .multilineTextAlignment(.trailing)
                    Stepper("", value: Binding(
                        get: { targetNumber(target) },
                        set: { onChange(kind.target(number: clipped($0, to: range))) }
                    ), in: range)
                    .labelsHidden()
                    .frame(width: 72)
                }
            }
        }
    }

    private func targetNumberTextBinding(
        target: X32Target,
        kind: X32TargetKind,
        range: ClosedRange<Int>,
        onChange: @escaping (X32Target) -> Void
    ) -> Binding<String> {
        Binding(
            get: { String(targetNumber(target)) },
            set: { text in
                guard let number = Int(text) else { return }
                onChange(kind.target(number: clipped(number, to: range)))
            }
        )
    }

    private func clipped(_ value: Int, to range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }

    private func targetNumber(_ target: X32Target) -> Int {
        switch target {
        case .channel(let index), .auxIn(let index), .fxReturn(let index),
             .bus(let index), .matrix(let index), .dca(let index):
            return index
        case .mainStereo, .mainMono:
            return 1
        }
    }
}

private struct FaderAdjustOption: Identifiable {
    var label: String
    var delta: Double

    var id: Double { delta }
}

private enum X32TargetKind: String, CaseIterable {
    case channel
    case auxIn
    case fxReturn
    case bus
    case matrix
    case mainStereo
    case mainMono
    case dca

    init(target: X32Target) {
        switch target {
        case .channel: self = .channel
        case .auxIn: self = .auxIn
        case .fxReturn: self = .fxReturn
        case .bus: self = .bus
        case .matrix: self = .matrix
        case .mainStereo: self = .mainStereo
        case .mainMono: self = .mainMono
        case .dca: self = .dca
        }
    }

    var displayName: String {
        switch self {
        case .channel: return L("x32.target.channel")
        case .auxIn: return "Aux In"
        case .fxReturn: return "FX Return"
        case .bus: return "Bus"
        case .matrix: return "Matrix"
        case .mainStereo: return "Main ST"
        case .mainMono: return "Main M"
        case .dca: return "DCA"
        }
    }

    var numberLabel: String {
        switch self {
        case .channel: return L("x32.target.channel")
        case .auxIn: return "Aux In"
        case .fxReturn: return "FX Return"
        case .bus: return "Bus"
        case .matrix: return "Matrix"
        case .dca: return "DCA"
        case .mainStereo, .mainMono: return ""
        }
    }

    var range: ClosedRange<Int>? {
        switch self {
        case .channel: return 1...32
        case .auxIn: return 1...8
        case .fxReturn: return 1...8
        case .bus: return 1...16
        case .matrix: return 1...6
        case .dca: return 1...8
        case .mainStereo, .mainMono: return nil
        }
    }

    var defaultTarget: X32Target {
        target(number: 1)
    }

    func target(number: Int) -> X32Target {
        switch self {
        case .channel: return .channel(number)
        case .auxIn: return .auxIn(number)
        case .fxReturn: return .fxReturn(number)
        case .bus: return .bus(number)
        case .matrix: return .matrix(number)
        case .mainStereo: return .mainStereo
        case .mainMono: return .mainMono
        case .dca: return .dca(number)
        }
    }
}
