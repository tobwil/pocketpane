import Foundation

public struct AndroidDevice: Identifiable, Equatable, Sendable {
    public enum State: String, Sendable {
        case device
        case offline
        case unauthorized
        case unknown
    }

    public let serial: String
    public let state: State
    public let model: String?
    public let product: String?

    public var id: String { serial }
    public var isMDNSWireless: Bool {
        serial.localizedCaseInsensitiveContains("._adb-tls-connect._tcp")
    }
    public var isDirectTCP: Bool { serial.contains(":") }
    public var isWireless: Bool { isDirectTCP || isMDNSWireless }
    public var displayName: String {
        model?.replacingOccurrences(of: "_", with: " ") ?? serial
    }

    public init(serial: String, state: State, model: String? = nil, product: String? = nil) {
        self.serial = serial
        self.state = state
        self.model = model
        self.product = product
    }
}
