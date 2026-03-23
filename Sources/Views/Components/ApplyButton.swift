import SwiftUI

struct ApplyButton: View {
    @Bindable var viewModel: EnvironmentViewModel
    let environmentID: UUID
    @State private var showConfirmation = false

    private var environmentName: String {
        viewModel.config.environments.first { $0.id == environmentID }?.name ?? ""
    }

    private var isActive: Bool {
        viewModel.config.activeEnvironment == environmentName
    }

    var body: some View {
        Button {
            showConfirmation = true
        } label: {
            Label(isActive ? "Re-apply" : "Apply", systemImage: "checkmark.circle")
        }
        .buttonStyle(.borderedProminent)
        .tint(isActive ? .gray : .accentColor)
        .confirmationDialog(
            "Apply '\(environmentName)'?",
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            Button("Apply") {
                viewModel.applyEnvironment(id: environmentID)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will update your .env file and .zshrc with this environment's variables.")
        }
    }
}
