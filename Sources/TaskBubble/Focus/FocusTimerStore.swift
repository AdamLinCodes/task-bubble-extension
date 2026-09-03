import Combine
import Foundation

enum FocusPhase: String, Codable, Equatable, Sendable {
  case idle
  case running
  case paused
  case completed
}

private struct FocusTimerSnapshot: Codable {
  var phase: FocusPhase
  var duration: TimeInterval
  var remainingWhenPaused: TimeInterval
  var deadline: Date?
}

@MainActor
final class FocusTimerStore: NSObject, ObservableObject {
  static let defaultDuration: TimeInterval = 30 * 60

  @Published private(set) var phase: FocusPhase = .idle
  @Published private(set) var remaining: TimeInterval = defaultDuration
  @Published private(set) var deadline: Date?

  var onDeadlineChanged: ((Date?) -> Void)?
  var onCompleted: (() -> Void)?

  private let storage: any DataStore
  private let storageKey: String
  private let now: () -> Date
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()
  private var ticker: Timer?
  private var configuredDuration: TimeInterval = defaultDuration

  init(
    storage: any DataStore = UserDefaultsDataStore(),
    storageKey: String = "taskBubble.focusTimer.v2",
    now: @escaping () -> Date = Date.init,
    startsTicker: Bool = true
  ) {
    self.storage = storage
    self.storageKey = storageKey
    self.now = now
    super.init()
    restore()
    refresh()

    if startsTicker {
      ticker = Timer.scheduledTimer(
        timeInterval: 0.5,
        target: self,
        selector: #selector(tick),
        userInfo: nil,
        repeats: true
      )
    }
  }

  func start(duration: TimeInterval = defaultDuration) {
    configuredDuration = duration
    remaining = duration
    deadline = now().addingTimeInterval(duration)
    phase = .running
    persist()
    onDeadlineChanged?(deadline)
  }

  func pause() {
    guard phase == .running else { return }
    refresh()
    guard phase == .running else { return }
    deadline = nil
    phase = .paused
    persist()
    onDeadlineChanged?(nil)
  }

  func resume() {
    guard phase == .paused, remaining > 0 else { return }
    deadline = now().addingTimeInterval(remaining)
    phase = .running
    persist()
    onDeadlineChanged?(deadline)
  }

  func reset() {
    phase = .idle
    remaining = configuredDuration
    deadline = nil
    persist()
    onDeadlineChanged?(nil)
  }

  func toggleRunning() {
    switch phase {
    case .idle, .completed:
      start()
    case .running:
      pause()
    case .paused:
      resume()
    }
  }

  func refresh() {
    guard phase == .running, let deadline else { return }
    let nextRemaining = max(0, deadline.timeIntervalSince(now()))
    remaining = nextRemaining

    guard nextRemaining <= 0 else { return }
    phase = .completed
    self.deadline = nil
    persist()
    onDeadlineChanged?(nil)
    onCompleted?()
  }

  var displayTime: String {
    let totalSeconds = max(0, Int(ceil(remaining)))
    return String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
  }

  var progress: Double {
    guard configuredDuration > 0 else { return 0 }
    return min(1, max(0, 1 - (remaining / configuredDuration)))
  }

  @objc private func tick() {
    refresh()
  }

  private func restore() {
    guard let data = storage.data(forKey: storageKey),
      let snapshot = try? decoder.decode(FocusTimerSnapshot.self, from: data)
    else {
      return
    }

    phase = snapshot.phase
    configuredDuration = snapshot.duration
    remaining = snapshot.remainingWhenPaused
    deadline = snapshot.deadline
  }

  private func persist() {
    let snapshot = FocusTimerSnapshot(
      phase: phase,
      duration: configuredDuration,
      remainingWhenPaused: remaining,
      deadline: deadline
    )
    guard let data = try? encoder.encode(snapshot) else { return }
    storage.set(data, forKey: storageKey)
  }
}
