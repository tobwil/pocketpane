import Foundation

public enum Endpoint {
    public static func normalized(_ input: String, defaultPort: Int? = nil) -> String? {
        var value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, !value.contains(where: \.isWhitespace) else { return nil }

        if value.hasPrefix("[") {
            guard let closing = value.firstIndex(of: "]") else { return nil }
            let host = value[value.index(after: value.startIndex)..<closing]
            guard !host.isEmpty else { return nil }
            let suffix = value[value.index(after: closing)...]
            if suffix.isEmpty, let defaultPort { return "[\(host)]:\(defaultPort)" }
            guard suffix.first == ":", validPort(String(suffix.dropFirst())) else { return nil }
            return value
        }

        let colonCount = value.filter { $0 == ":" }.count
        if colonCount == 0 {
            guard let defaultPort else { return nil }
            value += ":\(defaultPort)"
        } else if colonCount == 1 {
            let pieces = value.split(separator: ":", omittingEmptySubsequences: false)
            guard pieces.count == 2, !pieces[0].isEmpty, validPort(String(pieces[1])) else { return nil }
        } else {
            // A bare IPv6 address needs brackets before a port can safely be added.
            guard let defaultPort else { return nil }
            value = "[\(value)]:\(defaultPort)"
        }
        return value
    }

    private static func validPort(_ value: String) -> Bool {
        guard let port = Int(value) else { return false }
        return (1...65535).contains(port)
    }
}
