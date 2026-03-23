import SwiftUI

struct VariableRowView: View {
    let variable: EnvironmentVariable
    let onUpdate: (String, String) -> Void
    let onDelete: () -> Void

    @State private var editingKey: String
    @State private var editingValue: String

    init(variable: EnvironmentVariable, onUpdate: @escaping (String, String) -> Void, onDelete: @escaping () -> Void) {
        self.variable = variable
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self._editingKey = State(initialValue: variable.key)
        self._editingValue = State(initialValue: variable.value)
    }

    var body: some View {
        HStack(spacing: 8) {
            TextField("KEY", text: $editingKey)
                .textFieldStyle(.plain)
                .fontDesign(.monospaced)
                .frame(maxWidth: 200)
                .onSubmit { commitChanges() }
                .onChange(of: editingKey) { _, _ in commitChanges() }

            Text("=")
                .foregroundStyle(.secondary)

            TextField("value", text: $editingValue)
                .textFieldStyle(.plain)
                .fontDesign(.monospaced)
                .onSubmit { commitChanges() }
                .onChange(of: editingValue) { _, _ in commitChanges() }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private func commitChanges() {
        let key = editingKey.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { return }
        if key != variable.key || editingValue != variable.value {
            onUpdate(key, editingValue)
        }
    }
}
