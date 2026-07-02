import PocketPaneCore
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: MirrorModel
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = true
    @State private var isDropTarget = false
    @State private var showForgetConfirmation = false

    private var backgroundColors: [Color] {
        colorScheme == .dark
            ? [
                Color(red: 0.055, green: 0.067, blue: 0.09),
                Color(red: 0.075, green: 0.10, blue: 0.14)
            ]
            : [
                Color(red: 0.955, green: 0.975, blue: 1.0),
                Color(red: 0.90, green: 0.94, blue: 0.985)
            ]
    }

    private var panelFill: Color {
        colorScheme == .dark ? .white.opacity(0.055) : .white.opacity(0.72)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Divider().overlay(colorScheme == .dark ? .white.opacity(0.1) : .black.opacity(0.1))
                content
                statusBar
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .overlay {
            if isDropTarget {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 4, dash: [9]))
                    .padding(10)
                    .overlay {
                        Label("Send to Pixel Downloads", systemImage: "arrow.down.doc.fill")
                            .font(.title2.bold())
                            .padding(18)
                            .background(.ultraThickMaterial, in: Capsule())
                    }
                    .allowsHitTesting(false)
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            Task { await model.sendFiles(urls) }
            return !urls.isEmpty
        } isTargeted: {
            isDropTarget = $0
        }
        .sheet(isPresented: $model.showAppLauncher) {
            AppLauncherView()
                .environmentObject(model)
        }
        .confirmationDialog(
            "Forget wireless pairing?",
            isPresented: $showForgetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Forget on this Mac", role: .destructive) {
                Task { await model.forgetWirelessPairings() }
            }
        } message: {
            Text("This clears all saved Android wireless pairings on this Mac. Also choose this Mac → Forget in the Pixel’s Wireless debugging settings.")
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.accentColor.gradient)
                Image(systemName: "rectangle.on.rectangle.angled")
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 3) {
                Text("PocketPane")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text("Your Android, right here.")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                isDarkMode.toggle()
            } label: {
                Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
            }
            .buttonStyle(.plain)
            .help(isDarkMode ? "Switch to Light Mode" : "Switch to Dark Mode")

            Button {
                Task { await model.refresh() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .disabled(model.isWorking || model.tools.adb == nil)
        }
        .padding(24)
    }

    @ViewBuilder
    private var content: some View {
        if !model.tools.isReady {
            setupView
        } else {
            HStack(alignment: .top, spacing: 22) {
                devicePanel
                connectionPanel
            }
            .padding(24)
        }
    }

    private var setupView: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.accentColor)
            Text("One quick setup")
                .font(.title2.bold())
            Text("PocketPane uses the trusted open-source scrcpy engine and Android Platform Tools. Install both with Homebrew, then refresh.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 470)
            Text(model.installCommand)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding(14)
                .background(
                    colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.07),
                    in: RoundedRectangle(cornerRadius: 10)
                )
            HStack {
                Button("Copy install command") { model.copyInstallCommand() }
                    .buttonStyle(.borderedProminent)
                Button("Refresh") { Task { await model.refresh() } }
            }
            Text(missingTools)
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var missingTools: String {
        let missing = [
            model.tools.scrcpy == nil ? "scrcpy" : nil,
            model.tools.adb == nil ? "adb" : nil
        ].compactMap { $0 }
        return "Missing: \(missing.joined(separator: ", "))"
    }

    private var devicePanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Devices", systemImage: "smartphone")
                .font(.headline)

            if model.devices.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 30))
                        .foregroundStyle(.secondary)
                    Text("No device connected")
                        .font(.headline)
                    Text("Use Wireless debugging on your Pixel, or connect once with USB.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                VStack(spacing: 8) {
                    ForEach(model.devices) { device in
                        deviceRow(device)
                    }
                }
            }

            Divider()

            DisclosureGroup("Mirroring options", isExpanded: $model.showAdvanced) {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
                    GridRow {
                        Text("Resolution")
                        Picker("", selection: $model.maxSize) {
                            Text("1280").tag("1280")
                            Text("1920").tag("1920")
                            Text("Native").tag("0")
                        }
                    }
                    GridRow {
                        Text("Frame rate")
                        Picker("", selection: $model.maxFPS) {
                            Text("30 fps").tag("30")
                            Text("60 fps").tag("60")
                            Text("120 fps").tag("120")
                        }
                    }
                }
                .pickerStyle(.menu)
                .padding(.top, 10)

                Toggle("Keep phone awake", isOn: $model.stayAwake)
                Toggle("Turn phone screen off", isOn: $model.turnScreenOff)
                Toggle("Disable audio", isOn: $model.noAudio)
                Toggle("Show phone touches", isOn: $model.showTouches)
                Toggle("Borderless presentation window", isOn: $model.borderlessWindow)
            }

            Spacer()

            VStack(spacing: 8) {
                Button {
                    model.presentAppLauncher()
                } label: {
                    Label("Open Android App…", systemImage: "square.grid.2x2")
                        .frame(maxWidth: .infinity)
                }

                HStack {
                    Button {
                        Task { await model.saveScreenshot() }
                    } label: {
                        Label("Screenshot", systemImage: "camera")
                    }
                    Button {
                        model.recordPresentation()
                    } label: {
                        Label("Record", systemImage: "record.circle")
                    }
                }

                Text("Clipboard sync is automatic · Drop files anywhere in this window")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }

            Button {
                model.mirror()
            } label: {
                Label("Start Mirroring", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(model.selectedDevice?.state != .device)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(panelFill, in: RoundedRectangle(cornerRadius: 18))
    }

    private func deviceRow(_ device: AndroidDevice) -> some View {
        Button {
            model.selectedSerial = device.serial
        } label: {
            HStack {
                Image(systemName: device.isWireless ? "wifi" : "cable.connector")
                    .frame(width: 24)
                    .foregroundStyle(device.state == .device ? Color.green : Color.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.displayName)
                        .fontWeight(.medium)
                    Text(model.connectionEndpoint(for: device) ?? device.serial)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                    if let endpoint = model.connectionEndpoint(for: device),
                       endpoint != device.serial {
                        Text(device.serial)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                if model.selectedSerial == device.serial {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(11)
            .background(
                model.selectedSerial == device.serial ? Color.accentColor.opacity(0.14) : .clear,
                in: RoundedRectangle(cornerRadius: 11)
            )
        }
        .buttonStyle(.plain)
    }

    private var connectionPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Label("Wireless setup", systemImage: "antenna.radiowaves.left.and.right")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("First time: pair")
                        .fontWeight(.semibold)
                    Text("On your Pixel, open Settings → System → Developer options → Wireless debugging → Pair device with pairing code. Keep that dialog open.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let service = model.nearbyServices.first(where: { $0.kind == .pairing }) {
                        HStack(spacing: 7) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(Color.green)
                            Text("Current pairing address: \(service.endpoint)")
                                .font(.caption.weight(.medium))
                                .textSelection(.enabled)
                        }
                        .padding(9)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 9))
                    }
                    HStack {
                        TextField("Pairing IP & port", text: $model.pairAddress)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            Task { await model.findPairingAddress() }
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }
                        .help("Find the current pairing address")
                        .disabled(model.isWorking)
                    }
                    SecureField("Current 6-digit pairing code", text: $model.pairCode)
                        .textFieldStyle(.roundedBorder)
                    Button("Pair Pixel") {
                        Task { await model.pair() }
                    }
                    .disabled(model.isWorking || model.pairAddress.isEmpty || model.pairCode.isEmpty)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Connect")
                        .fontWeight(.semibold)
                    Text("After pairing, use the IP address and port on the main Wireless debugging screen. It is different from the pairing port.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    TextField("Connection IP & port", text: $model.connectAddress)
                        .textFieldStyle(.roundedBorder)
                    Button("Connect over Wi‑Fi") {
                        Task { await model.connect() }
                    }
                    .disabled(model.isWorking || model.connectAddress.isEmpty)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("USB shortcut")
                        .fontWeight(.semibold)
                    Text("Plug in and authorize your Pixel once; PocketPane can switch ADB to Wi‑Fi.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Enable wireless via USB") {
                        Task { await model.prepareUSBWireless() }
                    }
                    .disabled(model.isWorking)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Connection management")
                        .fontWeight(.semibold)
                    HStack {
                        Button("Disconnect") {
                            Task { await model.disconnectSelected() }
                        }
                        .disabled(model.selectedDevice == nil || model.isWorking)
                        Button("Forget pairing…", role: .destructive) {
                            showForgetConfirmation = true
                        }
                        .disabled(model.isWorking)
                    }
                }
            }
            .padding(20)
        }
        .frame(minWidth: 350, idealWidth: 380, maxWidth: 420)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(panelFill, in: RoundedRectangle(cornerRadius: 18))
    }

    private var statusBar: some View {
        HStack(spacing: 9) {
            if model.isWorking {
                ProgressView().controlSize(.small)
            } else {
                Circle()
                    .fill(model.tools.isReady ? Color.green : Color.orange)
                    .frame(width: 7, height: 7)
            }
            Text(model.status)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer()
            Text("Powered by scrcpy")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 24)
        .frame(height: 40)
        .background(colorScheme == .dark ? .black.opacity(0.14) : .white.opacity(0.5))
    }
}
