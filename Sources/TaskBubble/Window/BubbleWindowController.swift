import AppKit
import Combine
import SwiftUI

@MainActor
final class BubbleWindowController {
  let panel: BubblePanel

  private let model: AppModel
  private var avoidanceController: PointerAvoidanceController?
  private var surfaceCancellable: AnyCancellable?

  init(model: AppModel) {
    self.model = model

    let initialSize = Self.size(for: model.surface)
    let initialFrame = Self.initialFrame(size: initialSize)
    panel = BubblePanel(
      contentRect: initialFrame,
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )

    panel.isFloatingPanel = true
    panel.level = .statusBar
    panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = false
    panel.hidesOnDeactivate = false
    panel.isMovableByWindowBackground = true
    panel.isReleasedWhenClosed = false
    panel.animationBehavior = .utilityWindow
    panel.contentViewController = NSHostingController(rootView: BubbleRootView(model: model))

    avoidanceController = PointerAvoidanceController(panel: panel, model: model)
    surfaceCancellable = model.$surface
      .dropFirst()
      .sink { [weak self] surface in
        Task { @MainActor in
          self?.resize(for: surface)
        }
      }

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(screenConfigurationChanged),
      name: NSApplication.didChangeScreenParametersNotification,
      object: nil
    )
    NSWorkspace.shared.notificationCenter.addObserver(
      self,
      selector: #selector(workspaceVisibilityChanged),
      name: NSWorkspace.didActivateApplicationNotification,
      object: nil
    )
    NSWorkspace.shared.notificationCenter.addObserver(
      self,
      selector: #selector(workspaceVisibilityChanged),
      name: NSWorkspace.activeSpaceDidChangeNotification,
      object: nil
    )
  }

  func show() {
    panel.orderFrontRegardless()
  }

  @objc private func screenConfigurationChanged() {
    constrainToVisibleScreen()
    panel.orderFrontRegardless()
  }

  @objc private func workspaceVisibilityChanged() {
    panel.orderFrontRegardless()
  }

  private func resize(for surface: BubbleSurface) {
    let nextSize = Self.size(for: surface)
    let center = CGPoint(x: panel.frame.midX, y: panel.frame.midY)
    var nextFrame = CGRect(
      x: center.x - (nextSize.width / 2),
      y: center.y - (nextSize.height / 2),
      width: nextSize.width,
      height: nextSize.height
    )

    if let visibleFrame = panel.screen?.visibleFrame ?? NSScreen.main?.visibleFrame {
      nextFrame.origin.x = min(
        max(nextFrame.origin.x, visibleFrame.minX), visibleFrame.maxX - nextSize.width)
      nextFrame.origin.y = min(
        max(nextFrame.origin.y, visibleFrame.minY), visibleFrame.maxY - nextSize.height)
    }

    panel.setFrame(nextFrame, display: true, animate: true)
    panel.orderFrontRegardless()
  }

  private func constrainToVisibleScreen() {
    guard let visibleFrame = panel.screen?.visibleFrame ?? NSScreen.main?.visibleFrame else {
      return
    }
    var origin = panel.frame.origin
    origin.x = min(max(origin.x, visibleFrame.minX), visibleFrame.maxX - panel.frame.width)
    origin.y = min(max(origin.y, visibleFrame.minY), visibleFrame.maxY - panel.frame.height)
    panel.setFrameOrigin(origin)
  }

  private static func size(for surface: BubbleSurface) -> CGSize {
    switch surface {
    case .board:
      CGSize(width: 330, height: 250)
    case .focus:
      CGSize(width: 210, height: 210)
    }
  }

  private static func initialFrame(size: CGSize) -> CGRect {
    let visibleFrame = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
    return CGRect(
      x: visibleFrame.maxX - size.width - 12,
      y: visibleFrame.maxY - size.height - 12,
      width: size.width,
      height: size.height
    )
  }
}
