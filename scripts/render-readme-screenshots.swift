import AppKit
import PocketPaneCore
import SwiftUI

@main
struct ReadmeScreenshotRenderer {
    @MainActor
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            throw ScreenshotError.missingOutputDirectory
        }

        let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: true
        )

        try renderDashboard(
            dark: true,
            to: outputDirectory.appendingPathComponent("pocketpane-dark.png")
        )
        try renderDashboard(
            dark: false,
            to: outputDirectory.appendingPathComponent("pocketpane-light.png")
        )
        try renderAppLauncher(
            to: outputDirectory.appendingPathComponent("pocketpane-app-launcher.png")
        )
    }

    @MainActor
    private static func renderDashboard(dark: Bool, to destination: URL) throws {
        UserDefaults.standard.set(dark, forKey: "isDarkMode")
        let model = MirrorModel(preview: true)
        let view = ContentView()
            .environmentObject(model)
            .frame(width: 1000, height: 760)
        try render(view, size: CGSize(width: 1000, height: 760), to: destination)
    }

    @MainActor
    private static func renderAppLauncher(to destination: URL) throws {
        let model = MirrorModel(preview: true)
        let view = AppLauncherView()
            .environmentObject(model)
            .preferredColorScheme(.dark)
        try render(view, size: CGSize(width: 560, height: 620), to: destination)
    }

    @MainActor
    private static func render<Content: View>(
        _ content: Content,
        size: CGSize,
        to destination: URL
    ) throws {
        let hostingView = NSHostingView(rootView: content)
        hostingView.frame = NSRect(origin: .zero, size: size)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.setFrameOrigin(NSPoint(x: -10_000, y: -10_000))
        window.orderFrontRegardless()
        RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        hostingView.layoutSubtreeIfNeeded()

        guard let representation = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            throw ScreenshotError.renderFailed(destination.lastPathComponent)
        }
        representation.size = size
        hostingView.cacheDisplay(in: hostingView.bounds, to: representation)
        guard let png = representation.representation(using: .png, properties: [:]) else {
            throw ScreenshotError.encodingFailed(destination.lastPathComponent)
        }
        try png.write(to: destination, options: .atomic)
        window.orderOut(nil)
    }
}

private enum ScreenshotError: LocalizedError {
    case missingOutputDirectory
    case renderFailed(String)
    case encodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingOutputDirectory:
            "Pass an output directory."
        case .renderFailed(let name):
            "Could not render \(name)."
        case .encodingFailed(let name):
            "Could not encode \(name)."
        }
    }
}
