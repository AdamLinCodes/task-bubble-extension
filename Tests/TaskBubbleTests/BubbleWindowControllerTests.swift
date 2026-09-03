import XCTest

@testable import TaskBubble

@MainActor
final class BubbleWindowControllerTests: XCTestCase {
  func testCreatingWindowControllerPreservesBoardWindowSize() {
    let storage = TestDataStore()
    let model = AppModel(
      board: BoardStore(storage: storage),
      focus: FocusTimerStore(storage: storage, startsTicker: false)
    )

    let controller = BubbleWindowController(model: model)

    XCTAssertEqual(controller.panel.frame.width, 330)
    XCTAssertEqual(controller.panel.frame.height, 250)
  }
}
