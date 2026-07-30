import Foundation

// MARK: - Action Executor

@MainActor
class ActionExecutor: ObservableObject {
    static let shared = ActionExecutor()

    private var ppClient: ProPresenterClient?
    private var x32Client: X32Client?

    @Published var lastLog: [String] = []
    @Published var isConnectedPP: Bool = false
    @Published var isConnectedX32: Bool = false

    private init() {}

    func configure(connections: ConnectionConfig) {
        ppClient = ProPresenterClient(host: connections.ppHost, port: connections.ppPort)
        x32Client = X32Client(host: connections.x32IP, port: connections.x32Port)
    }

    func execute(actions: [Action]) async {
        var logs: [String] = []

        for action in actions {
            let start = Date()

            if action.isProPresenter {
                await executeProPresenterAction(action, logs: &logs)
            } else if action.isX32 {
                executeX32Action(action, logs: &logs)
            }

            let elapsed = Date().timeIntervalSince(start) * 1000
            if !logs.isEmpty {
                logs[logs.count - 1] = "\(logs[logs.count - 1]) (\(Int(elapsed))ms)"
            }
        }

        lastLog = logs
    }

    // MARK: - ProPresenter

    private func executeProPresenterAction(_ action: Action, logs: inout [String]) async {
        guard let pp = ppClient else {
            logs.append("✗ ProPresenter: not configured")
            return
        }

        switch action {
        case .ppTrigger(let presIdx, let slideIdx):
            do {
                try await pp.triggerPresentation(presentationIndex: presIdx, slideIndex: slideIdx)
                logs.append("✓ PP: triggered pres[\(presIdx)] slide[\(slideIdx)]")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppGoToSlide(let presIdx, let slideIdx):
            do {
                try await pp.triggerPresentation(presentationIndex: presIdx, slideIndex: slideIdx)
                logs.append("✓ PP: go to pres[\(presIdx)] slide[\(slideIdx)]")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppTriggerLastInPlaylist:
            do {
                try await pp.triggerLastInPlaylist()
                logs.append("✓ PP: triggered last in playlist")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppSlideNext:
            do {
                try await pp.triggerNextSlide()
                logs.append("✓ PP: next slide")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppSlidePrevious:
            do {
                try await pp.triggerPreviousSlide()
                logs.append("✓ PP: previous slide")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppPresentationNext:
            do {
                try await pp.triggerNextPresentation()
                logs.append("✓ PP: next presentation")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppPresentationPrevious:
            do {
                try await pp.triggerPreviousPresentation()
                logs.append("✓ PP: previous presentation")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppAnnounceTrigger:
            do {
                try await pp.triggerAnnounceCurrent()
                logs.append("✓ PP: announcement triggered")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppAnnounceTriggerAt(let idx):
            do {
                try await pp.triggerAnnounceAt(index: idx)
                logs.append("✓ PP: announcement[\(idx)] triggered")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppAnnounceNext:
            do {
                try await pp.triggerAnnounceNext()
                logs.append("✓ PP: next announcement")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppAnnouncePrevious:
            do {
                try await pp.triggerAnnouncePrevious()
                logs.append("✓ PP: previous announcement")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppAnnounceSlideIndex:
            do {
                let info = try await pp.getAnnouncementSlideIndex()
                logs.append("✓ PP: announcement slide index = \(info.slideIndex ?? -1)")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppLookTrigger:
            do {
                try await pp.triggerLookCurrent()
                logs.append("✓ PP: look triggered")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppLookTriggerById(let id):
            do {
                try await pp.triggerLook(id: id)
                logs.append("✓ PP: look \"\(id)\" triggered")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppLooksList:
            do {
                let looks = try await pp.getLooks()
                let names = looks.looks?.compactMap(\.name).joined(separator: ", ") ?? "?"
                logs.append("✓ PP: looks = \(names)")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppClearLayer(let layer):
            do {
                try await pp.clearLayer(layer)
                logs.append("✓ PP: cleared layer \"\(layer)\"")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppClearGroup(let id):
            do {
                try await pp.clearGroup(id: id)
                logs.append("✓ PP: cleared group \"\(id)\"")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppClearAll:
            do {
                try await pp.clearAll()
                logs.append("✓ PP: cleared all")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppTransportPlay:
            do {
                try await pp.transportPlay()
                logs.append("✓ PP: PLAY")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppTransportPause:
            do {
                try await pp.transportPause()
                logs.append("✓ PP: PAUSE")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppTransportStop:
            do {
                try await pp.transportStop()
                logs.append("✓ PP: STOP")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppTransportPlayPause:
            do {
                try await pp.transportPlayPause()
                logs.append("✓ PP: PLAY/PAUSE")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppStageDisplayOn:
            do {
                try await pp.stageDisplayOn()
                logs.append("✓ PP: stage display ON")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppStageDisplayOff:
            do {
                try await pp.stageDisplayOff()
                logs.append("✓ PP: stage display OFF")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppStageDisplayToggle:
            do {
                try await pp.stageDisplayToggle()
                logs.append("✓ PP: stage display TOGGLE")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppAudioTrigger(let playlistId):
            do {
                try await pp.audioTrigger(playlistId: playlistId)
                logs.append("✓ PP: audio trigger\(playlistId != nil ? " \"\(playlistId!)\"" : " (focused)")")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppAudioNext:
            do {
                try await pp.audioNext()
                logs.append("✓ PP: audio next")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppAudioPrevious:
            do {
                try await pp.audioPrevious()
                logs.append("✓ PP: audio previous")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppAudioStop:
            do {
                try await pp.audioStop()
                logs.append("✓ PP: audio stopped")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppCaptureStart:
            do {
                try await pp.captureStart()
                logs.append("✓ PP: capture started")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppCaptureStop:
            do {
                try await pp.captureStop()
                logs.append("✓ PP: capture stopped")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppCaptureStatus:
            do {
                let status = try await pp.captureStatus()
                logs.append("✓ PP: capture status = \(status.status ?? "unknown")")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppTimelineTrigger:
            do {
                try await pp.timelineTrigger()
                logs.append("✓ PP: timeline triggered")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppGroupTrigger(let groupId):
            do {
                try await pp.triggerGroup(id: groupId)
                logs.append("✓ PP: group \"\(groupId)\" triggered")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppOperationTrigger(let name):
            do {
                try await pp.triggerOperation(name: name)
                logs.append("✓ PP: operation \"\(name)\" triggered")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        case .ppFindMyMouse:
            do {
                try await pp.findMyMouse()
                logs.append("✓ PP: Find My Mouse")
            } catch {
                logs.append("✗ PP: \(error.localizedDescription)")
            }

        default:
            break
        }
    }

    // MARK: - X32

    private func executeX32Action(_ action: Action, logs: inout [String]) {
        guard let x32 = x32Client else {
            logs.append("✗ X32: not configured")
            return
        }

        switch action {
        case .x32Fader(let channel, let level):
            x32.setFader(channel: channel, level: level)
            logs.append("✓ X32: CH\(channel) fader = \(String(format: "%.0f", level * 100))%")

        case .x32FaderAdjust(let channel, let delta):
            x32.adjustFader(channel: channel, delta: delta)
            let sign = delta >= 0 ? "+" : ""
            logs.append("✓ X32: CH\(channel) fader \(sign)\(String(format: "%.0f", delta * 100))%")

        case .x32Mute(let channel, let muted):
            x32.setMute(channel: channel, muted: muted)
            logs.append("✓ X32: CH\(channel) \(muted ? "MUTED" : "UNMUTED")")

        case .x32MuteToggle(let channel):
            let muted = x32.toggleMute(target: .channel(channel ?? 1))
            logs.append("✓ X32: CH\(channel ?? 1) MUTE TOGGLE → \(muted ? "MUTED" : "UNMUTED")")

        case .x32TargetFader(let target, let level):
            x32.setFader(target: target, level: level)
            logs.append("✓ X32: \(target.displayName) fader = \(String(format: "%.0f", level * 100))%")

        case .x32TargetFaderAdjust(let target, let delta):
            x32.adjustFader(target: target, delta: delta)
            let sign = delta >= 0 ? "+" : ""
            logs.append("✓ X32: \(target.displayName) fader \(sign)\(String(format: "%.0f", delta * 100))%")

        case .x32TargetMute(let target, let muted):
            x32.setMute(target: target, muted: muted)
            logs.append("✓ X32: \(target.displayName) \(muted ? "MUTED" : "UNMUTED")")

        case .x32TargetMuteToggle(let target):
            let muted = x32.toggleMute(target: target)
            logs.append("✓ X32: \(target.displayName) MUTE TOGGLE → \(muted ? "MUTED" : "UNMUTED")")

        case .x32Recording(let start):
            x32.setRecording(start: start)
            logs.append("✓ X32: recording \(start ? "START" : "STOP")")

        case .x32Osc(let address, let value):
            x32.sendOSC(address: address, value: value)
            logs.append("✓ X32: OSC \(address) = \(value)")

        default:
            break
        }
    }

    func testConnection() async {
        guard let pp = ppClient else { return }
        do {
            _ = try await pp.getFocusedPlaylist()
            isConnectedPP = true
        } catch {
            isConnectedPP = false
        }
    }

    func testX32Connection() async {
        guard let x32 = x32Client else {
            isConnectedX32 = false
            return
        }
        isConnectedX32 = x32.testConnection()
    }
}
