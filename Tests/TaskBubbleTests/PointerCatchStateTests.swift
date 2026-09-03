import CoreGraphics
import XCTest

@testable import TaskBubble

final class PointerCatchStateTests: XCTestCase {
  func testControlCatchRemainsUntilPointerLeavesBubble() {
    var state = PointerCatchState()
    let catchArea = CGRect(x: 86, y: 86, width: 228, height: 128)

    XCTAssertTrue(
      state.suppressesAvoidance(
        pointer: CGPoint(x: 200, y: 150),
        catchArea: catchArea,
        controlIsHeld: true
      ))
    XCTAssertTrue(
      state.suppressesAvoidance(
        pointer: CGPoint(x: 200, y: 150),
        catchArea: catchArea,
        controlIsHeld: false
      ))
    XCTAssertFalse(
      state.suppressesAvoidance(
        pointer: CGPoint(x: 400, y: 150),
        catchArea: catchArea,
        controlIsHeld: false
      ))
  }

  func testHoldingControlAwayFromBubbleDoesNotLatchCatch() {
    var state = PointerCatchState()
    let catchArea = CGRect(x: 86, y: 86, width: 228, height: 128)

    XCTAssertTrue(
      state.suppressesAvoidance(
        pointer: CGPoint(x: 400, y: 150),
        catchArea: catchArea,
        controlIsHeld: true
      ))
    XCTAssertFalse(
      state.suppressesAvoidance(
        pointer: CGPoint(x: 400, y: 150),
        catchArea: catchArea,
        controlIsHeld: false
      ))
  }
}
