import Foundation

struct EnvFileService {
    /// The .env file is always written inside the app's secure config directory.
    private static let envFileURL: URL = {
        ConfigService.configDirectory.appendingPathComponent(".env")
    }()

    static func write(variables: [EnvironmentVariable]) -> Bool {
        ConfigService.ensureDirectoryExists()

        let lines = variables.map { variable in
            let value = variable.value
            if value.contains(" ") || value.contains("#") || value.isEmpty {
                return "\(variable.key)=\"\(value)\""
            }
            return "\(variable.key)=\(value)"
        }

        let content = lines.joined(separator: "\n") + "\n"

        do {
            try content.write(to: envFileURL, atomically: true, encoding: .utf8)

            // Owner read/write only
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: envFileURL.path
            )

            return true
        } catch {
            print("Failed to write .env file: \(error)")
            return false
        }
    }
}
