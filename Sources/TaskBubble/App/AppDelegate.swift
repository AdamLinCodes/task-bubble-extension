import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private var model: AppModel?
  private var windowController: BubbleWindowController?
  private var statusItem: NSStatusItem?
  private var notificationScheduler: FocusNotificationScheduler?

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.regular)

    let model = AppModel()
    let notificationScheduler = FocusNotificationScheduler()
    let windowController = BubbleWindowController(model: model)

    model.focus.onDeadlineChanged = { [weak notificationScheduler] deadline in
      notificationScheduler?.schedule(at: deadline)
    }
    model.focus.onCompleted = { [weak model, weak windowController] in
      NSSound.beep()
      model?.isPinned = true
      windowController?.show()
    }
    notificationScheduler.schedule(at: model.focus.deadline)

    self.model = model
    self.notificationScheduler = notificationScheduler
    self.windowController = windowController

    installStatusItem()
    windowController.show()
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    false
  }

  func applicationShouldHandleReopen(
    _ sender: NSApplication,
    hasVisibleWindows flag: Bool
  ) -> Bool {
    windowController?.show()
    return true
  }

  @objc private func showWhiteboard() {
    model?.showBoard()
    windowController?.show()
  }

  @objc private func startFocus() {
    model?.showFocus(startIfNeeded: true)
    model?.isPinned = false
    windowController?.show()
  }

  @objc private func toggleTimer() {
    model?.focus.toggleRunning()
    model?.showFocus()
    windowController?.show()
  }

  @objc private func flipBubble() {
    model?.flip()
    windowController?.show()
  }

  @objc private func togglePin() {
    guard let model else { return }
    model.isPinned.toggle()
    windowController?.show()
  }

  @objc private func quit() {
    NSApp.terminate(nil)
  }

  private func installStatusItem() {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    item.button?.image = NSImage(
      systemSymbolName: "timer.circle.fill",
      accessibilityDescription: "Task Bubble"
    )

    let menu = NSMenu()
    menu.addItem(menuItem("Show Whiteboard", action: #selector(showWhiteboard)))
    menu.addItem(menuItem("Start 30-minute Focus", action: #selector(startFocus)))
    menu.addItem(menuItem("Pause or Resume Timer", action: #selector(toggleTimer)))
    menu.addItem(menuItem("Flip Bubble", action: #selector(flipBubble)))
    menu.addItem(menuItem("Pin or Unpin Bubble", action: #selector(togglePin)))
    menu.addItem(.separator())
    menu.addItem(menuItem("Quit Task Bubble", action: #selector(quit), keyEquivalent: "q"))
    item.menu = menu
    statusItem = item
  }

  private func menuItem(
    _ title: String,
    action: Selector,
    keyEquivalent: String = ""
  ) -> NSMenuItem {
    let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
    item.target = self
    return item
  }
}
