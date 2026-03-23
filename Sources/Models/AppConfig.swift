import Foundation

struct AppConfig: Codable {
    var activeEnvironment: String?
    var environments: [AppEnvironment]

    static var `default`: AppConfig {
        AppConfig(
            activeEnvironment: nil,
            environments: []
        )
    }
}
