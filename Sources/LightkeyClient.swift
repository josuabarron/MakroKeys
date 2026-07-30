import Foundation
import Darwin

// MARK: - Lightkey OSC Client

final class LightkeyClient {
    enum CueCommand: String {
        case toggle
        case activate
        case deactivate
    }

    let host: String
    let port: Int

    init(host: String, port: Int) {
        self.host = host
        self.port = port
    }

    func sendCueCommand(address: String, command: CueCommand, fadeTime: Double) {
        let commandAddress = addressWithCommand(address, command: command)
        sendFloat(commandAddress, value: Float(max(0, fadeTime)))
    }

    func sendOSC(address: String, value: Double) {
        sendFloat(address, value: Float(value))
    }

    func testConnection(timeout: TimeInterval = 1.0) -> Bool {
        var hints = addrinfo()
        hints.ai_family = AF_INET
        hints.ai_socktype = SOCK_STREAM
        var result: UnsafeMutablePointer<addrinfo>?
        let status = host.withCString { hostPtr in
            String(port).withCString { portPtr in
                getaddrinfo(hostPtr, portPtr, &hints, &result)
            }
        }
        guard status == 0, let addrInfo = result else { return false }
        defer { freeaddrinfo(result) }

        let sock = socket(addrInfo.pointee.ai_family, addrInfo.pointee.ai_socktype, addrInfo.pointee.ai_protocol)
        guard sock >= 0 else { return false }
        defer { close(sock) }

        let flags = fcntl(sock, F_GETFL, 0)
        guard flags >= 0 else { return false }
        _ = fcntl(sock, F_SETFL, flags | O_NONBLOCK)

        let connectStatus = connect(sock, addrInfo.pointee.ai_addr, addrInfo.pointee.ai_addrlen)
        if connectStatus == 0 { return true }
        guard errno == EINPROGRESS else { return false }

        var pollInfo = pollfd(fd: sock, events: Int16(POLLOUT), revents: 0)
        let pollStatus = poll(&pollInfo, 1, Int32(timeout * 1000))
        guard pollStatus > 0 else { return false }

        var socketError: Int32 = 0
        var socketErrorLength = socklen_t(MemoryLayout<Int32>.size)
        guard getsockopt(sock, SOL_SOCKET, SO_ERROR, &socketError, &socketErrorLength) == 0 else {
            return false
        }

        return socketError == 0
    }

    private func addressWithCommand(_ address: String, command: CueCommand) -> String {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.isEmpty ? "/live/My_Control_Panel/cue/My_Cue_Name" : trimmed
        let commandSuffixes = ["/toggle", "/activate", "/deactivate"]

        for suffix in commandSuffixes where base.hasSuffix(suffix) {
            return String(base.dropLast(suffix.count)) + "/\(command.rawValue)"
        }

        return base.hasSuffix("/") ? base + command.rawValue : base + "/\(command.rawValue)"
    }

    private func sendFloat(_ address: String, value: Float) {
        let msg = buildOSC(address: normalizedAddress(address), value: value)
        send(msg)
    }

    private func normalizedAddress(_ address: String) -> String {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "/live/My_Control_Panel/cue/My_Cue_Name/toggle" }
        return trimmed.hasPrefix("/") ? trimmed : "/" + trimmed
    }

    private func buildOSC(address: String, value: Float) -> Data {
        var addrBytes = address.withCString { Data(bytes: $0, count: strlen($0) + 1) }
        let addrPad = (4 - addrBytes.count % 4) % 4
        addrBytes.append(contentsOf: [UInt8](repeating: 0, count: addrPad))

        let tag = Data([0x2C, 0x66, 0x00, 0x00])
        var bits = value.bitPattern.bigEndian
        let argData = Data(bytes: &bits, count: 4)

        return addrBytes + tag + argData
    }

    private func send(_ data: Data) {
        var hints = addrinfo()
        hints.ai_family = AF_INET
        hints.ai_socktype = SOCK_DGRAM
        var result: UnsafeMutablePointer<addrinfo>?
        let status = host.withCString { hostPtr in
            String(port).withCString { portPtr in
                getaddrinfo(hostPtr, portPtr, &hints, &result)
            }
        }
        guard status == 0, let addrInfo = result else { return }
        defer { freeaddrinfo(result) }

        let sock = socket(addrInfo.pointee.ai_family, addrInfo.pointee.ai_socktype, addrInfo.pointee.ai_protocol)
        guard sock >= 0 else { return }
        defer { close(sock) }

        data.withUnsafeBytes { ptr in
            guard let baseAddress = ptr.baseAddress else { return }
            _ = sendto(sock, baseAddress, data.count, 0, addrInfo.pointee.ai_addr, addrInfo.pointee.ai_addrlen)
        }
    }
}
