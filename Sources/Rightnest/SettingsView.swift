import SwiftUI
import AppKit

/// Native controls carry interaction; the corner illustration carries identity.
struct WelcomeView: View {
    @ObservedObject var model: AppModel
    @State private var applications = false
    @State private var query = ""
    private var choices: [(String, String)] {
        model.availableApplications.filter { query.isEmpty || $0.1.localizedCaseInsensitiveContains(query) }
    }
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 10) {
                    Image(nsImage: NSApplication.shared.applicationIconImage).resizable().frame(width: 38, height: 38).accessibilityHidden(true)
                    Text("Rightnest").font(.headline)
                }.padding(.bottom, 12)
                navigation("Overview", symbol: "rectangle.righthalf.inset.filled", selected: !applications) { applications = false }
                navigation("Applications", symbol: "square.stack.3d.up", selected: applications) { applications = true }
                Spacer()
                Label(L("On your Mac. Only."), systemImage: "lock.shield")
                    .font(.caption).foregroundStyle(.secondary)
                Text("0.1.0 · " + L("PREVIEW")).font(.caption).foregroundStyle(.secondary)
            }.padding(18).frame(width: 170).frame(maxHeight: .infinity)
                .background(Color(nsColor: .underPageBackgroundColor))
            Divider()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 7) {
                            Text(L(applications ? "Applications" : "A familiar corner.")).font(.system(size: 28, weight: .semibold))
                            Text(L(applications ? "Choose where Rightnest lends a hand." : "Window controls. On your right."))
                                .font(.body).foregroundStyle(.secondary)
                        }
                        if applications { applicationList } else { overview }
                    }.padding(26).frame(maxWidth: .infinity, alignment: .leading)
                }
                Divider()
                HStack(spacing: 10) {
                    Image(systemName: model.enabled ? "power.circle.fill" : "pause.circle.fill")
                        .foregroundStyle(model.enabled ? Color.accentColor : .secondary).accessibilityHidden(true)
                    Text(L(model.enabled ? "Rightnest is running" : "Paused")).font(.callout)
                    Spacer()
                    Toggle(L("Enabled"), isOn: $model.enabled).toggleStyle(.switch).controlSize(.small)
                }.padding(.horizontal, 24).padding(.vertical, 14).background(Color(nsColor: .controlBackgroundColor))
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }.background(Color(nsColor: .windowBackgroundColor))
    }
    private var overview: some View {
        VStack(alignment: .leading, spacing: 20) {
            cornerPreview
            if !model.trusted || !model.onboardingComplete { PermissionCard(model: model) }
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    if model.trusted {
                        Label(L("Window control is allowed"), systemImage: "checkmark.shield")
                            .font(.callout.weight(.medium))
                        Toggle(L("Automatically place controls in other apps"), isOn: $model.textEditEnabled)
                    }
                    Toggle(L("Launch at login"), isOn: Binding(get: { model.launchAtLogin }, set: { model.setLaunchAtLogin($0) }))
                    if !model.loginMessage.isEmpty { Text(model.loginMessage).font(.caption).foregroundStyle(.secondary) }
                }.padding(10).frame(maxWidth: .infinity, alignment: .leading)
            } label: { Text(L("Everyday use")).font(.headline) }
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(L("Try it first, without permission")).font(.callout.weight(.semibold))
                    Text(L("A test window, with nothing to lose.")).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button(L("Open Test Window")) { model.openDemo() }
            }
            if !model.onboardingComplete {
                Button(L("Continue in menu bar")) { model.finishSetup() }.buttonStyle(.borderedProminent)
            }
        }
    }
    private var cornerPreview: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 5) {
                ForEach(0..<3) { _ in Circle().fill(.secondary.opacity(0.25)).frame(width: 7, height: 7) }
                Spacer()
                HStack(spacing: 0) {
                    previewSymbol("minus", color: .yellow)
                    previewSymbol("square", color: .green)
                    previewSymbol("xmark", color: .red)
                }.background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 7))
            }.padding(14)
            Divider()
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "arrow.up.right").font(.system(size: 25, weight: .medium)).foregroundStyle(.tint).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text(L("Room for your habits.")).font(.headline)
                    Text(L("Original controls stay. Rightnest finds a clear corner, or uses free space just outside the window."))
                        .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }.padding(18)
        }.background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(nsColor: .separatorColor)))
    }
    private func previewSymbol(_ symbol: String, color: Color) -> some View {
        Image(systemName: symbol).font(.system(size: 11, weight: .semibold))
            .foregroundStyle(color).frame(width: 30, height: 26).accessibilityHidden(true)
    }
    private var applicationList: some View {
        VStack(alignment: .leading, spacing: 14) {
            TextField(L("Search applications"), text: $query).textFieldStyle(.roundedBorder)
            Text(L("Listed apps are eligible, not a compatibility guarantee. Crowded or uncertain windows may hide controls."))
                .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            if choices.isEmpty { Text(L("No matching applications")).foregroundStyle(.secondary).padding(.vertical, 20) }
            ForEach(choices, id: \.0) { item in
                HStack(spacing: 12) {
                    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: item.0) {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: url.path)).resizable().frame(width: 30, height: 30).accessibilityHidden(true)
                    } else { Image(systemName: "app").frame(width: 30, height: 30).accessibilityHidden(true) }
                    Toggle(item.1, isOn: Binding(get: { !model.disabledApplications.contains(item.0) }, set: { model.setApplication(item.0, enabled: $0) }))
                        .toggleStyle(.switch).controlSize(.small)
                }.padding(12).background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    private func navigation(_ title: String, symbol: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(L(title), systemImage: symbol).font(.body.weight(selected ? .semibold : .regular))
                .frame(maxWidth: .infinity, alignment: .leading).padding(10)
                .background(selected ? Color.accentColor.opacity(0.14) : .clear, in: RoundedRectangle(cornerRadius: 8))
        }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
    }
}
