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
            ForEach(model.availableApplications, id: \.0) { item in
                Toggle(item.1, isOn: Binding(get: { !model.disabledApplications.contains(item.0) }, set: {
                    model.setApplication(item.0, enabled: $0)
                }))
            }
        }
        Button(L("Open Test Window")) { model.openDemo() }
        Button(L("Settings…")) { model.showSettings() }.keyboardShortcut(",")
        Button(L("Releases on GitHub")) { model.openReleases() }
        Divider()
        Button(L("Quit Rightnest")) { NSApp.terminate(nil) }.keyboardShortcut("q")
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
