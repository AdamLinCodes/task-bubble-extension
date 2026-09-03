import Combine
import Foundation

enum BubbleSurface: String, Codable, Sendable {
  case board
  case focus
}

@MainActor
final class AppModel: ObservableObject {
  @Published var surface: BubbleSurface = .board
  @Published var isPinned = false

  let board: BoardStore
  let focus: FocusTimerStore

  init(
    board: BoardStore = BoardStore(),
    focus: FocusTimerStore = FocusTimerStore()
  ) {
    self.board = board
    self.focus = focus
  }

  func showBoard(pin: Bool = true) {
    surface = .board
    isPinned = pin
  }

  func showFocus(startIfNeeded: Bool = false) {
    surface = .focus
    if startIfNeeded, focus.phase == .idle || focus.phase == .completed {
      focus.start()
    }
  }

  func flip() {
    if surface == .board {
      showFocus(startIfNeeded: true)
      isPinned = false
    } else {
      showBoard(pin: false)
    }
  }
}
