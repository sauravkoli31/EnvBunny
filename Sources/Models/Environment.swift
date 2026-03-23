import Foundation

struct EnvironmentVariable: Codable, Identifiable, Hashable {
    var id = UUID()
    var key: String
    var value: String
}

struct AppEnvironment: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var variables: [EnvironmentVariable]
}
