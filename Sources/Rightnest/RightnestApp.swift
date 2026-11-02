import SwiftUI
import AppKit

@main
struct RightnestApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    var body: some Scene {
        MenuBarExtra("Rightnest", systemImage: "rectangle.righthalf.inset.filled") {
            MenuContent(model: delegate.model)
        }
    }
}
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    func applicationDidFinishLaunching(_ notification: Notification) { model.start() }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        model.showSettings(); return true
    }
}
struct MenuContent: View {
    @ObservedObject var model: AppModel
    var body: some View {
        Toggle(L("Enable Rightnest"), isOn: $model.enabled)
        Text(model.status)
        Divider()
        Menu(L("Applications")) {
            ForEach(AppModel.candidates, id: \.0) { item in
                Toggle(item.1, isOn: Binding(get: { !model.disabledApplications.contains(item.0) }, set: {
                    if $0 { model.disabledApplications.remove(item.0) } else { model.disabledApplications.insert(item.0) }
                })).disabled(!AppModel.verifiedApplications.contains(item.0))
            }
        }
        Button(L("Open Test Window")) { model.openDemo() }
        Button(L("Settings…")) { model.showSettings() }.keyboardShortcut(",")
        Button(L("Releases on GitHub")) { model.openReleases() }
        Divider()
        Button(L("Quit Rightnest")) { NSApp.terminate(nil) }.keyboardShortcut("q")
    }
}

struct WelcomeView: View {
    @ObservedObject var model: AppModel
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "rectangle.righthalf.inset.filled")
                    .font(.system(size: 32, weight: .medium)).foregroundStyle(.tint)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Text(L("Rightnest")).font(.largeTitle.weight(.semibold))
                    Text(L("Window controls. On your right.")).font(.title3).foregroundStyle(.secondary)
                }
                Spacer()
                Text(L("PREVIEW")).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    .padding(.horizontal, 9).padding(.vertical, 5).background(.quaternary, in: Capsule())
            }
            PermissionCard(model: model)
            VStack(alignment: .leading, spacing: 9) {
                Text(L("Try it first, without permission")).font(.headline)
                Text(L("A safe test window lets you try the three right-side controls before allowing access to other apps."))
                    .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                Button(L("Open Test Window")) { model.openDemo() }
            }
            if model.trusted {
                Toggle(L("Enable external controls (TextEdit preview)"), isOn: $model.textEditEnabled).font(.callout)
            }
            VStack(alignment: .leading, spacing: 9) {
                Toggle(L("Launch at login"), isOn: Binding(get: { model.launchAtLogin }, set: { model.setLaunchAtLogin($0) }))
                if !model.loginMessage.isEmpty { Text(model.loginMessage).font(.caption).foregroundStyle(.secondary) }
                Text(L("Other applications are being evaluated. Unsupported layouts remain hidden.")).font(.caption).foregroundStyle(.secondary)
                if !model.onboardingComplete {
                    Button(L("Continue in menu bar")) { model.finishSetup() }.buttonStyle(.borderedProminent)
                }
            }
            Spacer(minLength: 0)
            HStack {
                Circle().fill(model.enabled ? Color.accentColor : Color.secondary).frame(width: 7, height: 7).accessibilityHidden(true)
                Text(model.status).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Toggle(L("Enabled"), isOn: $model.enabled).toggleStyle(.switch).controlSize(.small)
            }
        }.padding(28) }
    }
}

struct DemoView: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "arrow.up.right").font(.system(size: 42, weight: .light)).foregroundStyle(.tint).accessibilityHidden(true)
            Text(L("A familiar corner.")).font(.system(size: 30, weight: .semibold))
            Text(L("Your window controls are also on the right.\nTry minimizing, fitting to screen, restoring, then closing this window."))
                .multilineTextAlignment(.center).foregroundStyle(.secondary).lineSpacing(4)
            HStack(spacing: 26) {
                Label(L("Minimize"), systemImage: "minus")
                Label(L("Fit / restore"), systemImage: "square")
                Label(L("Close"), systemImage: "xmark")
            }.font(.callout).padding(.top, 16)
            Text(L("Test window only · No other app is changed")).font(.caption).foregroundStyle(.tertiary)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
