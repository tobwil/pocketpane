import Foundation

public struct MDNSService: Identifiable, Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case pairing
        case connection
        case legacy
        case other(String)
    }

    public let name: String
    public let type: String
    public let endpoint: String
    public let kind: Kind

    public var id: String { "\(name)|\(type)|\(endpoint)" }

    public init(name: String, type: String, endpoint: String, kind: Kind) {
        self.name = name
        self.type = type
        self.endpoint = endpoint
        self.kind = kind
    }
}
