import XCTest

@testable import TaskBubble

@MainActor
final class BoardStoreTests: XCTestCase {
  func testCrossingOutKeepsTheLineInPlaceAndPersists() {
    let storage = TestDataStore()
    let board = BoardStore(storage: storage)
    let first = board.add("Write launch notes")!
    let second = board.add("Email the designer")!
    let third = board.add("Investigate billing")!

    board.toggleCrossedOut(id: second.id)

    XCTAssertEqual(board.items.map(\.id), [first.id, second.id, third.id])
    XCTAssertEqual(board.items.map(\.isCrossedOut), [false, true, false])

    let restored = BoardStore(storage: storage)
    XCTAssertEqual(restored.items, board.items)
  }

  func testBlankLinesAreIgnoredAndExistingLinesCanBeEditedOrDeleted() {
    let board = BoardStore(storage: TestDataStore())
    XCTAssertNil(board.add("   \n"))

    let item = board.add("First draft")!
    board.update(id: item.id, text: "Final draft")
    XCTAssertEqual(board.items.first?.text, "Final draft")

    board.delete(id: item.id)
    XCTAssertTrue(board.items.isEmpty)
  }

  func testClearDeletesEveryLineAndPersistsTheEmptyBoard() {
    let storage = TestDataStore()
    let board = BoardStore(storage: storage)
    board.add("First line")
    board.add("Second line")

    board.clear()

    XCTAssertTrue(board.items.isEmpty)
    XCTAssertTrue(BoardStore(storage: storage).items.isEmpty)
  }
}
