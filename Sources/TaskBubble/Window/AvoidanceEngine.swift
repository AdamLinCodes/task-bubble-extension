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
    visibleFrames: [CGRect],
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

    guard let direction = movementDirection(pointer: pointer, panelFrame: panelFrame) else {
      return nil
    }

    if let destination = nearestDestination(
      from: panelFrame.origin,
      panelSize: panelFrame.size,
      visibleFrames: visibleFrames,
      direction: direction
    ) {
      return destination
    }

    return fallbackDestination(
      from: panelFrame.origin,
      panelSize: panelFrame.size,
      visibleFrames: visibleFrames,
      blockedDirection: direction
    )
  }

  private func movementDirection(pointer: CGPoint, panelFrame: CGRect) -> CGVector? {
    let horizontalOffset = (panelFrame.midX - pointer.x) / max(panelFrame.width / 2, 1)
    let verticalOffset = (panelFrame.midY - pointer.y) / max(panelFrame.height / 2, 1)
    let largestOffset = max(abs(horizontalOffset), abs(verticalOffset))

    guard largestOffset > 0.01 else { return nil }

    // Ignore small secondary-axis noise so a side bump stays horizontal or vertical.
    let secondaryAxisThreshold = largestOffset * 0.4
    let dx = abs(horizontalOffset) >= secondaryAxisThreshold ? horizontalOffset.signValue : 0
    let dy = abs(verticalOffset) >= secondaryAxisThreshold ? verticalOffset.signValue : 0
    return CGVector(dx: dx, dy: dy)
  }

  private func nearestDestination(
    from currentOrigin: CGPoint,
    panelSize: CGSize,
    visibleFrames: [CGRect],
    direction: CGVector
  ) -> CGPoint? {
    let panelFrame = CGRect(origin: currentOrigin, size: panelSize)
    let currentVisibleFrame = visibleFrames.max { lhs, rhs in
      intersectionArea(of: lhs, with: panelFrame) < intersectionArea(of: rhs, with: panelFrame)
    }

    return
      visibleFrames
      .compactMap { visibleFrame in
        destinationOrigin(
          in: visibleFrame,
          panelSize: panelSize,
          currentOrigin: currentOrigin,
          direction: direction,
          centersInDisplay: currentVisibleFrame.map { $0 != visibleFrame } ?? false
        )
      }
      .filter { candidate in
        let delta = CGVector(
          dx: candidate.x - currentOrigin.x,
          dy: candidate.y - currentOrigin.y
        )
        let movesHorizontallyAsPushed = direction.dx == 0 || delta.dx * direction.dx >= -2
        let movesVerticallyAsPushed = direction.dy == 0 || delta.dy * direction.dy >= -2
        let directionalProgress = (delta.dx * direction.dx) + (delta.dy * direction.dy)
        return movesHorizontallyAsPushed && movesVerticallyAsPushed && directionalProgress > 2
      }
      .min { lhs, rhs in
        distanceSquared(from: lhs, to: currentOrigin)
          < distanceSquared(from: rhs, to: currentOrigin)
      }
  }

  private func destinationOrigin(
    in visibleFrame: CGRect,
    panelSize: CGSize,
    currentOrigin: CGPoint,
    direction: CGVector,
    centersInDisplay: Bool
  ) -> CGPoint? {
    let minX = visibleFrame.minX + edgeMargin
    let maxX = visibleFrame.maxX - panelSize.width - edgeMargin
    let minY = visibleFrame.minY + edgeMargin
    let maxY = visibleFrame.maxY - panelSize.height - edgeMargin

    guard minX <= maxX, minY <= maxY else { return nil }

    if centersInDisplay {
      return CGPoint(
        x: visibleFrame.midX - (panelSize.width / 2),
        y: visibleFrame.midY - (panelSize.height / 2)
      )
    }

    return CGPoint(
      x: destinationCoordinate(
        current: currentOrigin.x,
        minimum: minX,
        maximum: maxX,
        direction: direction.dx
      ),
      y: destinationCoordinate(
        current: currentOrigin.y,
        minimum: minY,
        maximum: maxY,
        direction: direction.dy
      )
    )
  }

  private func destinationCoordinate(
    current: CGFloat,
    minimum: CGFloat,
    maximum: CGFloat,
    direction: CGFloat
  ) -> CGFloat {
    if direction < 0 { return minimum }
    if direction > 0 { return maximum }
    return min(max(current, minimum), maximum)
  }

  private func fallbackDestination(
    from currentOrigin: CGPoint,
    panelSize: CGSize,
    visibleFrames: [CGRect],
    blockedDirection: CGVector
  ) -> CGPoint? {
    // At the outside edge of the display layout, slide along the edge instead of sticking.
    fallbackDirections(for: blockedDirection)
      .compactMap { direction in
        nearestDestination(
          from: currentOrigin,
          panelSize: panelSize,
          visibleFrames: visibleFrames,
          direction: direction
        )
      }
      .max { lhs, rhs in
        distanceSquared(from: lhs, to: currentOrigin)
          < distanceSquared(from: rhs, to: currentOrigin)
      }
  }

  private func fallbackDirections(for direction: CGVector) -> [CGVector] {
    if direction.dx == 0 {
      return [CGVector(dx: 1, dy: 0), CGVector(dx: -1, dy: 0)]
    }

    if direction.dy == 0 {
      return [CGVector(dx: 0, dy: 1), CGVector(dx: 0, dy: -1)]
    }

    return [
      CGVector(dx: direction.dx, dy: 0),
      CGVector(dx: 0, dy: direction.dy),
      CGVector(dx: -direction.dy, dy: direction.dx),
      CGVector(dx: direction.dy, dy: -direction.dx),
    ]
  }

  private func distanceSquared(from origin: CGPoint, to point: CGPoint) -> CGFloat {
    let dx = origin.x - point.x
    let dy = origin.y - point.y
    return (dx * dx) + (dy * dy)
  }

  private func intersectionArea(of frame: CGRect, with panelFrame: CGRect) -> CGFloat {
    let intersection = frame.intersection(panelFrame)
    guard !intersection.isNull else { return 0 }
    return intersection.width * intersection.height
  }
}

extension CGFloat {
  fileprivate var signValue: CGFloat {
    self < 0 ? -1 : 1
  }
}
