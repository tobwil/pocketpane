import Foundation

public struct ToolPaths: Equatable, Sendable {
    public let adb: URL?
    public let scrcpy: URL?

    public var isReady: Bool { adb != nil && scrcpy != nil }

    public init(adb: URL?, scrcpy: URL?) {
        self.adb = adb
        self.scrcpy = scrcpy
    }
}

public enum ToolLocator {
    public static func locate(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        bundle: Bundle = .main,
        fileManager: FileManager = .default
    ) -> ToolPaths {
        var directories: [URL] = []

        if let resources = bundle.resourceURL {
            directories += [
                resources.appendingPathComponent("bin"),
                resources
            ]
        }

        directories += (environment["PATH"] ?? "")
            .split(separator: ":")
            .map { URL(fileURLWithPath: String($0), isDirectory: true) }

        directories += [
            URL(fileURLWithPath: "/opt/homebrew/bin", isDirectory: true),
            URL(fileURLWithPath: "/usr/local/bin", isDirectory: true),
            URL(fileURLWithPath: "/opt/local/bin", isDirectory: true),
            URL(fileURLWithPath: "\(NSHomeDirectory())/Library/Android/sdk/platform-tools", isDirectory: true)
        ]

        func find(_ name: String) -> URL? {
            directories
                .map { $0.appendingPathComponent(name) }
                .first { fileManager.isExecutableFile(atPath: $0.path) }
        }

        return ToolPaths(adb: find("adb"), scrcpy: find("scrcpy"))
    }
}
