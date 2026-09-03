import CoreGraphics
import Foundation

struct AvoidanceEngine: Sendable {
  let edgeMargin: CGFloat
  let triggerPadding: CGFloat
  let cooldown: TimeInterval

  init(
    edgeMargin: CGFloat = 12,
    triggerPadding: CGFloat = 14,
    cooldown: TimeInterval = 0.9
  ) {
    self.edgeMargin = edgeMargin
    self.triggerPadding = triggerPadding
    self.cooldown = cooldown
  }

  func destination(
    pointer: CGPoint,
    panelFrame: CGRect,
    visibleFrame: CGRect,
    isPinned: Bool,
    isMoving: Bool,
    lastMoveAt: Date?,
    now: Date
  ) -> CGPoint? {
    guard !isPinned, !isMoving else { return nil }

    if let lastMoveAt, now.timeIntervalSince(lastMoveAt) < cooldown {
      return nil
    }

    guard panelFrame.insetBy(dx: -triggerPadding, dy: -triggerPadding).contains(pointer) else {
      return nil
    }

    let minX = visibleFrame.minX + edgeMargin
    let maxX = visibleFrame.maxX - panelFrame.width - edgeMargin
    let minY = visibleFrame.minY + edgeMargin
    let maxY = visibleFrame.maxY - panelFrame.height - edgeMargin
    let candidates = [
      CGPoint(x: minX, y: minY),
      CGPoint(x: minX, y: maxY),
      CGPoint(x: maxX, y: minY),
      CGPoint(x: maxX, y: maxY),
    ]

    let currentOrigin = panelFrame.origin
    return
      candidates
      .filter { hypot($0.x - currentOrigin.x, $0.y - currentOrigin.y) > 2 }
      .max { lhs, rhs in
        distanceSquared(from: lhs, to: pointer) < distanceSquared(from: rhs, to: pointer)
      }
  }

  private func distanceSquared(from origin: CGPoint, to point: CGPoint) -> CGFloat {
    let dx = origin.x - point.x
    let dy = origin.y - point.y
    return (dx * dx) + (dy * dy)
  }
}
