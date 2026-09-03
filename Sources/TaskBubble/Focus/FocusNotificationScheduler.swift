import Foundation
@preconcurrency import UserNotifications

@MainActor
final class FocusNotificationScheduler {
  private let notificationIdentifier = "task-bubble-focus-complete"
  private var generation = 0

  func schedule(at deadline: Date?) {
    guard Bundle.main.bundleURL.pathExtension == "app" else { return }
    generation += 1
    let requestedGeneration = generation
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
    guard let deadline else { return }

    center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
      Task { @MainActor [weak self] in
        guard granted, let self, self.generation == requestedGeneration else { return }

        let content = UNMutableNotificationContent()
        content.title = "Focus session complete"
        content.body = "Your 30-minute Task Bubble session is finished."
        content.sound = .default

        let interval = max(1, deadline.timeIntervalSinceNow)
        let request = UNNotificationRequest(
          identifier: self.notificationIdentifier,
          content: content,
          trigger: UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        )
        try? await UNUserNotificationCenter.current().add(request)
      }
    }
  }
}
