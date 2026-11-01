import AppKit
import ServiceManagement
import SwiftUI
import os

/// The Open at login toggle. When macOS wants the user's approval, or a change fails,
/// the Login Items message appears under it (with a button to System Settings when approval is pending).
struct LoginItemRow: View {
    let announce: (String) -> Void
    @State private var state = LaunchAtLoginService.state
    @State private var changeFailed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(WedgeCopy.openAtLogin, isOn: isOn)
            if changeFailed || state == .requiresApproval {
                Text(WedgeCopy.loginChangeFailed)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            if state == .requiresApproval {
                Button(WedgeCopy.openLoginItems) { SMAppService.openSystemSettingsLoginItems() }
            }
        }
        // Returning from System Settings (where the user may have approved or fixed it) refreshes
        // the state and drops a stale failure message.
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            state = LaunchAtLoginService.state
            changeFailed = false
        }
    }

    /// "On" means registered, including while approval is pending, so switching off always unregisters.
    private var isOn: Binding<Bool> {
        Binding(
            get: { state != .disabled },
            set: { wantsOn in
                do {
                    try LaunchAtLoginService.setEnabled(wantsOn)
                    changeFailed = false
                } catch {
                    changeFailed = true
                    announce(WedgeCopy.loginChangeFailed)
                    Log.settings.error("Login item change failed: \(error.localizedDescription, privacy: .private)")
                }
                state = LaunchAtLoginService.state
            }
        )
    }
}
