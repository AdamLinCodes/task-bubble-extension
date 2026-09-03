import AppKit
import SwiftUI
import XCTest

@testable import TaskBubble

@MainActor
final class BoardViewRenderingTests: XCTestCase {
  func testBoardWindowCornersAreTransparent() throws {
    let model = AppModel(
      board: BoardStore(storage: TestDataStore()),
      focus: FocusTimerStore(storage: TestDataStore(), startsTicker: false)
    )
    let hostingView = NSHostingView(rootView: BoardView(model: model, board: model.board))
    hostingView.frame = CGRect(x: 0, y: 0, width: 330, height: 250)
    hostingView.layoutSubtreeIfNeeded()

    let bitmap = try XCTUnwrap(hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds))
    hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)

    let corners = [
      (0, 0),
      (bitmap.pixelsWide - 1, 0),
      (0, bitmap.pixelsHigh - 1),
      (bitmap.pixelsWide - 1, bitmap.pixelsHigh - 1),
    ]

    for (x, y) in corners {
      let alpha = try XCTUnwrap(bitmap.colorAt(x: x, y: y)).alphaComponent
      XCTAssertEqual(alpha, 0, accuracy: 0.001, "Expected corner (\(x), \(y)) to be transparent")
    }
  }
}
