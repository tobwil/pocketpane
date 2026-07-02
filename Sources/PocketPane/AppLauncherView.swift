import PocketPaneCore
import SwiftUI

struct AppLauncherView: View {
    @EnvironmentObject private var model: MirrorModel
    @State private var query = ""

    private var filteredApps: [AndroidApp] {
        guard !query.isEmpty else { return model.apps }
        return model.apps.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || $0.packageName.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Open Android App")
                        .font(.title2.bold())
                    Text("Launch it in its own Mac window")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if model.isLoadingApps { ProgressView() }
            }
            .padding(20)

            TextField("Search apps or package names", text: $query)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            Divider()

            if filteredApps.isEmpty && !model.isLoadingApps {
                ContentUnavailableView(
                    "No apps found",
                    systemImage: "square.grid.2x2",
                    description: Text("Try another search or refresh the connected Pixel.")
                )
            } else {
                List(filteredApps) { app in
                    Button {
                        model.launchApp(app)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: app.isSystem ? "gearshape.fill" : "app.fill")
                                .foregroundStyle(app.isSystem ? .secondary : Color.accentColor)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.name).fontWeight(.medium)
                                Text(app.packageName)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "macwindow.badge.plus")
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.inset)
            }
        }
        .frame(width: 560, height: 620)
    }
}
