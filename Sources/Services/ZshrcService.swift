import Foundation

struct ZshrcService {
    private static let startSentinel = "# --- ENVIRONMENT MANAGER START (DO NOT EDIT) ---"
    private static let endSentinel = "# --- ENVIRONMENT MANAGER END ---"

    private static let zshrcURL: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".zshrc")
    }()

    private static let backupsDirectory: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/environment-manager/backups", isDirectory: true)
    }()

    static func apply(variables: [EnvironmentVariable], environmentName: String) -> Bool {
        let fm = FileManager.default

        // Read existing .zshrc content
        var content: String
        if fm.fileExists(atPath: zshrcURL.path) {
            do {
                content = try String(contentsOf: zshrcURL, encoding: .utf8)
            } catch {
                print("Failed to read .zshrc: \(error)")
                return false
            }
        } else {
            content = ""
        }

        // Create backup before modifying
        createBackup(content: content)

        // Build the managed block, unsetting stale keys from the previous environment
        let oldKeys = previousKeys(in: content)
        let block = buildBlock(variables: variables, environmentName: environmentName, previousKeys: oldKeys)

        // Replace or append the managed block
        if let startRange = content.range(of: startSentinel),
           let endRange = content.range(of: endSentinel) {
            // Replace existing block
            let replaceRange = startRange.lowerBound..<endRange.upperBound
            content.replaceSubrange(replaceRange, with: block)
        } else {
            // Append to end
            if !content.isEmpty && !content.hasSuffix("\n") {
                content += "\n"
            }
            content += "\n" + block + "\n"
        }

        // Atomic write via temp file
        return atomicWrite(content: content, to: zshrcURL)
    }

    /// Parse keys from the existing managed block so we can unset stale ones.
    private static func previousKeys(in content: String) -> Set<String> {
        guard let startRange = content.range(of: startSentinel),
              let endRange = content.range(of: endSentinel) else {
            return []
        }

        let block = String(content[startRange.upperBound..<endRange.lowerBound])
        var keys = Set<String>()
        for line in block.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("export "), let eqIndex = trimmed.firstIndex(of: "=") {
                let keyStart = trimmed.index(trimmed.startIndex, offsetBy: 7) // after "export "
                let key = String(trimmed[keyStart..<eqIndex])
                keys.insert(key)
            }
        }
        return keys
    }

    private static func buildBlock(variables: [EnvironmentVariable], environmentName: String, previousKeys: Set<String>) -> String {
        var lines: [String] = [startSentinel]

        // Unset keys from the previous environment that are not in the new one
        let newKeys = Set(variables.map(\.key))
        let staleKeys = previousKeys.subtracting(newKeys).sorted()
        for key in staleKeys {
            lines.append("unset \(key)")
        }

        for variable in variables {
            let escapedValue = shellEscape(variable.value)
            lines.append("export \(variable.key)=\"\(escapedValue)\"")
        }

        lines.append("# Active: \(environmentName)")
        lines.append(endSentinel)

        return lines.joined(separator: "\n")
    }

    private static func shellEscape(_ value: String) -> String {
        var result = value
        result = result.replacingOccurrences(of: "\\", with: "\\\\")
        result = result.replacingOccurrences(of: "\"", with: "\\\"")
        result = result.replacingOccurrences(of: "$", with: "\\$")
        result = result.replacingOccurrences(of: "`", with: "\\`")
        return result
    }

    private static func createBackup(content: String) {
        let fm = FileManager.default

        if !fm.fileExists(atPath: backupsDirectory.path) {
            try? fm.createDirectory(at: backupsDirectory, withIntermediateDirectories: true)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        let backupURL = backupsDirectory.appendingPathComponent("zshrc.backup.\(timestamp)")

        try? content.write(to: backupURL, atomically: true, encoding: .utf8)

        // Restrict backup file to owner-only read/write
        try? fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: backupURL.path)
    }

    private static func atomicWrite(content: String, to url: URL) -> Bool {
        let tempURL = url.deletingLastPathComponent()
            .appendingPathComponent(".zshrc.envmanager.tmp")

        do {
            try content.write(to: tempURL, atomically: false, encoding: .utf8)
            // Restrict temp file before moving into place
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: tempURL.path)
            _ = try FileManager.default.replaceItemAt(url, withItemAt: tempURL)
            return true
        } catch {
            print("Failed to write .zshrc: \(error)")
            // Clean up temp file
            try? FileManager.default.removeItem(at: tempURL)
            return false
        }
    }
}
