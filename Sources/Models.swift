import Foundation
import Carbon

// MARK: - Connection Settings

struct ConnectionConfig: Codable {
    var x32IP: String
    var x32Port: Int
    var ppHost: String
    var ppPort: Int
    var lightkeyHost: String
    var lightkeyPort: Int

    enum CodingKeys: String, CodingKey {
        case x32IP
        case x32Port
        case ppHost
        case ppPort
        case lightkeyHost
        case lightkeyPort
    }

    init(
        x32IP: String,
        x32Port: Int,
        ppHost: String,
        ppPort: Int,
        lightkeyHost: String = "127.0.0.1",
        lightkeyPort: Int = 21600
    ) {
        self.x32IP = x32IP
        self.x32Port = x32Port
        self.ppHost = ppHost
        self.ppPort = ppPort
        self.lightkeyHost = lightkeyHost
        self.lightkeyPort = lightkeyPort
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        x32IP = try container.decode(String.self, forKey: .x32IP)
        x32Port = try container.decode(Int.self, forKey: .x32Port)
        ppHost = try container.decode(String.self, forKey: .ppHost)
        ppPort = try container.decode(Int.self, forKey: .ppPort)
        lightkeyHost = try container.decodeIfPresent(String.self, forKey: .lightkeyHost) ?? "127.0.0.1"
        lightkeyPort = try container.decodeIfPresent(Int.self, forKey: .lightkeyPort) ?? 21600
    }
}

// MARK: - Hot Keys

struct HotKey: Codable, Hashable {
    var keyCode: UInt32
    var modifiers: UInt32
    var keyEquivalent: String

    var displayName: String {
        var parts: [String] = []
        if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        parts.append(keyEquivalent.isEmpty ? L("hotkey.key", keyCode) : keyEquivalent.uppercased())
        return parts.joined()
    }

    static func defaultForSlot(_ slot: Int) -> HotKey {
        HotKey(
            keyCode: defaultKeyCode(for: slot),
            modifiers: UInt32(controlKey | shiftKey),
            keyEquivalent: defaultKeyEquivalent(for: slot)
        )
    }

    private static func defaultKeyCode(for slot: Int) -> UInt32 {
        switch slot {
        case 1: return 0x12
        case 2: return 0x13
        case 3: return 0x14
        case 4: return 0x15
        case 5: return 0x17
        case 6: return 0x16
        case 7: return 0x1A
        case 8: return 0x1C
        case 9: return 0x19
        case 10: return 0x1D
        default: return 0x12
        }
    }

    private static func defaultKeyEquivalent(for slot: Int) -> String {
        slot == 10 ? "0" : String(slot)
    }
}

// MARK: - X32 Targets

enum X32Target: Codable, Hashable {
    case channel(Int)
    case auxIn(Int)
    case fxReturn(Int)
    case bus(Int)
    case matrix(Int)
    case mainStereo
    case mainMono
    case dca(Int)

    var displayName: String {
        switch self {
        case .channel(let index): return "CH\(index)"
        case .auxIn(let index): return "Aux In \(index)"
        case .fxReturn(let index): return "FX Return \(index)"
        case .bus(let index): return "Bus \(index)"
        case .matrix(let index): return "Matrix \(index)"
        case .mainStereo: return "Main ST"
        case .mainMono: return "Main M"
        case .dca(let index): return "DCA \(index)"
        }
    }

    var faderAddress: String {
        switch self {
        case .channel(let index): return "/ch/\(Self.twoDigit(index))/mix/fader"
        case .auxIn(let index): return "/auxin/\(Self.twoDigit(index))/mix/fader"
        case .fxReturn(let index): return "/fxrtn/\(Self.twoDigit(index))/mix/fader"
        case .bus(let index): return "/bus/\(Self.twoDigit(index))/mix/fader"
        case .matrix(let index): return "/mtx/\(Self.twoDigit(index))/mix/fader"
        case .mainStereo: return "/main/st/mix/fader"
        case .mainMono: return "/main/m/mix/fader"
        case .dca(let index): return "/dca/\(index)/fader"
        }
    }

    var onAddress: String {
        switch self {
        case .channel(let index): return "/ch/\(Self.twoDigit(index))/mix/on"
        case .auxIn(let index): return "/auxin/\(Self.twoDigit(index))/mix/on"
        case .fxReturn(let index): return "/fxrtn/\(Self.twoDigit(index))/mix/on"
        case .bus(let index): return "/bus/\(Self.twoDigit(index))/mix/on"
        case .matrix(let index): return "/mtx/\(Self.twoDigit(index))/mix/on"
        case .mainStereo: return "/main/st/mix/on"
        case .mainMono: return "/main/m/mix/on"
        case .dca(let index): return "/dca/\(index)/on"
        }
    }

    private static func twoDigit(_ value: Int) -> String {
        String(format: "%02d", value)
    }
}

// MARK: - Actions

enum Action: Codable, Identifiable, Hashable {
    // ProPresenter — Presentation
    case ppTrigger(presentationIndex: Int, slideIndex: Int)
    case ppGoToSlide(presentationIndex: Int, slideIndex: Int)
    case ppTriggerLastInPlaylist
    case ppSlideNext
    case ppSlidePrevious
    case ppPresentationNext
    case ppPresentationPrevious

    // ProPresenter — Announcement
    case ppAnnounceTrigger           // trigger active announcement
    case ppAnnounceTriggerAt(index: Int)  // trigger by index
    case ppAnnounceNext
    case ppAnnouncePrevious
    case ppAnnounceFocus             // focus active announcement
    case ppAnnounceSlideIndex        // get current announcement slide index

    // ProPresenter — Look
    case ppLookTrigger              // trigger current look
    case ppLookTriggerById(id: String)  // trigger look by id
    case ppLooksList                // list all looks

    // ProPresenter — Clear
    case ppClearLayer(layer: String)   // clear one layer: background, props, stage, audio, video, lights, all
    case ppClearGroup(id: String)      // clear group by id
    case ppClearAll                   // clear all

    // ProPresenter — Transport
    case ppTransportPlay
    case ppTransportPause
    case ppTransportStop
    case ppTransportPlayPause

    // ProPresenter — Stage
    case ppStageDisplayOn
    case ppStageDisplayOff
    case ppStageDisplayToggle

    // ProPresenter — Audio
    case ppAudioTrigger(playlistId: String?)   // trigger audio playlist (nil = focused)
    case ppAudioNext
    case ppAudioPrevious
    case ppAudioStop

    // ProPresenter — Capture
    case ppCaptureStart
    case ppCaptureStop
    case ppCaptureStatus

    // ProPresenter — Timeline
    case ppTimelineTrigger

    // ProPresenter — Groups
    case ppGroupTrigger(groupId: String)  // trigger global group

    // ProPresenter — Operations
    case ppOperationTrigger(name: String)  // trigger named operation

    // ProPresenter — Misc
    case ppFindMyMouse

    // X32
    case x32Fader(channel: Int, level: Double)
    case x32FaderAdjust(channel: Int, delta: Double)
    case x32Mute(channel: Int, muted: Bool)
    case x32MuteToggle(channel: Int?)
    case x32TargetFader(target: X32Target, level: Double)
    case x32TargetFaderAdjust(target: X32Target, delta: Double)
    case x32TargetMute(target: X32Target, muted: Bool)
    case x32TargetMuteToggle(target: X32Target)
    case x32Recording(start: Bool)
    case x32Osc(address: String, value: Double)

    // Lightkey
    case lightkeyCueToggle(address: String, fadeTime: Double)
    case lightkeyCueActivate(address: String, fadeTime: Double)
    case lightkeyCueDeactivate(address: String, fadeTime: Double)
    case lightkeyOsc(address: String, value: Double)

    var id: String {
        switch self {
        case .ppTrigger:            return "ppTrigger"
        case .ppGoToSlide:         return "ppGoToSlide"
        case .ppTriggerLastInPlaylist: return "ppTriggerLast"
        case .ppSlideNext:         return "ppSlideNext"
        case .ppSlidePrevious:     return "ppSlidePrevious"
        case .ppPresentationNext:  return "ppPresentationNext"
        case .ppPresentationPrevious: return "ppPresentationPrevious"
        case .ppAnnounceTrigger:   return "ppAnnounceTrigger"
        case .ppAnnounceTriggerAt(let i): return "ppAnnounceTriggerAt\(i)"
        case .ppAnnounceNext:      return "ppAnnounceNext"
        case .ppAnnouncePrevious:  return "ppAnnouncePrev"
        case .ppAnnounceFocus:     return "ppAnnounceFocus"
        case .ppAnnounceSlideIndex: return "ppAnnounceSlideIdx"
        case .ppLookTrigger:       return "ppLookTrigger"
        case .ppLookTriggerById:   return "ppLookTriggerById"
        case .ppLooksList:         return "ppLooksList"
        case .ppClearLayer:        return "ppClearLayer"
        case .ppClearGroup:        return "ppClearGroup"
        case .ppClearAll:          return "ppClearAll"
        case .ppTransportPlay:      return "ppTransportPlay"
        case .ppTransportPause:     return "ppTransportPause"
        case .ppTransportStop:      return "ppTransportStop"
        case .ppTransportPlayPause: return "ppTransportPlayPause"
        case .ppStageDisplayOn:    return "ppStageOn"
        case .ppStageDisplayOff:   return "ppStageOff"
        case .ppStageDisplayToggle: return "ppStageToggle"
        case .ppAudioTrigger:      return "ppAudioTrigger"
        case .ppAudioNext:         return "ppAudioNext"
        case .ppAudioPrevious:     return "ppAudioPrev"
        case .ppAudioStop:         return "ppAudioStop"
        case .ppCaptureStart:      return "ppCaptureStart"
        case .ppCaptureStop:       return "ppCaptureStop"
        case .ppCaptureStatus:     return "ppCaptureStatus"
        case .ppTimelineTrigger:   return "ppTimelineTrigger"
        case .ppGroupTrigger:      return "ppGroupTrigger"
        case .ppOperationTrigger:  return "ppOpTrigger"
        case .ppFindMyMouse:       return "ppFindMouse"
        case .x32Fader:            return "x32Fader"
        case .x32FaderAdjust:      return "x32FaderAdjust"
        case .x32Mute:             return "x32Mute"
        case .x32MuteToggle:       return "x32MuteToggle"
        case .x32TargetFader:      return "x32TargetFader"
        case .x32TargetFaderAdjust: return "x32TargetFaderAdjust"
        case .x32TargetMute:       return "x32TargetMute"
        case .x32TargetMuteToggle: return "x32TargetMuteToggle"
        case .x32Recording:        return "x32Recording"
        case .x32Osc:              return "x32Osc"
        case .lightkeyCueToggle:   return "lightkeyCueToggle"
        case .lightkeyCueActivate: return "lightkeyCueActivate"
        case .lightkeyCueDeactivate: return "lightkeyCueDeactivate"
        case .lightkeyOsc:         return "lightkeyOsc"
        }
    }

    var displayName: String {
        switch self {
        case .ppTrigger(let pres, let slide):
            return L("action.pp.trigger", pres, slide)
        case .ppGoToSlide(let pres, let slide):
            return L("action.pp.go_to_slide", pres, slide)
        case .ppTriggerLastInPlaylist:
            return L("action.pp.trigger_last")
        case .ppSlideNext:
            return L("action.pp.slide_next")
        case .ppSlidePrevious:
            return L("action.pp.slide_previous")
        case .ppPresentationNext:
            return L("action.pp.presentation_next")
        case .ppPresentationPrevious:
            return L("action.pp.presentation_previous")
        case .ppAnnounceTrigger:
            return L("action.pp.announce_trigger")
        case .ppAnnounceTriggerAt(let i):
            return L("action.pp.announce_trigger_at", i)
        case .ppAnnounceNext:
            return L("action.pp.announce_next")
        case .ppAnnouncePrevious:
            return L("action.pp.announce_previous")
        case .ppAnnounceFocus:
            return L("action.pp.announce_focus")
        case .ppAnnounceSlideIndex:
            return L("action.pp.announce_slide_index")
        case .ppLookTrigger:
            return L("action.pp.look_trigger")
        case .ppLookTriggerById(let id):
            return L("action.pp.look_trigger_id", id)
        case .ppLooksList:
            return L("action.pp.looks_list")
        case .ppClearLayer(let layer):
            return L("action.pp.clear_layer", layer)
        case .ppClearGroup(let id):
            return L("action.pp.clear_group", id)
        case .ppClearAll:
            return L("action.pp.clear_all")
        case .ppTransportPlay:
            return L("action.pp.transport_play")
        case .ppTransportPause:
            return L("action.pp.transport_pause")
        case .ppTransportStop:
            return L("action.pp.transport_stop")
        case .ppTransportPlayPause:
            return L("action.pp.transport_play_pause")
        case .ppStageDisplayOn:
            return L("action.pp.stage_on")
        case .ppStageDisplayOff:
            return L("action.pp.stage_off")
        case .ppStageDisplayToggle:
            return L("action.pp.stage_toggle")
        case .ppAudioTrigger(let id):
            return id.map { L("action.pp.audio_trigger_id", $0) } ?? L("action.pp.audio_trigger_focused")
        case .ppAudioNext:
            return L("action.pp.audio_next")
        case .ppAudioPrevious:
            return L("action.pp.audio_previous")
        case .ppAudioStop:
            return L("action.pp.audio_stop")
        case .ppCaptureStart:
            return L("action.pp.capture_start")
        case .ppCaptureStop:
            return L("action.pp.capture_stop")
        case .ppCaptureStatus:
            return L("action.pp.capture_status")
        case .ppTimelineTrigger:
            return L("action.pp.timeline_trigger")
        case .ppGroupTrigger(let id):
            return L("action.pp.group_trigger", id)
        case .ppOperationTrigger(let name):
            return L("action.pp.operation_trigger", name)
        case .ppFindMyMouse:
            return L("action.pp.find_mouse")
        case .x32Fader(let ch, let level):
            return L("action.x32.fader", ch, level * 100)
        case .x32FaderAdjust(let ch, let delta):
            let sign = delta >= 0 ? "+" : ""
            return L("action.x32.fader_adjust", ch, sign, delta * 100)
        case .x32Mute(let ch, let muted):
            return L(muted ? "action.x32.mute" : "action.x32.unmute", ch)
        case .x32MuteToggle(let ch):
            return L("action.x32.mute_toggle", ch ?? 1)
        case .x32TargetFader(let target, let level):
            return L("action.x32.target_fader", target.displayName, level * 100)
        case .x32TargetFaderAdjust(let target, let delta):
            let sign = delta >= 0 ? "+" : ""
            return L("action.x32.target_fader_adjust", target.displayName, sign, delta * 100)
        case .x32TargetMute(let target, let muted):
            return L(muted ? "action.x32.target_mute" : "action.x32.target_unmute", target.displayName)
        case .x32TargetMuteToggle(let target):
            return L("action.x32.target_mute_toggle", target.displayName)
        case .x32Recording(let start):
            return L(start ? "action.x32.recording_start" : "action.x32.recording_stop")
        case .x32Osc(let addr, let val):
            return L("action.x32.osc", addr, val)
        case .lightkeyCueToggle(let address, let fadeTime):
            return L("action.lightkey.cue_toggle", address, fadeTime)
        case .lightkeyCueActivate(let address, let fadeTime):
            return L("action.lightkey.cue_activate", address, fadeTime)
        case .lightkeyCueDeactivate(let address, let fadeTime):
            return L("action.lightkey.cue_deactivate", address, fadeTime)
        case .lightkeyOsc(let address, let value):
            return L("action.lightkey.osc", address, value)
        }
    }

    var isProPresenter: Bool {
        switch self {
        case .ppTrigger, .ppGoToSlide, .ppTriggerLastInPlaylist,
             .ppSlideNext, .ppSlidePrevious, .ppPresentationNext, .ppPresentationPrevious,
             .ppAnnounceTrigger, .ppAnnounceTriggerAt, .ppAnnounceNext, .ppAnnouncePrevious,
             .ppAnnounceFocus, .ppAnnounceSlideIndex,
             .ppLookTrigger, .ppLookTriggerById, .ppLooksList,
             .ppClearLayer, .ppClearGroup, .ppClearAll,
             .ppTransportPlay, .ppTransportPause, .ppTransportStop, .ppTransportPlayPause,
             .ppStageDisplayOn, .ppStageDisplayOff, .ppStageDisplayToggle,
             .ppAudioTrigger, .ppAudioNext, .ppAudioPrevious, .ppAudioStop,
             .ppCaptureStart, .ppCaptureStop, .ppCaptureStatus,
             .ppTimelineTrigger, .ppGroupTrigger, .ppOperationTrigger, .ppFindMyMouse:
            return true
        default:
            return false
        }
    }

    var isX32: Bool {
        switch self {
        case .x32Fader, .x32FaderAdjust, .x32Mute, .x32MuteToggle,
             .x32TargetFader, .x32TargetFaderAdjust, .x32TargetMute, .x32TargetMuteToggle,
             .x32Recording, .x32Osc:
            return true
        default:
            return false
        }
    }

    var isLightkey: Bool {
        switch self {
        case .lightkeyCueToggle, .lightkeyCueActivate, .lightkeyCueDeactivate, .lightkeyOsc:
            return true
        default:
            return false
        }
    }
}

// MARK: - Shortcut

struct Shortcut: Codable, Identifiable {
    var id: Int { keyNumber }
    let keyNumber: Int
    var hotKey: HotKey
    var label: String
    var actions: [Action]
    var enabled: Bool

    var keyLabel: String { hotKey.displayName }

    init(keyNumber: Int, hotKey: HotKey? = nil, label: String, actions: [Action], enabled: Bool) {
        self.keyNumber = keyNumber
        self.hotKey = hotKey ?? .defaultForSlot(keyNumber)
        self.label = label
        self.actions = actions
        self.enabled = enabled
    }

    enum CodingKeys: String, CodingKey {
        case keyNumber
        case hotKey
        case label
        case actions
        case enabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        keyNumber = try container.decode(Int.self, forKey: .keyNumber)
        hotKey = try container.decodeIfPresent(HotKey.self, forKey: .hotKey) ?? .defaultForSlot(keyNumber)
        label = try container.decode(String.self, forKey: .label)
        actions = try container.decode([Action].self, forKey: .actions)
        enabled = try container.decode(Bool.self, forKey: .enabled)
    }
}

// MARK: - Full App Config

struct AppConfig: Codable {
    var connections: ConnectionConfig
    var shortcuts: [Shortcut]
    var launchAtLogin: Bool
    var language: AppLanguage
    var buttonCount: Int

    enum CodingKeys: String, CodingKey {
        case connections
        case shortcuts
        case launchAtLogin
        case language
        case buttonCount
    }

    init(connections: ConnectionConfig, shortcuts: [Shortcut], launchAtLogin: Bool, language: AppLanguage, buttonCount: Int = 6) {
        self.connections = connections
        self.shortcuts = shortcuts
        self.launchAtLogin = launchAtLogin
        self.language = language
        self.buttonCount = buttonCount
        normalize()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        connections = try container.decode(ConnectionConfig.self, forKey: .connections)
        shortcuts = try container.decode([Shortcut].self, forKey: .shortcuts)
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .german
        buttonCount = try container.decodeIfPresent(Int.self, forKey: .buttonCount) ?? 6
        normalize()
    }

    var activeShortcuts: [Shortcut] {
        Array(shortcuts.prefix(buttonCount))
    }

    mutating func normalize() {
        buttonCount = min(max(buttonCount, Self.minimumButtonCount), Self.maximumButtonCount)
        ensureShortcutCapacity()
    }

    mutating func ensureShortcutCapacity() {
        guard shortcuts.count < buttonCount else { return }
        let existingNumbers = Set(shortcuts.map(\.keyNumber))
        for keyNumber in 1...buttonCount where !existingNumbers.contains(keyNumber) {
            shortcuts.append(Self.defaultShortcut(for: keyNumber))
        }
        shortcuts.sort { $0.keyNumber < $1.keyNumber }
    }

    static let minimumButtonCount = 1
    static let maximumButtonCount = 10

    static func defaultShortcut(for keyNumber: Int) -> Shortcut {
        Shortcut(
            keyNumber: keyNumber,
            label: "",
            actions: [],
            enabled: true
        )
    }

    static var `default`: AppConfig {
        AppConfig(
            connections: ConnectionConfig(
                x32IP: "192.168.1.100",
                x32Port: 10023,
                ppHost: "127.0.0.1",
                ppPort: 52809,
                lightkeyHost: "127.0.0.1",
                lightkeyPort: 21600
            ),
            shortcuts: [
                Shortcut(keyNumber: 1, label: "Präsentation 1 laden", actions: [
                    .ppTrigger(presentationIndex: 0, slideIndex: 0)
                ], enabled: true),
                Shortcut(keyNumber: 2, label: "Präsentation 2 + Aufnahme", actions: [
                    .ppTrigger(presentationIndex: 1, slideIndex: 0),
                    .x32Recording(start: true)
                ], enabled: true),
                Shortcut(keyNumber: 3, label: "Letzte Präsentation + Stopp", actions: [
                    .ppTriggerLastInPlaylist,
                    .x32Recording(start: false)
                ], enabled: true),
                Shortcut(keyNumber: 4, label: "X32: Lauter", actions: [
                    .x32FaderAdjust(channel: 1, delta: 0.05)
                ], enabled: true),
                Shortcut(keyNumber: 5, label: "X32: Stumm/An", actions: [
                    .x32Mute(channel: 1, muted: true)
                ], enabled: true),
                Shortcut(keyNumber: 6, label: "X32: Leiser", actions: [
                    .x32FaderAdjust(channel: 1, delta: -0.05)
                ], enabled: true)
            ],
            launchAtLogin: false,
            language: .german,
            buttonCount: 6
        )
    }
}

// MARK: - Action Type Catalogs (for the Add-Action wizard)

enum ProPresenterActionType: CaseIterable {
    case ppTrigger
    case ppGoToSlide
    case ppTriggerLastInPlaylist
    case ppSlideNext
    case ppSlidePrevious
    case ppPresentationNext
    case ppPresentationPrevious
    case ppAnnounceTrigger
    case ppAnnounceTriggerAt
    case ppAnnounceNext
    case ppAnnouncePrevious
    case ppLookTrigger
    case ppLookTriggerById
    case ppClearLayer
    case ppClearGroup
    case ppClearAll
    case ppTransportPlay
    case ppTransportPause
    case ppTransportStop
    case ppTransportPlayPause
    case ppStageDisplayOn
    case ppStageDisplayOff
    case ppStageDisplayToggle
    case ppAudioTrigger
    case ppAudioNext
    case ppAudioPrevious
    case ppAudioStop
    case ppCaptureStart
    case ppCaptureStop
    case ppGroupTrigger
    case ppOperationTrigger
    case ppFindMyMouse

    var displayName: String {
        switch self {
        case .ppTrigger: return L("type.pp.trigger")
        case .ppGoToSlide: return L("type.pp.go_to_slide")
        case .ppTriggerLastInPlaylist: return L("type.pp.trigger_last")
        case .ppSlideNext: return L("type.pp.slide_next")
        case .ppSlidePrevious: return L("type.pp.slide_previous")
        case .ppPresentationNext: return L("type.pp.presentation_next")
        case .ppPresentationPrevious: return L("type.pp.presentation_previous")
        case .ppAnnounceTrigger: return L("type.pp.announce_trigger")
        case .ppAnnounceTriggerAt: return L("type.pp.announce_trigger_at")
        case .ppAnnounceNext: return L("type.pp.announce_next")
        case .ppAnnouncePrevious: return L("type.pp.announce_previous")
        case .ppLookTrigger: return L("type.pp.look_trigger")
        case .ppLookTriggerById: return L("type.pp.look_trigger_id")
        case .ppClearLayer: return L("type.pp.clear_layer")
        case .ppClearGroup: return L("type.pp.clear_group")
        case .ppClearAll: return L("type.pp.clear_all")
        case .ppTransportPlay: return L("type.pp.transport_play")
        case .ppTransportPause: return L("type.pp.transport_pause")
        case .ppTransportStop: return L("type.pp.transport_stop")
        case .ppTransportPlayPause: return L("type.pp.transport_play_pause")
        case .ppStageDisplayOn: return L("type.pp.stage_on")
        case .ppStageDisplayOff: return L("type.pp.stage_off")
        case .ppStageDisplayToggle: return L("type.pp.stage_toggle")
        case .ppAudioTrigger: return L("type.pp.audio_trigger")
        case .ppAudioNext: return L("type.pp.audio_next")
        case .ppAudioPrevious: return L("type.pp.audio_previous")
        case .ppAudioStop: return L("type.pp.audio_stop")
        case .ppCaptureStart: return L("type.pp.capture_start")
        case .ppCaptureStop: return L("type.pp.capture_stop")
        case .ppGroupTrigger: return L("type.pp.group_trigger")
        case .ppOperationTrigger: return L("type.pp.operation_trigger")
        case .ppFindMyMouse: return L("type.pp.find_mouse")
        }
    }

    var description: String {
        switch self {
        case .ppTrigger: return L("desc.pp.trigger")
        case .ppGoToSlide: return L("desc.pp.go_to_slide")
        case .ppTriggerLastInPlaylist: return L("desc.pp.trigger_last")
        case .ppSlideNext: return L("desc.pp.slide_next")
        case .ppSlidePrevious: return L("desc.pp.slide_previous")
        case .ppPresentationNext: return L("desc.pp.presentation_next")
        case .ppPresentationPrevious: return L("desc.pp.presentation_previous")
        case .ppAnnounceTrigger: return L("desc.pp.announce_trigger")
        case .ppAnnounceTriggerAt: return L("desc.pp.announce_trigger_at")
        case .ppAnnounceNext: return L("desc.pp.announce_next")
        case .ppAnnouncePrevious: return L("desc.pp.announce_previous")
        case .ppLookTrigger: return L("desc.pp.look_trigger")
        case .ppLookTriggerById: return L("desc.pp.look_trigger_id")
        case .ppClearLayer: return L("desc.pp.clear_layer")
        case .ppClearGroup: return L("desc.pp.clear_group")
        case .ppClearAll: return L("desc.pp.clear_all")
        case .ppTransportPlay: return L("desc.pp.transport_play")
        case .ppTransportPause: return L("desc.pp.transport_pause")
        case .ppTransportStop: return L("desc.pp.transport_stop")
        case .ppTransportPlayPause: return L("desc.pp.transport_play_pause")
        case .ppStageDisplayOn: return L("desc.pp.stage_on")
        case .ppStageDisplayOff: return L("desc.pp.stage_off")
        case .ppStageDisplayToggle: return L("desc.pp.stage_toggle")
        case .ppAudioTrigger: return L("desc.pp.audio_trigger")
        case .ppAudioNext: return L("desc.pp.audio_next")
        case .ppAudioPrevious: return L("desc.pp.audio_previous")
        case .ppAudioStop: return L("desc.pp.audio_stop")
        case .ppCaptureStart: return L("desc.pp.capture_start")
        case .ppCaptureStop: return L("desc.pp.capture_stop")
        case .ppGroupTrigger: return L("desc.pp.group_trigger")
        case .ppOperationTrigger: return L("desc.pp.operation_trigger")
        case .ppFindMyMouse: return L("desc.pp.find_mouse")
        }
    }

    var defaultAction: Action {
        switch self {
        case .ppTrigger: return .ppTrigger(presentationIndex: 0, slideIndex: 0)
        case .ppGoToSlide: return .ppGoToSlide(presentationIndex: 0, slideIndex: 0)
        case .ppTriggerLastInPlaylist: return .ppTriggerLastInPlaylist
        case .ppSlideNext: return .ppSlideNext
        case .ppSlidePrevious: return .ppSlidePrevious
        case .ppPresentationNext: return .ppPresentationNext
        case .ppPresentationPrevious: return .ppPresentationPrevious
        case .ppAnnounceTrigger: return .ppAnnounceTrigger
        case .ppAnnounceTriggerAt: return .ppAnnounceTriggerAt(index: 0)
        case .ppAnnounceNext: return .ppAnnounceNext
        case .ppAnnouncePrevious: return .ppAnnouncePrevious
        case .ppLookTrigger: return .ppLookTrigger
        case .ppLookTriggerById: return .ppLookTriggerById(id: "")
        case .ppClearLayer: return .ppClearLayer(layer: "all")
        case .ppClearGroup: return .ppClearGroup(id: "")
        case .ppClearAll: return .ppClearAll
        case .ppTransportPlay: return .ppTransportPlay
        case .ppTransportPause: return .ppTransportPause
        case .ppTransportStop: return .ppTransportStop
        case .ppTransportPlayPause: return .ppTransportPlayPause
        case .ppStageDisplayOn: return .ppStageDisplayOn
        case .ppStageDisplayOff: return .ppStageDisplayOff
        case .ppStageDisplayToggle: return .ppStageDisplayToggle
        case .ppAudioTrigger: return .ppAudioTrigger(playlistId: nil)
        case .ppAudioNext: return .ppAudioNext
        case .ppAudioPrevious: return .ppAudioPrevious
        case .ppAudioStop: return .ppAudioStop
        case .ppCaptureStart: return .ppCaptureStart
        case .ppCaptureStop: return .ppCaptureStop
        case .ppGroupTrigger: return .ppGroupTrigger(groupId: "")
        case .ppOperationTrigger: return .ppOperationTrigger(name: "")
        case .ppFindMyMouse: return .ppFindMyMouse
        }
    }
}

enum X32ActionType: CaseIterable {
    case x32TargetFader
    case x32TargetFaderAdjust
    case x32TargetMute
    case x32TargetMuteToggle
    case x32Recording
    case x32Osc

    var displayName: String {
        switch self {
        case .x32TargetFader: return L("type.x32.target_fader")
        case .x32TargetFaderAdjust: return L("type.x32.target_fader_adjust")
        case .x32TargetMute: return L("type.x32.target_mute")
        case .x32TargetMuteToggle: return L("type.x32.target_mute_toggle")
        case .x32Recording: return L("type.x32.recording")
        case .x32Osc: return L("type.x32.osc")
        }
    }

    var description: String {
        switch self {
        case .x32TargetFader: return L("desc.x32.target_fader")
        case .x32TargetFaderAdjust: return L("desc.x32.target_fader_adjust")
        case .x32TargetMute: return L("desc.x32.target_mute")
        case .x32TargetMuteToggle: return L("desc.x32.target_mute_toggle")
        case .x32Recording: return L("desc.x32.recording")
        case .x32Osc: return L("desc.x32.osc")
        }
    }

    var defaultAction: Action {
        switch self {
        case .x32TargetFader: return .x32TargetFader(target: .channel(1), level: 0.75)
        case .x32TargetFaderAdjust: return .x32TargetFaderAdjust(target: .channel(1), delta: 0.05)
        case .x32TargetMute: return .x32TargetMute(target: .channel(1), muted: true)
        case .x32TargetMuteToggle: return .x32TargetMuteToggle(target: .channel(1))
        case .x32Recording: return .x32Recording(start: true)
        case .x32Osc: return .x32Osc(address: "/ch/01/mix/fader", value: 0.75)
        }
    }
}

enum LightkeyActionType: CaseIterable {
    case cueToggle
    case cueActivate
    case cueDeactivate
    case osc

    var displayName: String {
        switch self {
        case .cueToggle: return L("type.lightkey.cue_toggle")
        case .cueActivate: return L("type.lightkey.cue_activate")
        case .cueDeactivate: return L("type.lightkey.cue_deactivate")
        case .osc: return L("type.lightkey.osc")
        }
    }

    var description: String {
        switch self {
        case .cueToggle: return L("desc.lightkey.cue_toggle")
        case .cueActivate: return L("desc.lightkey.cue_activate")
        case .cueDeactivate: return L("desc.lightkey.cue_deactivate")
        case .osc: return L("desc.lightkey.osc")
        }
    }

    var defaultAction: Action {
        switch self {
        case .cueToggle:
            return .lightkeyCueToggle(address: "/live/My_Control_Panel/cue/My_Cue_Name/toggle", fadeTime: 0)
        case .cueActivate:
            return .lightkeyCueActivate(address: "/live/My_Control_Panel/cue/My_Cue_Name/activate", fadeTime: 0)
        case .cueDeactivate:
            return .lightkeyCueDeactivate(address: "/live/My_Control_Panel/cue/My_Cue_Name/deactivate", fadeTime: 0)
        case .osc:
            return .lightkeyOsc(address: "/live/My_Control_Panel/cue/My_Cue_Name/toggle", value: 0)
        }
    }
}

// MARK: - Config Persistence

struct ConfigStore {
    static let fileName = "config.json"

    static var configURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("MacroKeys", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(fileName)
    }

    static func load() -> AppConfig {
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            return .default
        }
        do {
            let data = try Data(contentsOf: configURL)
            var config = try JSONDecoder().decode(AppConfig.self, from: data)
            if config.connections.x32Port == 10024 {
                config.connections.x32Port = 10023
                _ = save(config)
            }
            config.normalize()
            return config
        } catch {
            print("Config load error: \(error)")
            return .default
        }
    }

    static func loadLanguage() -> AppLanguage {
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            return AppConfig.default.language
        }

        do {
            let data = try Data(contentsOf: configURL)
            return try JSONDecoder().decode(AppConfig.self, from: data).language
        } catch {
            return AppConfig.default.language
        }
    }

    static func save(_ config: AppConfig) -> Bool {
        do {
            var normalizedConfig = config
            normalizedConfig.normalize()
            let data = try JSONEncoder().encode(normalizedConfig)
            try data.write(to: configURL, options: .atomic)
            return true
        } catch {
            print("Config save error: \(error)")
            return false
        }
    }
}
