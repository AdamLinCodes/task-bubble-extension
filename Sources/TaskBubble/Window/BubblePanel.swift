import AppKit

final class BubblePanel: NSPanel {
  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { false }

  override func animationResizeTime(_ newFrame: NSRect) -> TimeInterval {
    0.96
  }
}
