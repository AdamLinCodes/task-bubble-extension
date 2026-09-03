import AppKit

@MainActor
final class PointerAvoidanceController: NSObject {
  private weak var panel: NSPanel?
  private let model: AppModel
  private let engine: AvoidanceEngine
  private var ticker: Timer?
  private var isMoving = false
  private var lastMoveAt: Date?

  init(panel: NSPanel, model: AppModel, engine: AvoidanceEngine = AvoidanceEngine()) {
    self.panel = panel
    self.model = model
    self.engine = engine
    super.init()

    ticker = Timer.scheduledTimer(
      timeInterval: 1.0 / 30.0,
      target: self,
      selector: #selector(checkPointer),
      userInfo: nil,
      repeats: true
    )
  }

  @objc private func checkPointer() {
    guard let panel, panel.isVisible else { return }
    let optionIsHeld = NSEvent.modifierFlags.contains(.option)
    guard
      let visibleFrame = panel.screen?.visibleFrame
        ?? screenContaining(panel.frame.center)?.visibleFrame
    else {
      return
    }

    guard
      let destination = engine.destination(
        pointer: NSEvent.mouseLocation,
        panelFrame: panel.frame,
        visibleFrame: visibleFrame,
        isPinned: model.isPinned || optionIsHeld,
        isMoving: isMoving,
        lastMoveAt: lastMoveAt,
        now: Date()
      )
    else {
      return
    }

    isMoving = true
    lastMoveAt = Date()
    var targetFrame = panel.frame
    targetFrame.origin = destination

    if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
      panel.setFrameOrigin(destination)
      isMoving = false
      return
    }

    panel.setFrame(targetFrame, display: true, animate: true)
    Task { @MainActor [weak self] in
      try? await Task.sleep(for: .seconds(0.96))
      guard !Task.isCancelled else { return }
      self?.isMoving = false
    }
  }

  private func screenContaining(_ point: CGPoint) -> NSScreen? {
    NSScreen.screens.first { $0.frame.contains(point) }
  }
}

extension CGRect {
  fileprivate var center: CGPoint {
    CGPoint(x: midX, y: midY)
  }
}
