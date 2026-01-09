//
//  LoginItemClientLive.swift
//  WhisperPad
//

import ComposableArchitecture
import Foundation
import OSLog
import ServiceManagement

private let clientLogger = Logger(subsystem: "com.whisperpad", category: "LoginItemClient")

// MARK: - DependencyKey

extension LoginItemClient: DependencyKey {
    static let liveValue = Self(
        register: {
            clientLogger.info("Registering app as login item")
            do {
                try SMAppService.mainApp.register()
                clientLogger.info("Successfully registered as login item")
            } catch {
                clientLogger.error("Failed to register as login item: \(error.localizedDescription)")
                throw LoginItemError.registrationFailed
            }
        },
        unregister: {
            clientLogger.info("Unregistering app from login items")
            do {
                try SMAppService.mainApp.unregister()
                clientLogger.info("Successfully unregistered from login items")
            } catch {
                clientLogger.error("Failed to unregister from login items: \(error.localizedDescription)")
                throw LoginItemError.unregistrationFailed
            }
        },
        status: {
            let appService = SMAppService.mainApp
            let isEnabled = appService.status == .enabled
            clientLogger.debug("Login item status: \(isEnabled ? "enabled" : "disabled")")
            return isEnabled
        }
    )
}
