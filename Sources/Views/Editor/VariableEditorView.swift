import SwiftUI

struct VariableEditorView: View {
    @Bindable var viewModel: EnvironmentViewModel

    @State private var newKey = ""
    @State private var newValue = ""
    @State private var keyValidationError: String?

    var body: some View {
        if let env = viewModel.selectedEnvironment {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(env.name)
                                .font(.title2.bold())

                            if viewModel.config.activeEnvironment == env.name {
                                Text("Active")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(.green.opacity(0.2))
                                    .foregroundStyle(.green)
                                    .clipShape(Capsule())
                            }
                        }

                        Text("\(env.variables.count) variable\(env.variables.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    ApplyButton(viewModel: viewModel, environmentID: env.id)
                }
                .padding()

                Divider()

                // Variable list
                if env.variables.isEmpty {
                    Spacer()
                    Text("No variables yet. Add one below.")
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    List {
                        ForEach(env.variables) { variable in
                            VariableRowView(
                                variable: variable,
                                onUpdate: { key, value in
                                    viewModel.updateVariable(envID: env.id, variableID: variable.id, key: key, value: value)
                                },
                                onDelete: {
                                    viewModel.removeVariable(envID: env.id, variableID: variable.id)
                                }
                            )
                        }
                    }
                }

                Divider()

                // Add variable form
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        TextField("KEY", text: $newKey)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 200)
                            .onChange(of: newKey) { _, newValue in
                                validateKey(newValue, in: env)
                            }
                            .onSubmit { addVariable(envID: env.id) }

                        TextField("value", text: $newValue)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit { addVariable(envID: env.id) }

                        Button {
                            addVariable(envID: env.id)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        .disabled(newKey.trimmingCharacters(in: .whitespaces).isEmpty || keyValidationError != nil)
                    }

                    if let error = keyValidationError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
            }
        } else {
            Text("Select an environment")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func addVariable(envID: UUID) {
        let key = newKey.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty, keyValidationError == nil else { return }
        viewModel.addVariable(to: envID, key: key, value: newValue)
        newKey = ""
        newValue = ""
        keyValidationError = nil
    }

    private func validateKey(_ key: String, in env: AppEnvironment) {
        let trimmed = key.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            keyValidationError = nil
        } else if !EnvironmentViewModel.isValidKey(trimmed) {
            keyValidationError = "Keys must start with a letter/underscore, containing only letters, digits, underscores."
        } else if env.variables.contains(where: { $0.key == trimmed }) {
            keyValidationError = "Key '\(trimmed)' already exists."
        } else {
            keyValidationError = nil
        }
    }
}
