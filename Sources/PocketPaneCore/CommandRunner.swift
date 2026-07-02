import Foundation

public struct CommandResult: Sendable {
    public let status: Int32
    public let output: String

    public var succeeded: Bool { status == 0 }
}

public struct DataCommandResult: Sendable {
    public let status: Int32
    public let data: Data
    public let errorOutput: String

    public var succeeded: Bool { status == 0 }
}

public enum CommandRunner {
    public static func run(_ executable: URL, arguments: [String]) async -> CommandResult {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                let pipe = Pipe()
                process.executableURL = executable
                process.arguments = arguments
                configureEnvironment(for: process, executable: executable)
                process.standardOutput = pipe
                process.standardError = pipe

                do {
                    try process.run()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    process.waitUntilExit()
                    continuation.resume(returning: CommandResult(
                        status: process.terminationStatus,
                        output: String(decoding: data, as: UTF8.self)
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                    ))
                } catch {
                    continuation.resume(returning: CommandResult(status: -1, output: error.localizedDescription))
                }
            }
        }
    }

    public static func launch(_ executable: URL, arguments: [String]) throws {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        configureEnvironment(for: process, executable: executable)
        try process.run()
    }

    public static func runData(_ executable: URL, arguments: [String]) async -> DataCommandResult {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                let outputPipe = Pipe()
                let errorPipe = Pipe()
                process.executableURL = executable
                process.arguments = arguments
                configureEnvironment(for: process, executable: executable)
                process.standardOutput = outputPipe
                process.standardError = errorPipe

                do {
                    try process.run()
                    let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    process.waitUntilExit()
                    continuation.resume(returning: DataCommandResult(
                        status: process.terminationStatus,
                        data: data,
                        errorOutput: String(decoding: errorData, as: UTF8.self)
                    ))
                } catch {
                    continuation.resume(returning: DataCommandResult(
                        status: -1,
                        data: Data(),
                        errorOutput: error.localizedDescription
                    ))
                }
            }
        }
    }

    private static func configureEnvironment(for process: Process, executable: URL) {
        let directory = executable.deletingLastPathComponent()
        process.currentDirectoryURL = directory

        let server = directory.appendingPathComponent("scrcpy-server")
        if FileManager.default.fileExists(atPath: server.path) {
            var environment = ProcessInfo.processInfo.environment
            environment["SCRCPY_SERVER_PATH"] = server.path
            process.environment = environment
        }
    }
}
