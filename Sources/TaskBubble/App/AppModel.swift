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
  private let quitHandler: () -> Void

  init(
    board: BoardStore = BoardStore(),
    focus: FocusTimerStore = FocusTimerStore(),
    quitHandler: @escaping () -> Void = {}
  ) {
    self.board = board
    self.focus = focus
    self.quitHandler = quitHandler
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
    } else {
      surface = .board
    }
  }

  func presentCompletedFocus() {
    surface = .focus
    isPinned = true
  }

  func quit() {
    quitHandler()
  }
}
