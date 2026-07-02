import Foundation

public enum ADBParser {
    public static func devices(from output: String) -> [AndroidDevice] {
        output
            .split(whereSeparator: \.isNewline)
            .drop(while: { $0.hasPrefix("List of devices") || $0.hasPrefix("* daemon") })
            .compactMap(parseDevice)
    }

    public static func ipAddress(fromRoute output: String) -> String? {
        let fields = output.split(whereSeparator: \.isWhitespace).map(String.init)
        if let sourceIndex = fields.firstIndex(of: "src"), fields.indices.contains(sourceIndex + 1) {
            return fields[sourceIndex + 1]
        }

        return fields.first { field in
            let octets = field.split(separator: ".")
            return octets.count == 4 && octets.allSatisfy { (0...255).contains(Int($0) ?? -1) }
        }
    }

    public static func mdnsServices(from output: String) -> [MDNSService] {
        output
            .split(whereSeparator: \.isNewline)
            .drop(while: { $0.hasPrefix("List of discovered") })
            .compactMap { line in
                let fields = line.split(whereSeparator: \.isWhitespace).map(String.init)
                guard fields.count >= 3, Endpoint.normalized(fields[2]) != nil else { return nil }

                let kind: MDNSService.Kind = switch fields[1] {
                case let type where type.hasPrefix("_adb-tls-pairing._tcp"): .pairing
                case let type where type.hasPrefix("_adb-tls-connect._tcp"): .connection
                case let type where type.hasPrefix("_adb._tcp"): .legacy
                default: .other(fields[1])
                }

                return MDNSService(name: fields[0], type: fields[1], endpoint: fields[2], kind: kind)
            }
    }

    public static func apps(fromScrcpyOutput output: String) -> [AndroidApp] {
        var apps: [AndroidApp] = []
        var pendingName: String?
        var pendingSystem = false

        for rawLine in output.split(whereSeparator: \.isNewline).map(String.init) {
            guard !rawLine.hasPrefix("[server]"),
                  !rawLine.contains("file pushed"),
                  !rawLine.hasPrefix("INFO:") else { continue }

            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            let markedSystem = trimmed.hasPrefix("* ")
            let markedThirdParty = trimmed.hasPrefix("- ")
            let content = (markedSystem || markedThirdParty)
                ? String(trimmed.dropFirst(2))
                : trimmed

            let columns = content
                .components(separatedBy: .init(charactersIn: " \t"))
                .filter { !$0.isEmpty }

            guard let package = columns.last, package.contains(".") else {
                if markedSystem || markedThirdParty {
                    pendingName = content
                    pendingSystem = markedSystem
                }
                continue
            }

            let isPackageOnlyContinuation = !markedSystem && !markedThirdParty && columns.count == 1
            let name: String
            let isSystem: Bool
            if isPackageOnlyContinuation, let pendingName {
                name = pendingName
                isSystem = pendingSystem
            } else {
                let packageRange = content.range(of: package, options: .backwards)
                name = packageRange
                    .map { content[..<$0.lowerBound].trimmingCharacters(in: .whitespaces) }
                    .flatMap { $0.isEmpty ? nil : $0 } ?? package
                isSystem = markedSystem
            }

            apps.append(AndroidApp(name: name, packageName: package, isSystem: isSystem))
            pendingName = nil
        }

        return apps.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private static func parseDevice(_ line: Substring) -> AndroidDevice? {
        let fields = line.split(whereSeparator: \.isWhitespace).map(String.init)
        guard fields.count >= 2 else { return nil }

        let attributes = Dictionary(
            uniqueKeysWithValues: fields.dropFirst(2).compactMap { field -> (String, String)? in
                let pieces = field.split(separator: ":", maxSplits: 1).map(String.init)
                return pieces.count == 2 ? (pieces[0], pieces[1]) : nil
            }
        )

        return AndroidDevice(
            serial: fields[0],
            state: AndroidDevice.State(rawValue: fields[1]) ?? .unknown,
            model: attributes["model"],
            product: attributes["product"]
        )
    }
}
