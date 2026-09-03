import SwiftUI

struct BubbleRootView: View {
  @ObservedObject var model: AppModel
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    Group {
      if model.surface == .board {
        BoardView(model: model, board: model.board)
          .transition(surfaceTransition)
      } else {
        AppleTimerView(model: model, focus: model.focus)
          .transition(surfaceTransition)
      }
    }
    .animation(
      reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.55, dampingFraction: 0.78),
      value: model.surface
    )
    .contentShape(Rectangle())
  }

  private var surfaceTransition: AnyTransition {
    if reduceMotion {
      return .opacity
    }

    return .asymmetric(
      insertion: .modifier(
        active: FlipModifier(angle: -90, opacity: 0),
        identity: FlipModifier(angle: 0, opacity: 1)
      ),
      removal: .modifier(
        active: FlipModifier(angle: 90, opacity: 0),
        identity: FlipModifier(angle: 0, opacity: 1)
      )
    )
  }
}

private struct FlipModifier: ViewModifier {
  let angle: Double
  let opacity: Double

  func body(content: Content) -> some View {
    content
      .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.65)
      .opacity(opacity)
  }
}
