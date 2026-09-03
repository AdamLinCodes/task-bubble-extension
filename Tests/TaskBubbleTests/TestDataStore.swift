import Foundation

@testable import TaskBubble

final class TestDataStore: DataStore, @unchecked Sendable {
  private var values: [String: Data] = [:]

  func data(forKey key: String) -> Data? {
    values[key]
  }

  func set(_ data: Data?, forKey key: String) {
    values[key] = data
  }
}

final class TestClock: @unchecked Sendable {
  var now: Date

  init(now: Date) {
    self.now = now
  }
}
