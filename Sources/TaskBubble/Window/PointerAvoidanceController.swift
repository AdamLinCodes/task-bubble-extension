import AppKit

@MainActor
final class PointerAvoidanceController: NSObject {
  private weak var panel: NSPanel?
  private let model: AppModel
  private let engine: AvoidanceEngine
  private var ticker: Timer?
  private var isMoving = false
  private var lastMoveAt: Date?
  private var catchState = PointerCatchState()

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
    let pointer = NSEvent.mouseLocation
    let controlIsHeld = NSEvent.modifierFlags.contains(.control)
    let catchArea = panel.frame.insetBy(
      dx: -engine.triggerPadding,
      dy: -engine.triggerPadding
    )
    let catchSuppressesAvoidance = catchState.suppressesAvoidance(
      pointer: pointer,
      catchArea: catchArea,
      controlIsHeld: controlIsHeld
    )
    guard
      let visibleFrame = panel.screen?.visibleFrame
        ?? screenContaining(panel.frame.center)?.visibleFrame
    else {
      return
    }

    guard
      let destination = engine.destination(
        pointer: pointer,
        panelFrame: panel.frame,
        visibleFrame: visibleFrame,
        isPinned: model.isPinned || catchSuppressesAvoidance,
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

struct PointerCatchState {
  private var isCaught = false

  mutating func suppressesAvoidance(
    pointer: CGPoint,
    catchArea: CGRect,
    controlIsHeld: Bool
  ) -> Bool {
    if controlIsHeld {
      isCaught = isCaught || catchArea.contains(pointer)
      return true
    }

    if isCaught, !catchArea.contains(pointer) {
      isCaught = false
    }

    return isCaught
  }
}

extension CGRect {
  fileprivate var center: CGPoint {
    CGPoint(x: midX, y: midY)
  }
}
