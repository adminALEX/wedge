//
//  LaunchAtLoginService.swift
//  wedge
//

import ServiceManagement
import os.log

enum LaunchAtLoginService {
    private static let log = Logger(subsystem: "com.xela.wedge", category: "LaunchAtLogin")

    static func enableOnLaunch() {
        let service = SMAppService.mainApp
        guard service.status != .enabled else { return }
        do {
            try service.register()
        } catch {
            log.error("Failed to register login item: \(error.localizedDescription, privacy: .public)")
        }
    }
}
