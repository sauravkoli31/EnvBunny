import SwiftUI

struct EnvironmentListView: View {
    @Bindable var viewModel: EnvironmentViewModel
    @State private var showNewSheet = false
    @State private var environmentToDelete: AppEnvironment?
    @State private var renamingID: UUID?
    @State private var renameText = ""

    var body: some View {
        List(selection: $viewModel.selectedEnvironmentID) {
            Section {
                ForEach(viewModel.config.environments) { env in
                    if renamingID == env.id {
                        TextField("Name", text: $renameText, onCommit: {
                            viewModel.renameEnvironment(id: env.id, newName: renameText)
                            renamingID = nil
                        })
                        .textFieldStyle(.plain)
                    } else {
                        EnvironmentRowView(
                            environment: env,
                            isActive: viewModel.config.activeEnvironment == env.name
                        )
                        .tag(env.id)
                        .contextMenu {
                            Button("Rename") {
                                renameText = env.name
                                renamingID = env.id
                            }
                            Button("Duplicate") {
                                viewModel.duplicateEnvironment(id: env.id)
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                environmentToDelete = env
                            }
                        }
                    }
                }
            } header: {
                Text("Environments")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                showNewSheet = true
            } label: {
                Label("New Environment", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .padding(8)
        }
        .navigationTitle("Environments")
        .sheet(isPresented: $showNewSheet) {
            NewEnvironmentSheet(viewModel: viewModel)
        }
        .alert("Delete Environment?", isPresented: .init(
            get: { environmentToDelete != nil },
            set: { if !$0 { environmentToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                environmentToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let env = environmentToDelete {
                    viewModel.deleteEnvironment(id: env.id)
                }
                environmentToDelete = nil
            }
        } message: {
            if let env = environmentToDelete {
                Text("Are you sure you want to delete '\(env.name)'? This cannot be undone.")
            }
        }
    }
}
