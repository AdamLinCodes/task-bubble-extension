import Foundation
import XCTest

@testable import TaskBubble

@MainActor
final class FocusTimerStoreTests: XCTestCase {
  func testThirtyMinuteTimerSurvivesPauseAndResumeWithoutDrift() {
    let clock = TestClock(now: Date(timeIntervalSince1970: 1_000))
    let timer = FocusTimerStore(
      storage: TestDataStore(),
      now: { clock.now },
      startsTicker: false
    )

    timer.start()
    XCTAssertEqual(timer.remaining, 1_800, accuracy: 0.001)

    clock.now = clock.now.addingTimeInterval(600)
    timer.refresh()
    XCTAssertEqual(timer.remaining, 1_200, accuracy: 0.001)

    timer.pause()
    clock.now = clock.now.addingTimeInterval(300)
    timer.refresh()
    XCTAssertEqual(timer.remaining, 1_200, accuracy: 0.001)

    timer.resume()
    clock.now = clock.now.addingTimeInterval(1_200)
    timer.refresh()
    XCTAssertEqual(timer.phase, .completed)
    XCTAssertEqual(timer.remaining, 0, accuracy: 0.001)
  }

  func testRunningTimerRestoresFromItsDeadline() {
    let storage = TestDataStore()
    let clock = TestClock(now: Date(timeIntervalSince1970: 2_000))
    let original = FocusTimerStore(storage: storage, now: { clock.now }, startsTicker: false)
    original.start()

    clock.now = clock.now.addingTimeInterval(75)
    let restored = FocusTimerStore(storage: storage, now: { clock.now }, startsTicker: false)

    XCTAssertEqual(restored.phase, .running)
    XCTAssertEqual(restored.remaining, 1_725, accuracy: 0.001)
  }
}
