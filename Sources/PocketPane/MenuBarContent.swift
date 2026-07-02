import AppKit
import SwiftUI

struct MenuBarContent: View {
    @EnvironmentObject private var model: MirrorModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        if let device = model.selectedDevice {
            Text(device.displayName)
            if let endpoint = model.connectionEndpoint(for: device) {
                Text(endpoint)
            }
            Divider()
            Button("Start Mirroring") { model.mirror() }
            Button("Open Android App…") {
                showMainWindow()
                model.presentAppLauncher()
            }
            Button("Save Screenshot…") {
                Task { await model.saveScreenshot() }
            }
            Button("Record Presentation…") {
                model.recordPresentation()
            }
        } else {
            Text("No Pixel nearby")
            Button("Refresh") {
                Task { await model.refresh() }
            }
        }

        Divider()
        Button("Open PocketPane") { showMainWindow() }
        Button("Quit PocketPane") {
            NSApplication.shared.terminate(nil)
        }
    }

    private func showMainWindow() {
        openWindow(id: "main")
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
