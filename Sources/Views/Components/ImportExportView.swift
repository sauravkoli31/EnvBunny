import SwiftUI
import UniformTypeIdentifiers

struct ImportButton: View {
    @Bindable var viewModel: EnvironmentViewModel

    var body: some View {
        Button {
            importEnvFile()
        } label: {
            Label("Import .env", systemImage: "square.and.arrow.down")
        }
    }

    private func importEnvFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Import .env File"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }

        let variables = parseEnvContent(content)
        let fileName = url.deletingPathExtension().lastPathComponent

        // Generate a unique name
        var name = fileName
        var counter = 2
        while viewModel.config.environments.contains(where: { $0.name == name }) {
            name = "\(fileName) \(counter)"
            counter += 1
        }

        let env = AppEnvironment(name: name, variables: variables)
        viewModel.config.environments.append(env)
        viewModel.selectedEnvironmentID = env.id
        ConfigService.save(viewModel.config)
    }

    private func parseEnvContent(_ content: String) -> [EnvironmentVariable] {
        content
            .components(separatedBy: .newlines)
            .compactMap { line -> EnvironmentVariable? in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                // Skip empty lines and comments
                guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { return nil }

                guard let equalsIndex = trimmed.firstIndex(of: "=") else { return nil }

                let key = String(trimmed[trimmed.startIndex..<equalsIndex])
                    .trimmingCharacters(in: .whitespaces)
                var value = String(trimmed[trimmed.index(after: equalsIndex)...])
                    .trimmingCharacters(in: .whitespaces)

                // Strip surrounding quotes
                if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
                   (value.hasPrefix("'") && value.hasSuffix("'")) {
                    value = String(value.dropFirst().dropLast())
                }

                guard !key.isEmpty else { return nil }
                return EnvironmentVariable(key: key, value: value)
            }
    }
}

struct ExportButton: View {
    let environment: AppEnvironment

    var body: some View {
        Button {
            exportEnvFile()
        } label: {
            Label("Export .env", systemImage: "square.and.arrow.up")
        }
    }

    private func exportEnvFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "\(environment.name).env"
        panel.title = "Export .env File"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let content = environment.variables
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "\n") + "\n"

        try? content.write(to: url, atomically: true, encoding: .utf8)
    }
}
