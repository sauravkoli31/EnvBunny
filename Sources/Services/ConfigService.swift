import Foundation

struct ConfigService {
    static let configDirectory: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/environment-manager", isDirectory: true)
    }()

    private static let configFile: URL = {
        configDirectory.appendingPathComponent("environments.json")
    }()

    /// Sets up the config directory with owner-only permissions (700).
    static func ensureDirectoryExists() {
        let fm = FileManager.default

        if !fm.fileExists(atPath: configDirectory.path) {
            try? fm.createDirectory(at: configDirectory, withIntermediateDirectories: true)
        }

        // Lock down permissions: owner read/write/execute only
        try? fm.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: configDirectory.path
        )
    }

    static func load() -> AppConfig {
        ensureDirectoryExists()

        guard FileManager.default.fileExists(atPath: configFile.path),
              let data = try? Data(contentsOf: configFile) else {
            let defaultConfig = AppConfig.default
            save(defaultConfig)
            return defaultConfig
        }

        do {
            return try JSONDecoder().decode(AppConfig.self, from: data)
        } catch {
            print("Failed to decode config: \(error). Using default.")
            return .default
        }
    }

    @discardableResult
    static func save(_ config: AppConfig) -> Bool {
        ensureDirectoryExists()

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            try data.write(to: configFile, options: .atomic)

            // Owner read/write only on the config file
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: configFile.path
            )

            return true
        } catch {
            print("Failed to save config: \(error)")
            return false
        }
    }
}
