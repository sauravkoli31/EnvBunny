import SwiftUI

struct EnvironmentRowView: View {
    let environment: AppEnvironment
    let isActive: Bool

    var body: some View {
        HStack {
            if isActive {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
            }

            Text(environment.name)

            Spacer()

            Text("\(environment.variables.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
