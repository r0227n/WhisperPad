//
//  UserDefaultsClientLive.swift
//  WhisperPad
//

import Dependencies
import Foundation
import OSLog

private let logger = Logger(subsystem: "com.whisperpad", category: "UserDefaultsClientLive")

// MARK: - DependencyKey

extension UserDefaultsClient: DependencyKey {
    static var liveValue: Self {
        let userDefaults = UserDefaults.standard
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        return Self(
            loadSettings: {
                guard let data = userDefaults.data(forKey: AppSettings.Keys.settings) else {
                    logger.info("No saved settings found, returning defaults")
                    return .default
                }

                do {
                    let settings = try decoder.decode(AppSettings.self, from: data)
                    logger.info("Settings loaded successfully")
                    return settings
                } catch {
                    logger.error("Failed to decode settings: \(error.localizedDescription)")
                    return .default
                }
            },
            saveSettings: { settings in
                do {
                    let data = try encoder.encode(settings)
                    userDefaults.set(data, forKey: AppSettings.Keys.settings)
                    logger.info("Settings saved successfully")
                } catch {
                    logger.error("Failed to encode settings: \(error.localizedDescription)")
                    throw UserDefaultsError.encodingFailed(error.localizedDescription)
                }
            },
            saveStorageBookmark: { bookmarkData in
                userDefaults.set(bookmarkData, forKey: AppSettings.Keys.storageBookmark)
                logger.info("Storage bookmark saved (\(bookmarkData.count) bytes)")
            },
            loadStorageBookmark: {
                let data = userDefaults.data(forKey: AppSettings.Keys.storageBookmark)
                if data != nil {
                    logger.info("Storage bookmark loaded")
                } else {
                    logger.debug("No storage bookmark found")
                }
                return data
            },
            // 注意: 返された URL のセキュリティスコープリソースは、アプリのライフサイクル全体で
            // 使用されることを想定しています。アプリ終了時に自動的にリソースは解放されます。
            // 異なるユースケースで使用する場合は、呼び出し側で url.stopAccessingSecurityScopedResource()
            // を呼び出してリソースを解放する必要があります。
            resolveBookmark: { bookmarkData in
                do {
                    var isStale = false
                    let url = try URL(
                        resolvingBookmarkData: bookmarkData,
                        options: .withSecurityScope,
                        relativeTo: nil,
                        bookmarkDataIsStale: &isStale
                    )

                    if isStale {
                        logger.warning("Bookmark is stale, may need to be recreated")
                    }

                    // セキュリティスコープのアクセスを開始
                    guard url.startAccessingSecurityScopedResource() else {
                        logger.error("Failed to start accessing security-scoped resource")
                        return nil
                    }

                    logger.info("Bookmark resolved to: \(url.path)")
                    return url
                } catch {
                    logger.error("Failed to resolve bookmark: \(error.localizedDescription)")
                    return nil
                }
            },
            createBookmark: { url in
                do {
                    let bookmarkData = try url.bookmarkData(
                        options: .withSecurityScope,
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    )
                    logger.info("Bookmark created for: \(url.path)")
                    return bookmarkData
                } catch {
                    logger.error("Failed to create bookmark: \(error.localizedDescription)")
                    throw UserDefaultsError.bookmarkCreationFailed(error.localizedDescription)
                }
            }
        )
    }
}
