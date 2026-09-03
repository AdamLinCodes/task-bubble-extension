import XCTest

@testable import TaskBubble

@MainActor
final class AppModelTests: XCTestCase {
  func testInteractiveFlipsPreservePinnedState() {
    let focus = FocusTimerStore(storage: TestDataStore(), startsTicker: false)
    let model = AppModel(board: BoardStore(storage: TestDataStore()), focus: focus)
    model.isPinned = true

    model.flip()

    XCTAssertEqual(model.surface, .focus)
    XCTAssertEqual(model.focus.phase, .running)
    XCTAssertTrue(model.isPinned)

    model.flip()

    XCTAssertEqual(model.surface, .board)
    XCTAssertTrue(model.isPinned)
  }

  func testQuitRunsApplicationQuitHandler() {
    var didQuit = false
    let model = AppModel(
      board: BoardStore(storage: TestDataStore()),
      focus: FocusTimerStore(storage: TestDataStore(), startsTicker: false),
      quitHandler: { didQuit = true }
    )

    model.quit()

    XCTAssertTrue(didQuit)
  }
}
