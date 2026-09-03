import SwiftUI

struct BoardView: View {
  @ObservedObject var model: AppModel
  @ObservedObject var board: BoardStore
  @State private var draft = ""

  var body: some View {
    VStack(spacing: 12) {
      HStack {
        Label("Whiteboard", systemImage: "square.and.pencil")
          .font(.headline)

        Spacer()

        Button {
          model.flip()
        } label: {
          Image(systemName: "timer")
        }
        .help("Start a 30-minute focus session")

        Button {
          model.isPinned.toggle()
        } label: {
          Image(systemName: model.isPinned ? "pin.fill" : "pin")
        }
        .help(model.isPinned ? "Let the bubble dodge again" : "Pin the bubble")

        Button {
          model.quit()
        } label: {
          Image(systemName: "xmark")
        }
        .help("Quit Task Bubble")
      }
      .buttonStyle(.plain)

      Divider()

      ScrollView {
        LazyVStack(spacing: 8) {
          if board.items.isEmpty {
            Text("Write anything. Cross it off when it is done; it will stay right here.")
              .font(.system(size: 13))
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.vertical, 8)
          }

          ForEach(board.items) { item in
            BoardLineView(item: item, board: board)
          }
        }
      }

      HStack(spacing: 8) {
        Image(systemName: "plus.circle.fill")
          .foregroundStyle(.secondary)

        TextField("Add a line…", text: $draft)
          .textFieldStyle(.plain)
          .onSubmit(addDraft)
      }
      .padding(10)
      .background(Color.black.opacity(0.045), in: RoundedRectangle(cornerRadius: 12))

      Text("Hold ⌥, then pin to edit")
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(.secondary)
    }
    .padding(16)
    .frame(width: 330, height: 250)
    .background(
      LinearGradient(
        colors: [Color(red: 1, green: 0.995, blue: 0.96), .white],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      ),
      in: RoundedRectangle(cornerRadius: 22, style: .continuous)
    )
    .overlay {
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .stroke(Color.black.opacity(0.12), lineWidth: 1)
    }
    .shadow(color: .black.opacity(0.22), radius: 22, y: 10)
  }

  private func addDraft() {
    if board.add(draft) != nil {
      draft = ""
    }
  }
}

private struct BoardLineView: View {
  let item: BoardItem
  @ObservedObject var board: BoardStore

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 9) {
      Button {
        board.toggleCrossedOut(id: item.id)
      } label: {
        Image(systemName: item.isCrossedOut ? "checkmark.circle.fill" : "circle")
          .foregroundStyle(item.isCrossedOut ? Color.green : Color.secondary)
      }
      .buttonStyle(.plain)

      TextField(
        "Note",
        text: Binding(
          get: { item.text },
          set: { board.update(id: item.id, text: $0) }
        )
      )
      .textFieldStyle(.plain)
      .font(.system(size: 14, weight: .medium))
      .strikethrough(item.isCrossedOut, color: .secondary)
      .foregroundStyle(item.isCrossedOut ? Color.secondary : Color.primary)
    }
    .padding(.horizontal, 4)
    .contextMenu {
      Button("Delete", role: .destructive) {
        board.delete(id: item.id)
      }
    }
  }
}
