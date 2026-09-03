import Combine
import Foundation

@MainActor
final class BoardStore: ObservableObject {
  @Published private(set) var items: [BoardItem]

  private let storage: any DataStore
  private let storageKey: String
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()

  init(
    storage: any DataStore = UserDefaultsDataStore(),
    storageKey: String = "taskBubble.board.v2"
  ) {
    self.storage = storage
    self.storageKey = storageKey

    if let data = storage.data(forKey: storageKey),
      let storedItems = try? decoder.decode([BoardItem].self, from: data)
    {
      items = storedItems
    } else {
      items = []
    }
  }

  @discardableResult
  func add(_ text: String) -> BoardItem? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    let item = BoardItem(text: trimmed)
    items.append(item)
    persist()
    return item
  }

  func update(id: UUID, text: String) {
    guard let index = items.firstIndex(where: { $0.id == id }) else { return }
    items[index].text = text
    persist()
  }

  func toggleCrossedOut(id: UUID) {
    guard let index = items.firstIndex(where: { $0.id == id }) else { return }
    items[index].isCrossedOut.toggle()
    persist()
  }

  func delete(id: UUID) {
    items.removeAll { $0.id == id }
    persist()
  }

  func clear() {
    guard !items.isEmpty else { return }
    items = []
    persist()
  }

  private func persist() {
    guard let data = try? encoder.encode(items) else { return }
    storage.set(data, forKey: storageKey)
  }
}
