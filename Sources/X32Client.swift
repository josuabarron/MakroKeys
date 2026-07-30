import Foundation
import Darwin

// MARK: - X32 OSC Client

class X32Client {
    let host: String
    let port: Int

    init(host: String, port: Int) {
        self.host = host
        self.port = port
    }

    /// Send an OSC float message to the X32
    func sendFloat(_ address: String, value: Float) {
        let msg = buildOSC(address: address, value: .float(value))
        send(msg)
    }

    /// Send an OSC int message to the X32
    func sendInt(_ address: String, value: Int32) {
        let msg = buildOSC(address: address, value: .int(value))
        send(msg)
    }

    /// Generic OSC send with a double value (sent as float)
    func sendOSC(address: String, value: Double) {
        sendFloat(address, value: Float(value))
    }

    func testConnection(timeout: TimeInterval = 1.0) -> Bool {
        let msg = buildOSC(address: "/xinfo")
        return sendAndWaitForResponse(msg, timeout: timeout)
    }

    // ── Module-level fader state (X32 has no echo back) ──
    private(set) var faderLevel: Double = 0.75
    private(set) var isMuted: Bool = false
    private var faderLevelsByAddress: [String: Double] = [:]
    private var muteStatesByAddress: [String: Bool] = [:]

    func adjustFader(channel: Int, delta: Double) {
        adjustFader(target: .channel(channel), delta: delta)
    }

    func setFader(channel: Int, level: Double) {
        setFader(target: .channel(channel), level: level)
    }

    func setMute(channel: Int, muted: Bool) {
        setMute(target: .channel(channel), muted: muted)
    }

    func toggleMute(channel: Int?) {
        toggleMute(target: .channel(channel ?? 1))
    }

    func adjustFader(target: X32Target, delta: Double) {
        let address = target.faderAddress
        let currentLevel = faderLevelsByAddress[address] ?? faderLevel
        let level = max(0, min(1, currentLevel + delta))
        setFader(target: target, level: level)
    }

    func setFader(target: X32Target, level: Double) {
        let clippedLevel = max(0, min(1, level))
        let address = target.faderAddress
        faderLevelsByAddress[address] = clippedLevel
        faderLevel = clippedLevel
        sendFloat(address, value: Float(clippedLevel))
    }

    func setMute(target: X32Target, muted: Bool) {
        let address = target.onAddress
        muteStatesByAddress[address] = muted
        isMuted = muted
        sendInt(address, value: muted ? 0 : 1)
    }

    @discardableResult
    func toggleMute(target: X32Target) -> Bool {
        let address = target.onAddress
        let muted = !(muteStatesByAddress[address] ?? isMuted)
        setMute(target: target, muted: muted)
        return muted
    }

    func setRecording(start: Bool) {
        // Tape state: 0=stop, 1=pause, 2=play, 3=pause record, 4=record, 5=ff, 6=rew
        sendInt("/-stat/tape/state", value: start ? 4 : 0)
    }

    // MARK: - Private

    private enum OSCValue {
        case float(Float)
        case int(Int32)
    }

    private func buildOSC(address: String) -> Data {
        var addrBytes = address.withCString { Data(bytes: $0, count: strlen($0) + 1) }
        let addrPad = (4 - addrBytes.count % 4) % 4
        addrBytes.append(contentsOf: [UInt8](repeating: 0, count: addrPad))

        var tag = Data([0x2C, 0x00])
        let tagPad = (4 - tag.count % 4) % 4
        tag.append(contentsOf: [UInt8](repeating: 0, count: tagPad))

        return addrBytes + tag
    }

    private func buildOSC(address: String, value: OSCValue) -> Data {
        // OSC address → null-terminated + 4-byte aligned
        var addrBytes = address.withCString { Data(bytes: $0, count: strlen($0) + 1) }
        let addrPad = (4 - addrBytes.count % 4) % 4
        addrBytes.append(contentsOf: [UInt8](repeating: 0, count: addrPad))

        // Type tag ",f" or ",i" + 4-byte aligned
        let tag: Data
        switch value {
        case .float:  tag = Data([0x2C, 0x66, 0x00, 0x00])   // ",f\0\0"
        case .int:    tag = Data([0x2C, 0x69, 0x00, 0x00])   // ",i\0\0"
        }

        // Argument
        var argData: Data
        switch value {
        case .float(let f):
            var bits = f.bitPattern.bigEndian
            argData = Data(bytes: &bits, count: 4)
        case .int(let i):
            var bits = i.bigEndian
            argData = Data(bytes: &bits, count: 4)
        }

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
        defer { close(sock) }
        data.withUnsafeBytes { ptr in
            guard let baseAddress = ptr.baseAddress else { return }
            _ = sendto(sock, baseAddress, data.count, 0, addrInfo.pointee.ai_addr, addrInfo.pointee.ai_addrlen)
        }
    }

    private func sendAndWaitForResponse(_ data: Data, timeout: TimeInterval) -> Bool {
        var hints = addrinfo()
        hints.ai_family = AF_INET
        hints.ai_socktype = SOCK_DGRAM
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

        var receiveTimeout = timeval(
            tv_sec: Int(timeout),
            tv_usec: suseconds_t((timeout - floor(timeout)) * 1_000_000)
        )
        setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &receiveTimeout, socklen_t(MemoryLayout<timeval>.size))

        let sent: ssize_t = data.withUnsafeBytes { ptr in
            guard let baseAddress = ptr.baseAddress else { return -1 }
            return sendto(sock, baseAddress, data.count, 0, addrInfo.pointee.ai_addr, addrInfo.pointee.ai_addrlen)
        }
        guard sent > 0 else { return false }

        var buffer = [UInt8](repeating: 0, count: 1024)
        let received = recv(sock, &buffer, buffer.count, 0)
        return received > 0
    }
}
