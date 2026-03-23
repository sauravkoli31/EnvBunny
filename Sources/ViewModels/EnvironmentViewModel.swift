import SwiftUI

@Observable
final class EnvironmentViewModel {
    var config: AppConfig
    var selectedEnvironmentID: UUID?
    var errorMessage: String?
    var showError = false
    var showApplySuccess = false

    var selectedEnvironment: AppEnvironment? {
        guard let id = selectedEnvironmentID else { return nil }
        return config.environments.first { $0.id == id }
    }

    var activeEnvironment: AppEnvironment? {
        guard let name = config.activeEnvironment else { return nil }
        return config.environments.first { $0.name == name }
    }

    init() {
        self.config = ConfigService.load()
        // Auto-select the first environment if available
        self.selectedEnvironmentID = config.environments.first?.id
    }

    // MARK: - Environment CRUD

    func createEnvironment(name: String) {
        guard !name.isEmpty else { return }
        guard !config.environments.contains(where: { $0.name == name }) else {
            showError(message: "Environment '\(name)' already exists.")
            return
        }

        let env = AppEnvironment(name: name, variables: [])
        config.environments.append(env)
        selectedEnvironmentID = env.id
        save()
    }

    func deleteEnvironment(id: UUID) {
        guard let env = config.environments.first(where: { $0.id == id }) else { return }

        if config.activeEnvironment == env.name {
            config.activeEnvironment = nil
        }

        config.environments.removeAll { $0.id == id }

        if selectedEnvironmentID == id {
            selectedEnvironmentID = config.environments.first?.id
        }

        save()
    }

    func renameEnvironment(id: UUID, newName: String) {
        guard !newName.isEmpty else { return }
        guard let index = config.environments.firstIndex(where: { $0.id == id }) else { return }
        guard !config.environments.contains(where: { $0.name == newName && $0.id != id }) else {
            showError(message: "Environment '\(newName)' already exists.")
            return
        }

        let oldName = config.environments[index].name
        config.environments[index].name = newName

        if config.activeEnvironment == oldName {
            config.activeEnvironment = newName
        }

        save()
    }

    func duplicateEnvironment(id: UUID) {
        guard let source = config.environments.first(where: { $0.id == id }) else { return }

        var copyName = "\(source.name) Copy"
        var counter = 2
        while config.environments.contains(where: { $0.name == copyName }) {
            copyName = "\(source.name) Copy \(counter)"
            counter += 1
        }

        let newEnv = AppEnvironment(
            name: copyName,
            variables: source.variables.map { EnvironmentVariable(key: $0.key, value: $0.value) }
        )
        config.environments.append(newEnv)
        selectedEnvironmentID = newEnv.id
        save()
    }

    // MARK: - Variable CRUD

    func addVariable(to envID: UUID, key: String, value: String) {
        guard let index = config.environments.firstIndex(where: { $0.id == envID }) else { return }

        if !Self.isValidKey(key) {
            showError(message: "Invalid key '\(key)'. Keys must start with a letter or underscore and contain only letters, digits, and underscores.")
            return
        }

        if config.environments[index].variables.contains(where: { $0.key == key }) {
            showError(message: "Key '\(key)' already exists in this environment.")
            return
        }

        let variable = EnvironmentVariable(key: key, value: value)
        config.environments[index].variables.append(variable)
        save()
    }

    func updateVariable(envID: UUID, variableID: UUID, key: String, value: String) {
        guard let envIndex = config.environments.firstIndex(where: { $0.id == envID }),
              let varIndex = config.environments[envIndex].variables.firstIndex(where: { $0.id == variableID })
        else { return }

        config.environments[envIndex].variables[varIndex].key = key
        config.environments[envIndex].variables[varIndex].value = value
        save()
    }

    func removeVariable(envID: UUID, variableID: UUID) {
        guard let envIndex = config.environments.firstIndex(where: { $0.id == envID }) else { return }
        config.environments[envIndex].variables.removeAll { $0.id == variableID }
        save()
    }

    // MARK: - Apply

    func applyEnvironment(id: UUID) {
        guard let env = config.environments.first(where: { $0.id == id }) else { return }

        // Write .env file to secure config directory
        let envSuccess = EnvFileService.write(variables: env.variables)
        if !envSuccess {
            showError(message: "Failed to write .env file.")
            return
        }

        // Write .zshrc managed block
        let zshrcSuccess = ZshrcService.apply(variables: env.variables, environmentName: env.name)

        if zshrcSuccess {
            config.activeEnvironment = env.name
            save()
            showApplySuccess = true
        } else {
            showError(message: "Failed to update .zshrc. Check file permissions.")
        }
    }

    // MARK: - Private

    private func save() {
        ConfigService.save(config)
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }

    static func isValidKey(_ key: String) -> Bool {
        let pattern = #"^[A-Za-z_][A-Za-z0-9_]*$"#
        return key.range(of: pattern, options: .regularExpression) != nil
    }
}
