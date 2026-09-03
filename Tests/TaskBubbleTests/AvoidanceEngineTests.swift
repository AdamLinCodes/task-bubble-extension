import CoreGraphics
import Foundation
import XCTest

@testable import TaskBubble

final class AvoidanceEngineTests: XCTestCase {
  private let engine = AvoidanceEngine()
  private let now = Date(timeIntervalSince1970: 10_000)

  func testPointerNearPanelMovesItToTheFarthestCorner() {
    let visibleFrame = CGRect(x: 0, y: 0, width: 1_000, height: 800)
    let panel = CGRect(x: 708, y: 538, width: 280, height: 250)
    let pointer = CGPoint(x: 850, y: 650)

    let destination = engine.destination(
      pointer: pointer,
      panelFrame: panel,
      visibleFrame: visibleFrame,
      isPinned: false,
      isMoving: false,
      lastMoveAt: nil,
      now: now
    )

    XCTAssertEqual(destination, CGPoint(x: 12, y: 12))
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
        visibleFrame: visibleFrame,
        isPinned: false,
        isMoving: true,
        lastMoveAt: nil,
        now: now
      ))
    XCTAssertNil(
      engine.destination(
        pointer: pointer,
        panelFrame: panel,
        visibleFrame: visibleFrame,
        isPinned: false,
        isMoving: false,
        lastMoveAt: now.addingTimeInterval(-0.2),
        now: now
      ))
  }

  func testNegativeDisplayOriginsRemainValid() {
    let visibleFrame = CGRect(x: -1_440, y: 0, width: 1_440, height: 900)
    let panel = CGRect(x: -1_428, y: 12, width: 210, height: 210)
    let pointer = CGPoint(x: -1_350, y: 80)

    let destination = engine.destination(
      pointer: pointer,
      panelFrame: panel,
      visibleFrame: visibleFrame,
      isPinned: false,
      isMoving: false,
      lastMoveAt: nil,
      now: now
    )

    XCTAssertEqual(destination, CGPoint(x: -222, y: 678))
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
      visibleFrame: visibleFrame,
      isPinned: isPinned,
      isMoving: false,
      lastMoveAt: nil,
      now: now
    )
  }
}
