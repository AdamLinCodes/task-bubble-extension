import XCTest

@testable import TaskBubble

@MainActor
final class AppModelTests: XCTestCase {
  func testInteractiveFlipsReturnBothSurfacesToRoamingMode() {
    let focus = FocusTimerStore(storage: TestDataStore(), startsTicker: false)
    let model = AppModel(board: BoardStore(storage: TestDataStore()), focus: focus)
    model.isPinned = true

    model.flip()

    XCTAssertEqual(model.surface, .focus)
    XCTAssertEqual(model.focus.phase, .running)
    XCTAssertFalse(model.isPinned)

    model.flip()

    XCTAssertEqual(model.surface, .board)
    XCTAssertFalse(model.isPinned)
  }
}
