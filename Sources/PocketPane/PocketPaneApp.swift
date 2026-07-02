import SwiftUI

@main
struct PocketPaneApp: App {
    @StateObject private var model = MirrorModel()

    var body: some Scene {
        WindowGroup("PocketPane", id: "main") {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 820, minHeight: 660)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Device") {
                Button("Refresh Devices") {
                    Task { await model.refresh() }
                }
                .keyboardShortcut("r")
                Button("Open Android App…") {
                    model.presentAppLauncher()
                }
                .keyboardShortcut("k")
                Divider()
                Button("Save Screenshot…") {
                    Task { await model.saveScreenshot() }
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }

        MenuBarExtra {
            MenuBarContent()
                .environmentObject(model)
        } label: {
            Image(systemName: model.selectedDevice == nil ? "iphone.slash" : "iphone")
                .accessibilityLabel("PocketPane")
        }
        .menuBarExtraStyle(.menu)
    }
}
