//
//  LaunchAtLoginService.swift
//  wedge
//

import Foundation
import ServiceManagement
import os.log

enum LaunchAtLoginService {
    private static let log = Logger(subsystem: "com.xela.wedge", category: "LaunchAtLogin")

    /// UserDefaults flag recording that we already asked for the login item once.
    static let didRequestKey = "wedge.didRequestLoginItem"

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
            log.error("Failed to register login item: \(error.localizedDescription, privacy: .public)")
        }
    }
}
