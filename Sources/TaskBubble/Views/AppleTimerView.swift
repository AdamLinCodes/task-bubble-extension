import SwiftUI

struct AppleTimerView: View {
  @ObservedObject var model: AppModel
  @ObservedObject var focus: FocusTimerStore

  var body: some View {
    ZStack {
      Circle()
        .stroke(Color.black.opacity(0.1), lineWidth: 5)
        .frame(width: 200, height: 200)

      Circle()
        .trim(from: 0, to: max(0.001, 1 - focus.progress))
        .stroke(
          Color(red: 0.18, green: 0.48, blue: 0.16),
          style: StrokeStyle(lineWidth: 5, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
        .frame(width: 200, height: 200)
        .animation(.linear(duration: 0.4), value: focus.progress)

      AppleShape()
        .fill(
          LinearGradient(
            colors: [
              Color(red: 0.98, green: 0.20, blue: 0.18),
              Color(red: 0.72, green: 0.03, blue: 0.06),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: 152, height: 146)
        .shadow(color: .black.opacity(0.26), radius: 18, y: 9)

      Capsule()
        .fill(Color(red: 0.22, green: 0.55, blue: 0.20))
        .frame(width: 34, height: 15)
        .rotationEffect(.degrees(-28))
        .offset(x: 22, y: -72)

      VStack(spacing: 8) {
        Text(focus.displayTime)
          .font(.system(size: 30, weight: .bold, design: .rounded))
          .monospacedDigit()
          .foregroundStyle(.white)

        Text(phaseLabel)
          .font(.system(size: 10, weight: .semibold))
          .textCase(.uppercase)
          .tracking(1.2)
          .foregroundStyle(.white.opacity(0.76))

        HStack(spacing: 13) {
          Button {
            focus.toggleRunning()
          } label: {
            Image(systemName: focus.phase == .running ? "pause.fill" : "play.fill")
          }

          Button {
            focus.reset()
          } label: {
            Image(systemName: "arrow.counterclockwise")
          }

          Button {
            model.flip()
          } label: {
            Image(systemName: "note.text")
          }
        }
        .buttonStyle(AppleControlButtonStyle())
      }
      .offset(y: 8)

      Button {
        model.isPinned.toggle()
      } label: {
        Image(systemName: model.isPinned ? "pin.fill" : "pin")
          .font(.system(size: 11, weight: .bold))
          .foregroundStyle(.white.opacity(0.9))
          .padding(8)
          .background(.black.opacity(0.14), in: Circle())
      }
      .buttonStyle(.plain)
      .offset(x: 65, y: -58)

      Button {
        model.quit()
      } label: {
        Image(systemName: "xmark")
          .font(.system(size: 11, weight: .bold))
          .foregroundStyle(.white.opacity(0.9))
          .padding(8)
          .background(.black.opacity(0.14), in: Circle())
      }
      .buttonStyle(.plain)
      .help("Quit Task Bubble")
      .offset(x: -65, y: -58)
    }
    .frame(width: 210, height: 210)
  }

  private var phaseLabel: String {
    switch focus.phase {
    case .idle: "Ready"
    case .running: "Focusing"
    case .paused: "Paused"
    case .completed: "Complete"
    }
  }
}

private struct AppleControlButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 11, weight: .bold))
      .foregroundStyle(.white)
      .frame(width: 28, height: 28)
      .background(.white.opacity(configuration.isPressed ? 0.30 : 0.18), in: Circle())
      .scaleEffect(configuration.isPressed ? 0.92 : 1)
  }
}

struct AppleShape: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let w = rect.width
    let h = rect.height

    path.move(to: CGPoint(x: w * 0.50, y: h * 0.20))
    path.addCurve(
      to: CGPoint(x: w * 0.12, y: h * 0.39),
      control1: CGPoint(x: w * 0.36, y: h * 0.08),
      control2: CGPoint(x: w * 0.14, y: h * 0.16)
    )
    path.addCurve(
      to: CGPoint(x: w * 0.32, y: h * 0.94),
      control1: CGPoint(x: w * 0.03, y: h * 0.62),
      control2: CGPoint(x: w * 0.15, y: h * 0.91)
    )
    path.addCurve(
      to: CGPoint(x: w * 0.50, y: h * 0.88),
      control1: CGPoint(x: w * 0.41, y: h * 0.98),
      control2: CGPoint(x: w * 0.45, y: h * 0.88)
    )
    path.addCurve(
      to: CGPoint(x: w * 0.68, y: h * 0.94),
      control1: CGPoint(x: w * 0.55, y: h * 0.88),
      control2: CGPoint(x: w * 0.59, y: h * 0.98)
    )
    path.addCurve(
      to: CGPoint(x: w * 0.88, y: h * 0.39),
      control1: CGPoint(x: w * 0.85, y: h * 0.91),
      control2: CGPoint(x: w * 0.97, y: h * 0.62)
    )
    path.addCurve(
      to: CGPoint(x: w * 0.50, y: h * 0.20),
      control1: CGPoint(x: w * 0.86, y: h * 0.16),
      control2: CGPoint(x: w * 0.64, y: h * 0.08)
    )
    path.closeSubpath()
    return path
  }
}
