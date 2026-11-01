//
//  LaunchAtLoginService.swift
//  wedge
//

import Foundation
import ServiceManagement
import os

/// What Settings needs to tell apart: on, off, or registered but waiting for the user in System Settings.
enum LoginItemState: Equatable {
    case enabled, disabled, requiresApproval
}

enum LaunchAtLoginService {
    /// UserDefaults flag recording that we already asked for the login item once.
    static let didRequestKey = "loginItem.didRequest"

    static func state(for status: SMAppService.Status) -> LoginItemState {
        switch status {
        case .enabled: .enabled
        case .requiresApproval: .requiresApproval
        case .notRegistered, .notFound: .disabled
        @unknown default: .disabled
        }
    }

    static var state: LoginItemState {
        state(for: SMAppService.mainApp.status)
    }

    static func setEnabled(_ enabled: Bool) throws {
        let service = SMAppService.mainApp
        if enabled {
            // Already registered (even if awaiting approval): registering again would throw.
            guard state == .disabled else { return }
            try service.register()
        } else {
            guard state != .disabled else { return }
            try service.unregister()
        }
    }

    /// Registers the login item exactly once, on the first launch that ever
    /// asks. Re-registering on every launch would silently undo the user
    /// turning Wedge off in System Settings > General > Login Items.
    static func enableOnLaunch(defaults: UserDefaults = .standard) {
        guard !defaults.bool(forKey: didRequestKey) else { return }
        defaults.set(true, forKey: didRequestKey)

        let service = SMAppService.mainApp
        guard service.status != .enabled else { return }
        do {
            try service.register()
        } catch {
            Log.settings.error("Failed to register login item: \(error.localizedDescription, privacy: .private)")
        }
    }
}
