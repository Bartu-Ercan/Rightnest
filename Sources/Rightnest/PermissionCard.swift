import SwiftUI
import RightnestCore

struct PermissionCard: View {
    @ObservedObject var model: AppModel
    @State private var showHelp = false
    private var allowed: Bool { model.permissionFlow == .granted }
    private var waiting: Bool { model.permissionFlow == .waiting || model.permissionFlow == .revoked }
    private var title: String {
        switch model.permissionFlow {
        case .required: "Allow window control"
        case .waiting: "Waiting for permission"
        case .granted: "Window control is allowed"
        case .revoked: "Window control needs permission again"
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: allowed ? "checkmark.circle.fill" : "hand.raised.fill")
                    .foregroundStyle(allowed ? Color.green : Color.accentColor).accessibilityHidden(true)
                Text(L(title)).font(.headline)
                Spacer()
                if allowed { Text(L("READY")).font(.caption.weight(.semibold)).foregroundStyle(.secondary) }
            }
            if allowed {
                Text(L("Permission detected. Try a TextEdit document next. The original left-side controls stay in place."))
                    .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                Button(L("Try in TextEdit")) { model.openTextEdit() }.buttonStyle(.borderedProminent)
                Text(L("Preview support: TextEdit only. If the title bar is occupied or uncertain, controls stay hidden."))
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            } else {
                Text(L("Rightnest needs macOS permission to close, minimize and resize another app’s window. macOS grants broad control; Rightnest uses it for window controls and does not send window data to a server."))
                    .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                if waiting {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(L("1. In System Settings, find Rightnest."))
                        Text(L("2. Turn on the switch beside it."))
                        Text(L("3. Return here. Rightnest checks automatically."))
                    }.font(.callout)
                    Text("Privacy & Security → \(model.permissionPaneName)")
                        .font(.caption).foregroundStyle(.secondary)
                }
                HStack {
                    Button(L(waiting ? "Open Permission Settings" : "Set Up Window Control…")) {
                        if waiting { model.openPrivacySettings() } else { model.requestPermission() }
                    }.buttonStyle(.borderedProminent)
                    if waiting { Button(L("Check Again")) { model.checkPermission() } }
                }
                if model.settingsOpenFailed {
                    Text("Open System Settings → Privacy & Security → \(model.permissionPaneName) manually.")
                        .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                DisclosureGroup(L("Already enabled, or Rightnest isn’t listed?"), isExpanded: $showHelp) {
                    VStack(alignment: .leading, spacing: 9) {
                        Text(L("If it isn’t listed, press + in the permission settings and choose this copy of Rightnest. “Show Rightnest in Finder” locates it for you."))
                        Text(L("If the switch is already on but permission is still missing, quit and reopen Rightnest. After a development update, remove its old entry with − and add this copy again with +."))
                        Text(L("You can also try the test window below without granting permission."))
                        Button(L("Show Rightnest in Finder")) { model.revealApplication() }
                    }.font(.callout).foregroundStyle(.secondary).padding(.top, 6)
                }.font(.callout)
            }
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .contain)
    }
}
