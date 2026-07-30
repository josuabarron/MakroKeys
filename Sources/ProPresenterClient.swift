import Foundation

// MARK: - ProPresenter API Client

class ProPresenterClient {
    let host: String
    let port: Int

    init(host: String, port: Int) {
        self.host = host
        self.port = port
    }

    // MARK: - Low-level

    private func sendGET(_ path: String) async throws -> Data {
        var components = URLComponents()
        components.scheme = "http"
        components.host = host
        components.port = port
        components.percentEncodedPath = path

        guard let url = components.url else {
            throw NSError(
                domain: "ProPresenter",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid ProPresenter URL"]
            )
        }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = 4
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode < 300 else {
            throw NSError(domain: "ProPresenter", code: -1, userInfo: [NSLocalizedDescriptionKey: "HTTP error"])
        }
        return data
    }

    private func getJSON<T: Decodable>(_ path: String) async throws -> T {
        let data = try await sendGET(path)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func path(_ components: String...) -> String {
        "/" + components.map(encodedPathComponent).joined(separator: "/")
    }

    private func encodedPathComponent(_ value: String) -> String {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/?#")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
    }

    // MARK: - Playlist

    func getFocusedPlaylist() async throws -> FocusedPlaylistResponse {
        try await getJSON("/v1/playlist/focused")
    }

    func getPlaylist(uuid: String) async throws -> PlaylistResponse {
        try await getJSON(path("v1", "playlist", uuid))
    }

    func triggerPresentation(presentationIndex: Int, slideIndex: Int) async throws {
        _ = try await sendGET("/v1/playlist/focused/\(presentationIndex)/\(slideIndex)/trigger")
    }

    func triggerNextSlide() async throws {
        _ = try await sendGET("/v1/presentation/active/next/trigger")
    }

    func triggerPreviousSlide() async throws {
        _ = try await sendGET("/v1/presentation/active/previous/trigger")
    }

    func triggerNextPresentation() async throws {
        _ = try await sendGET("/v1/playlist/focused/next/trigger")
    }

    func triggerPreviousPresentation() async throws {
        _ = try await sendGET("/v1/playlist/focused/previous/trigger")
    }

    func triggerLastInPlaylist() async throws {
        let focused = try await getFocusedPlaylist()
        guard let playlistUUID = focused.playlist?.uuid else { return }
        let playlist = try await getPlaylist(uuid: playlistUUID)

        var lastPresIndex = -1
        for item in playlist.items ?? [] {
            if item.type == "presentation" {
                lastPresIndex = item.id.index
            }
        }
        guard lastPresIndex >= 0 else { return }
        _ = try await sendGET("/v1/playlist/focused/\(lastPresIndex)/0/trigger")
    }

    // MARK: - Announcement

    func getAnnouncementActive() async throws -> AnnounceActiveResponse {
        try await getJSON("/v1/announcement/active")
    }

    func triggerAnnounceCurrent() async throws {
        _ = try await sendGET("/v1/announcement/active/trigger")
    }

    func triggerAnnounceAt(index: Int) async throws {
        _ = try await sendGET("/v1/announcement/active/\(index)/trigger")
    }

    func triggerAnnounceNext() async throws {
        _ = try await sendGET("/v1/announcement/active/next/trigger")
    }

    func triggerAnnouncePrevious() async throws {
        _ = try await sendGET("/v1/announcement/active/previous/trigger")
    }

    func getAnnouncementSlideIndex() async throws -> AnnounceSlideIndexResponse {
        try await getJSON("/v1/announcement/slide_index")
    }

    // MARK: - Looks

    func getLooks() async throws -> LooksResponse {
        try await getJSON("/v1/looks")
    }

    func triggerLookCurrent() async throws {
        _ = try await sendGET("/v1/look/trigger")
    }

    func triggerLook(id: String) async throws {
        _ = try await sendGET(path("v1", "look", id, "trigger"))
    }

    // MARK: - Clear

    func clearLayer(_ layer: String) async throws {
        _ = try await sendGET(path("v1", "clear", "layer", layer))
    }

    func clearGroup(id: String) async throws {
        _ = try await sendGET(path("v1", "clear", "group", id, "trigger"))
    }

    func clearAll() async throws {
        _ = try await sendGET("/v1/clear/layer/all")
    }

    func getClearGroups() async throws -> ClearGroupsResponse {
        try await getJSON("/v1/clear/groups")
    }

    // MARK: - Transport

    func transportPlay() async throws {
        _ = try await sendGET("/v1/transport/play")
    }

    func transportPause() async throws {
        _ = try await sendGET("/v1/transport/pause")
    }

    func transportStop() async throws {
        _ = try await sendGET("/v1/transport/stop")
    }

    func transportPlayPause() async throws {
        _ = try await sendGET("/v1/transport/playpause")
    }

    // MARK: - Stage

    func stageDisplayOn() async throws {
        _ = try await sendGET("/v1/stage/display/on")
    }

    func stageDisplayOff() async throws {
        _ = try await sendGET("/v1/stage/display/off")
    }

    func stageDisplayToggle() async throws {
        _ = try await sendGET("/v1/stage/display/toggle")
    }

    // MARK: - Audio

    func audioTrigger(playlistId: String?) async throws {
        let path = playlistId != nil
            ? path("v1", "audio", "playlist", playlistId!, "trigger")
            : "/v1/audio/playlist/focused/trigger"
        _ = try await sendGET(path)
    }

    func audioNext() async throws {
        _ = try await sendGET("/v1/audio/playlist/focused/next/trigger")
    }

    func audioPrevious() async throws {
        _ = try await sendGET("/v1/audio/playlist/focused/previous/trigger")
    }

    func audioStop() async throws {
        _ = try await sendGET("/v1/audio/playlist/focused/trigger")
        // Fallback: send stop via transport
        try? await transportStop()
    }

    // MARK: - Capture

    func captureStart() async throws {
        _ = try await sendGET("/v1/capture/start")
    }

    func captureStop() async throws {
        _ = try await sendGET("/v1/capture/stop")
    }

    func captureStatus() async throws -> CaptureStatusResponse {
        try await getJSON("/v1/capture/status")
    }

    // MARK: - Timeline

    func timelineTrigger() async throws {
        _ = try await sendGET("/v1/timeline/trigger")
    }

    // MARK: - Groups

    func getGroups() async throws -> GroupsResponse {
        try await getJSON("/v1/groups")
    }

    func triggerGroup(id: String) async throws {
        _ = try await sendGET(path("v1", "group", id, "trigger"))
    }

    // MARK: - Operations

    func triggerOperation(name: String) async throws {
        _ = try await sendGET(path("v1", "operations", name, "trigger"))
    }

    // MARK: - Misc

    func findMyMouse() async throws {
        _ = try await sendGET("/v1/find_my_mouse")
    }
}

// MARK: - Response Models

struct FocusedPlaylistResponse: Codable {
    var playlist: PlaylistInfo?
}

struct PlaylistResponse: Codable {
    var items: [PlaylistItem]?
}

struct PlaylistInfo: Codable {
    var name: String
    var uuid: String
}

struct PlaylistItem: Codable {
    var id: PresentationId
    var type: String
}

struct PresentationId: Codable {
    var index: Int
}

struct AnnounceActiveResponse: Codable {
    var announcement: AnnounceInfo?
    var index: Int?
}

struct AnnounceInfo: Codable {
    var name: String?
    var id: String?
}

struct AnnounceSlideIndexResponse: Codable {
    var slideIndex: Int?
}

struct LooksResponse: Codable {
    var looks: [LookInfo]?
}

struct LookInfo: Codable {
    var id: String?
    var name: String?
}

struct ClearGroupsResponse: Codable {
    var groups: [ClearGroupInfo]?
}

struct ClearGroupInfo: Codable {
    var id: String?
    var name: String?
}

struct CaptureStatusResponse: Codable {
    var isCapturing: Bool?
    var status: String?
}

struct GroupsResponse: Codable {
    var groups: [GroupInfo]?
}

struct GroupInfo: Codable {
    var id: String?
    var name: String?
}
