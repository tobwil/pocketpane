import AppKit
import PocketPaneCore
import Foundation
import UniformTypeIdentifiers

@MainActor
final class MirrorModel: ObservableObject {
    @Published var tools = ToolLocator.locate()
    @Published var devices: [AndroidDevice] = []
    @Published var nearbyServices: [MDNSService] = []
    @Published var selectedSerial: String?
    @Published var pairAddress = ""
    @Published var pairCode = ""
    @Published var connectAddress = ""
    @Published var status = "Checking your Mac…"
    @Published var isWorking = false
    @Published var showAdvanced = false
    @Published var maxSize = "1920"
    @Published var maxFPS = "60"
    @Published var turnScreenOff = false
    @Published var stayAwake = true
    @Published var noAudio = false
    @Published var showTouches = false
    @Published var borderlessWindow = false
    @Published var apps: [AndroidApp] = []
    @Published var isLoadingApps = false
    @Published var showAppLauncher = false

    private let defaults = UserDefaults.standard

    init(preview: Bool = false) {
        connectAddress = defaults.string(forKey: "lastConnectAddress") ?? ""
        if preview {
            let serviceName = "adb-DEMO123456-PocketPane"
            let serviceSerial = "\(serviceName)._adb-tls-connect._tcp"
            devices = [
                AndroidDevice(
                    serial: serviceSerial,
                    state: .device,
                    model: "Pixel_10_Pro",
                    product: "blazer"
                )
            ]
            nearbyServices = [
                MDNSService(
                    name: serviceName,
                    type: "_adb-tls-connect._tcp",
                    endpoint: "192.0.2.42:41335",
                    kind: .connection
                )
            ]
            selectedSerial = serviceSerial
            status = "Pixel 10 Pro is nearby and ready."
            apps = [
                AndroidApp(name: "WhatsApp", packageName: "com.whatsapp", isSystem: false),
                AndroidApp(name: "Kamera", packageName: "com.google.android.GoogleCamera", isSystem: true),
                AndroidApp(name: "Home", packageName: "com.google.android.apps.chromecast.app", isSystem: false),
                AndroidApp(name: "ChatGPT", packageName: "com.openai.chatgpt", isSystem: false)
            ]
        } else {
            Task { await refresh() }
        }
    }

    var selectedDevice: AndroidDevice? {
        devices.first { $0.serial == selectedSerial }
    }

    func connectionEndpoint(for device: AndroidDevice) -> String? {
        if device.isDirectTCP { return device.serial }
        return nearbyServices.first {
            $0.kind == .connection && device.serial.hasPrefix($0.name)
        }?.endpoint
    }

    var installCommand: String {
        "brew install scrcpy && brew install --cask android-platform-tools"
    }

    func refresh() async {
        tools = ToolLocator.locate()
        guard let adb = tools.adb else {
            devices = []
            status = "Android Platform Tools are not installed."
            return
        }

        isWorking = true
        let discovery = await CommandRunner.run(adb, arguments: ["mdns", "services"])
        nearbyServices = ADBParser.mdnsServices(from: discovery.output)

        if let pairing = nearbyServices.first(where: { $0.kind == .pairing }) {
            pairAddress = pairing.endpoint
        }

        let result = await CommandRunner.run(adb, arguments: ["devices", "-l"])
        let discoveredDevices = ADBParser.devices(from: result.output)
        let mdnsDevices = discoveredDevices.filter(\.isMDNSWireless)
        devices = discoveredDevices.filter { device in
            guard device.isDirectTCP else { return true }
            return !mdnsDevices.contains {
                $0.model == device.model && $0.product == device.product
            }
        }
        if selectedSerial == nil || !devices.contains(where: { $0.serial == selectedSerial }) {
            selectedSerial = devices.first(where: { $0.state == .device })?.serial
        }
        if !devices.isEmpty {
            status = "\(devices.count) device\(devices.count == 1 ? "" : "s") found."
        } else if nearbyServices.contains(where: { $0.kind == .pairing }) {
            status = "Pixel found nearby. Enter the 6-digit code to pair."
        } else {
            status = "No devices yet. Turn on Wireless debugging on your Pixel."
        }
        isWorking = false
    }

    func findPairingAddress() async {
        guard let adb = tools.adb else { return }
        isWorking = true
        status = "Looking for the Pixel pairing dialog…"

        let discovery = await CommandRunner.run(adb, arguments: ["mdns", "services"])
        nearbyServices = ADBParser.mdnsServices(from: discovery.output)

        if let pairing = nearbyServices.first(where: { $0.kind == .pairing }) {
            pairAddress = pairing.endpoint
            status = "Pairing address found. Enter the current 6-digit code."
        } else {
            status = "Not found. Keep “Pair device with pairing code” open, or enter its address manually."
        }
        isWorking = false
    }

    func pair() async {
        guard let adb = tools.adb else { return }
        guard let endpoint = Endpoint.normalized(pairAddress) else {
            status = "Enter the pairing IP and port shown on your Pixel."
            return
        }
        let code = pairCode.filter(\.isNumber)
        guard code.count == 6 else {
            status = "The pairing code should contain 6 digits."
            return
        }

        isWorking = true
        status = "Pairing with \(endpoint)…"
        let result = await runConnectionCommand(adb, arguments: ["pair", endpoint, code])
        guard result.succeeded else {
            status = result.output.isEmpty
                ? "Pairing failed. Check the current address, port, and code."
                : result.output
            isWorking = false
            return
        }

        pairCode = ""
        pairAddress = ""
        status = "Paired. Looking for the connection service…"

        try? await Task.sleep(for: .milliseconds(700))
        let discovery = await CommandRunner.run(adb, arguments: ["mdns", "services"])
        nearbyServices = ADBParser.mdnsServices(from: discovery.output)

        if let connection = nearbyServices.first(where: { $0.kind == .connection }) {
            connectAddress = connection.endpoint
            defaults.set(connection.endpoint, forKey: "lastConnectAddress")
            let connected = await runConnectionCommand(adb, arguments: ["connect", connection.endpoint])
            status = connected.succeeded ? "Paired and connected." : "Paired. Tap Connect if it does not appear."
        } else {
            status = "Paired. Close the pairing dialog, then tap Refresh."
        }

        isWorking = false
        let pairingStatus = status
        await refresh()
        status = pairingStatus
    }

    func connect() async {
        guard let adb = tools.adb else { return }
        guard let endpoint = Endpoint.normalized(connectAddress, defaultPort: 5555) else {
            status = "Enter the Wireless debugging IP address and port."
            return
        }

        isWorking = true
        let result = await runConnectionCommand(adb, arguments: ["connect", endpoint])
        status = result.output.isEmpty ? (result.succeeded ? "Connected." : "Connection failed.") : result.output
        if result.succeeded {
            connectAddress = endpoint
            defaults.set(endpoint, forKey: "lastConnectAddress")
        }
        isWorking = false
        await refresh()
    }

    func prepareUSBWireless() async {
        guard let adb = tools.adb else { return }
        isWorking = true
        status = "Reading your Pixel’s Wi‑Fi address…"
        let route = await CommandRunner.run(adb, arguments: ["-d", "shell", "ip", "route"])
        guard route.succeeded, let ip = ADBParser.ipAddress(fromRoute: route.output) else {
            status = "Connect one authorized phone by USB and make sure it is on Wi‑Fi."
            isWorking = false
            return
        }

        status = "Switching ADB to Wi‑Fi…"
        let tcpip = await CommandRunner.run(adb, arguments: ["-d", "tcpip", "5555"])
        guard tcpip.succeeded else {
            status = tcpip.output.isEmpty ? "Could not enable ADB over Wi‑Fi." : tcpip.output
            isWorking = false
            return
        }

        let endpoint = "\(ip):5555"
        let connection = await CommandRunner.run(adb, arguments: ["connect", endpoint])
        status = connection.output.isEmpty
            ? (connection.succeeded ? "Connected wirelessly. You can unplug the cable." : "Wi‑Fi connection failed.")
            : connection.output
        if connection.succeeded {
            connectAddress = endpoint
            defaults.set(endpoint, forKey: "lastConnectAddress")
        }
        isWorking = false
        await refresh()
    }

    func mirror() {
        guard let scrcpy = tools.scrcpy, let device = selectedDevice else { return }
        guard device.state == .device else {
            status = device.state == .unauthorized
                ? "Unlock your Pixel and allow USB debugging."
                : "This device is not ready."
            return
        }

        do {
            try CommandRunner.launch(scrcpy, arguments: mirrorArguments(for: device))
            status = "Mirroring \(device.displayName)."
        } catch {
            status = "Could not start scrcpy: \(error.localizedDescription)"
        }
    }

    func disconnectSelected() async {
        guard let adb = tools.adb, let device = selectedDevice else { return }
        let target = connectionEndpoint(for: device) ?? device.serial
        isWorking = true
        let result = await CommandRunner.run(adb, arguments: ["disconnect", target])
        status = result.output.isEmpty ? "Disconnected." : result.output
        isWorking = false
        await refresh()
    }

    func forgetWirelessPairings() async {
        guard let adb = tools.adb else { return }
        isWorking = true
        status = "Forgetting wireless pairings on this Mac…"
        _ = await CommandRunner.run(adb, arguments: ["disconnect"])
        _ = await CommandRunner.run(adb, arguments: ["kill-server"])

        let knownHosts = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent(".android/adb_known_hosts.pb")
        try? FileManager.default.removeItem(at: knownHosts)

        defaults.removeObject(forKey: "lastConnectAddress")
        connectAddress = ""
        pairAddress = ""
        nearbyServices = []
        devices = []
        selectedSerial = nil

        _ = await CommandRunner.run(adb, arguments: ["start-server"])
        isWorking = false
        status = "Forgotten on this Mac. Also tap this Mac → Forget on the Pixel, then pair again."
    }

    func loadApps() async {
        guard let scrcpy = tools.scrcpy, let device = selectedDevice else {
            status = "Connect and select a Pixel first."
            return
        }
        isLoadingApps = true
        status = "Reading apps from \(device.displayName)…"
        let result = await CommandRunner.run(
            scrcpy,
            arguments: ["--serial", device.serial, "--list-apps"]
        )
        apps = ADBParser.apps(fromScrcpyOutput: result.output)
        isLoadingApps = false
        status = apps.isEmpty ? "No launchable apps found." : "\(apps.count) apps ready."
    }

    func presentAppLauncher() {
        guard selectedDevice != nil else {
            status = "Connect and select a Pixel first."
            return
        }
        showAppLauncher = true
        Task { await loadApps() }
    }

    func launchApp(_ app: AndroidApp) {
        guard let scrcpy = tools.scrcpy, let device = selectedDevice else { return }
        var arguments = mirrorArguments(for: device)
        arguments += ["--new-display", "--start-app=+\(app.packageName)"]
        do {
            try CommandRunner.launch(scrcpy, arguments: arguments)
            showAppLauncher = false
            status = "Opening \(app.name) in its own window."
        } catch {
            status = "Could not open \(app.name): \(error.localizedDescription)"
        }
    }

    func sendFiles(_ urls: [URL]) async {
        guard let adb = tools.adb, let device = selectedDevice, !urls.isEmpty else {
            status = "Select a connected Pixel before dropping files."
            return
        }
        isWorking = true
        var arguments = ["-s", device.serial, "push"]
        arguments += urls.map(\.path)
        arguments.append("/sdcard/Download/")
        let result = await CommandRunner.run(adb, arguments: arguments)
        status = result.succeeded
            ? "Sent \(urls.count) file\(urls.count == 1 ? "" : "s") to Downloads."
            : (result.output.isEmpty ? "File transfer failed." : result.output)
        isWorking = false
    }

    func saveScreenshot() async {
        guard let adb = tools.adb, let device = selectedDevice else {
            status = "Select a connected Pixel first."
            return
        }

        let panel = NSSavePanel()
        panel.title = "Save Pixel Screenshot"
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "Pixel-\(Self.timestamp()).png"
        guard panel.runModal() == .OK, let destination = panel.url else { return }

        isWorking = true
        let result = await CommandRunner.runData(
            adb,
            arguments: ["-s", device.serial, "exec-out", "screencap", "-p"]
        )
        do {
            guard result.succeeded else {
                status = result.errorOutput.isEmpty ? "Screenshot failed." : result.errorOutput
                isWorking = false
                return
            }
            try result.data.write(to: destination, options: .atomic)
            status = "Screenshot saved to \(destination.lastPathComponent)."
        } catch {
            status = "Could not save screenshot: \(error.localizedDescription)"
        }
        isWorking = false
    }

    func recordPresentation() {
        guard let scrcpy = tools.scrcpy, let device = selectedDevice else {
            status = "Select a connected Pixel first."
            return
        }

        let panel = NSSavePanel()
        panel.title = "Record Pixel Presentation"
        panel.allowedContentTypes = [.mpeg4Movie]
        panel.nameFieldStringValue = "Pixel-Presentation-\(Self.timestamp()).mp4"
        guard panel.runModal() == .OK, let destination = panel.url else { return }

        var arguments = mirrorArguments(for: device)
        arguments += ["--record", destination.path]
        do {
            try CommandRunner.launch(scrcpy, arguments: arguments)
            status = "Recording presentation. Close the mirror window to finish."
        } catch {
            status = "Could not start recording: \(error.localizedDescription)"
        }
    }

    func copyInstallCommand() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(installCommand, forType: .string)
        status = "Install command copied. Paste it into Terminal."
    }

    private func runConnectionCommand(_ adb: URL, arguments: [String]) async -> CommandResult {
        var result = await CommandRunner.run(adb, arguments: arguments)
        let staleNetworkState = result.output.localizedCaseInsensitiveContains("no route to host")
            || result.output.localizedCaseInsensitiveContains("cannot connect to daemon")

        if !result.succeeded && staleNetworkState {
            status = "Restarting the local ADB connection…"
            _ = await CommandRunner.run(adb, arguments: ["kill-server"])
            _ = await CommandRunner.run(adb, arguments: ["start-server"])
            result = await CommandRunner.run(adb, arguments: arguments)
        }
        return result
    }

    private func mirrorArguments(for device: AndroidDevice) -> [String] {
        var arguments = ["--serial", device.serial, "--window-title", "PocketPane · \(device.displayName)"]
        if let size = Int(maxSize), size > 0 { arguments += ["--max-size", String(size)] }
        if let fps = Int(maxFPS), fps > 0 { arguments += ["--max-fps", String(fps)] }
        if turnScreenOff { arguments.append("--turn-screen-off") }
        if stayAwake { arguments.append("--stay-awake") }
        if noAudio { arguments.append("--no-audio") }
        if showTouches { arguments.append("--show-touches") }
        if borderlessWindow { arguments.append("--window-borderless") }
        return arguments
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter.string(from: Date())
    }
}
