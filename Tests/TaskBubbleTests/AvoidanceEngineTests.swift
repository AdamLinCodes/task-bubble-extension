import CoreGraphics
import Foundation
import XCTest

@testable import TaskBubble

final class AvoidanceEngineTests: XCTestCase {
  private let engine = AvoidanceEngine()
  private let now = Date(timeIntervalSince1970: 10_000)

  func testRightSideContactMovesLeftWithoutChangingHeight() {
    let visibleFrame = CGRect(x: 0, y: 0, width: 1_000, height: 800)
    let panel = CGRect(x: 400, y: 300, width: 200, height: 100)
    let pointer = CGPoint(x: 605, y: 350)

    let destination = engine.destination(
      pointer: pointer,
      panelFrame: panel,
      visibleFrames: [visibleFrame],
      isPinned: false,
      isMoving: false,
      lastMoveAt: nil,
      now: now
    )

    XCTAssertEqual(destination, CGPoint(x: 12, y: 300))
  }

  func testBottomRightContactMovesTowardTopLeft() {
    let visibleFrame = CGRect(x: 0, y: 0, width: 1_000, height: 800)
    let panel = CGRect(x: 400, y: 300, width: 200, height: 100)
    let pointer = CGPoint(x: 605, y: 295)

    let destination = engine.destination(
      pointer: pointer,
      panelFrame: panel,
      visibleFrames: [visibleFrame],
      isPinned: false,
      isMoving: false,
      lastMoveAt: nil,
      now: now
    )

    XCTAssertEqual(destination, CGPoint(x: 12, y: 688))
  }

  func testPushAtDisplayEdgeMovesOntoAdjacentDisplay() {
    let leftDisplay = CGRect(x: -2_560, y: 131, width: 2_560, height: 1_440)
    let rightDisplay = CGRect(x: 0, y: 87, width: 1_710, height: 986)
    let panel = CGRect(x: 12, y: 300, width: 330, height: 250)
    let pointer = CGPoint(x: 347, y: 425)

    let destination = engine.destination(
      pointer: pointer,
      panelFrame: panel,
      visibleFrames: [rightDisplay, leftDisplay],
      isPinned: false,
      isMoving: false,
      lastMoveAt: nil,
      now: now
    )

    XCTAssertEqual(destination, CGPoint(x: -2_548, y: 300))
  }

  func testThreeDisplayLayoutMovesToTheNextDisplayWithoutSkippingIt() {
    let farLeftDisplay = CGRect(x: -2_400, y: 0, width: 1_200, height: 900)
    let leftDisplay = CGRect(x: -1_200, y: 0, width: 1_200, height: 900)
    let rightDisplay = CGRect(x: 0, y: 0, width: 1_000, height: 800)
    let panel = CGRect(x: 12, y: 300, width: 200, height: 100)
    let pointer = CGPoint(x: 217, y: 350)

    let destination = engine.destination(
      pointer: pointer,
      panelFrame: panel,
      visibleFrames: [farLeftDisplay, rightDisplay, leftDisplay],
      isPinned: false,
      isMoving: false,
      lastMoveAt: nil,
      now: now
    )

    XCTAssertEqual(destination, CGPoint(x: -1_188, y: 300))
  }

  func testCrossScreenMoveClampsOnlyTheOffsetAxis() {
    let lowerDisplay = CGRect(x: 0, y: -500, width: 1_000, height: 500)
    let upperDisplay = CGRect(x: 0, y: 0, width: 1_000, height: 800)
    let panel = CGRect(x: 400, y: 12, width: 200, height: 100)
    let pointer = CGPoint(x: 500, y: 117)

    let destination = engine.destination(
      pointer: pointer,
      panelFrame: panel,
      visibleFrames: [upperDisplay, lowerDisplay],
      isPinned: false,
      isMoving: false,
      lastMoveAt: nil,
      now: now
    )

    XCTAssertEqual(destination, CGPoint(x: 400, y: -488))
  }

  func testPushAgainstOuterEdgeSlidesAlongEdgeInsteadOfSticking() {
    let visibleFrame = CGRect(x: 0, y: 0, width: 1_000, height: 800)
    let panel = CGRect(x: 12, y: 300, width: 200, height: 100)
    let pointer = CGPoint(x: 217, y: 350)

    let destination = engine.destination(
      pointer: pointer,
      panelFrame: panel,
      visibleFrames: [visibleFrame],
      isPinned: false,
      isMoving: false,
      lastMoveAt: nil,
      now: now
    )

    XCTAssertEqual(destination, CGPoint(x: 12, y: 688))
  }

  func testPinnedMovingAndCooldownStatesDoNotMove() {
    let visibleFrame = CGRect(x: 0, y: 0, width: 1_000, height: 800)
    let panel = CGRect(x: 708, y: 538, width: 280, height: 250)
    let pointer = CGPoint(x: 850, y: 650)

    XCTAssertNil(destination(pointer, panel, visibleFrame, isPinned: true))
    XCTAssertNil(
      engine.destination(
        pointer: pointer,
        panelFrame: panel,
        visibleFrames: [visibleFrame],
        isPinned: false,
        isMoving: true,
        lastMoveAt: nil,
        now: now
      ))
    XCTAssertNil(
      engine.destination(
        pointer: pointer,
        panelFrame: panel,
        visibleFrames: [visibleFrame],
        isPinned: false,
        isMoving: false,
        lastMoveAt: now.addingTimeInterval(-0.2),
        now: now
      ))
  }

  func testSingleDisplayWithNegativeOriginRemainsValid() {
    let visibleFrame = CGRect(x: -1_440, y: 0, width: 1_440, height: 900)
    let panel = CGRect(x: -1_000, y: 300, width: 210, height: 210)
    let pointer = CGPoint(x: -785, y: 405)

    let destination = engine.destination(
      pointer: pointer,
      panelFrame: panel,
      visibleFrames: [visibleFrame],
      isPinned: false,
      isMoving: false,
      lastMoveAt: nil,
      now: now
    )

    XCTAssertEqual(destination, CGPoint(x: -1_428, y: 300))
  }

  private func destination(
    _ pointer: CGPoint,
    _ panel: CGRect,
    _ visibleFrame: CGRect,
    isPinned: Bool
  ) -> CGPoint? {
    engine.destination(
      pointer: pointer,
      panelFrame: panel,
      visibleFrames: [visibleFrame],
      isPinned: isPinned,
      isMoving: false,
      lastMoveAt: nil,
      now: now
    )
  }
}
