import Foundation

protocol DataStore: Sendable {
  func data(forKey key: String) -> Data?
  func set(_ data: Data?, forKey key: String)
}

struct UserDefaultsDataStore: DataStore, @unchecked Sendable {
  private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  func data(forKey key: String) -> Data? {
    defaults.data(forKey: key)
  }

  func set(_ data: Data?, forKey key: String) {
    defaults.set(data, forKey: key)
  }
}
