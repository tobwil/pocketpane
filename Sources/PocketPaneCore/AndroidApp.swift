import Foundation

public struct AndroidApp: Identifiable, Equatable, Sendable {
    public let name: String
    public let packageName: String
    public let isSystem: Bool

    public var id: String { packageName }

    public init(name: String, packageName: String, isSystem: Bool) {
        self.name = name
        self.packageName = packageName
        self.isSystem = isSystem
    }
}
