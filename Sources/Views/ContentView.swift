import SwiftUI

struct ContentView: View {
    @State private var viewModel = EnvironmentViewModel()
    var body: some View {
        NavigationSplitView {
            EnvironmentListView(viewModel: viewModel)
        } detail: {
            VariableEditorView(viewModel: viewModel)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                if let url = Bundle.main.url(forResource: "envBunny-logo", withExtension: "png"),
                   let nsImage = NSImage(contentsOf: url) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 20)
                }
            }

            ToolbarItem(placement: .automatic) {
                ImportButton(viewModel: viewModel)
            }

            ToolbarItem(placement: .automatic) {
                if let env = viewModel.selectedEnvironment {
                    ExportButton(environment: env)
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred.")
        }
        .alert("Environment Applied", isPresented: $viewModel.showApplySuccess) {
            Button("OK") {}
        } message: {
            Text("Environment has been applied. Run 'source ~/.zshrc' in open terminals to pick up the changes.")
        }
    }
}

#Preview {
    ContentView()
}
