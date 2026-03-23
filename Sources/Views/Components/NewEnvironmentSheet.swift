import SwiftUI

struct NewEnvironmentSheet: View {
    @Bindable var viewModel: EnvironmentViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        VStack(spacing: 16) {
            Label("New", systemImage: "plus")
                .font(.headline)

            TextField("Environment name", text: $name)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    create()
                }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Create") {
                    create()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 300)
    }

    private func create() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        viewModel.createEnvironment(name: trimmed)
        dismiss()
    }
}
