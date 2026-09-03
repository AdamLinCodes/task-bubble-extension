import Foundation

struct BoardItem: Codable, Equatable, Identifiable, Sendable {
  let id: UUID
  var text: String
  var isCrossedOut: Bool

  init(id: UUID = UUID(), text: String, isCrossedOut: Bool = false) {
    self.id = id
    self.text = text
    self.isCrossedOut = isCrossedOut
  }
}
