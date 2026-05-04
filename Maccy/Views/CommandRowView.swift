import SwiftUI

struct CommandRowView: View {
  @Bindable var item: CommandDecorator

  @Environment(AppState.self) private var appState

  var body: some View {
    ListItemView(
      id: item.id,
      selectionId: item.id,
      appIcon: nil,
      image: nil,
      accessoryImage: nil,
      attributedTitle: nil,
      shortcuts: item.shortcuts,
      isSelected: item.isSelected,
      selectionIndex: nil
    ) {
      VStack(alignment: .leading, spacing: 1) {
        Text(verbatim: item.title)
        if !item.body.isEmpty {
          Text(verbatim: item.body.prefix(80).description)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
    }
    .accessibilityIdentifier("command_row_\(item.id)")
    .onTapGesture {
      Task {
        await appState.executeCommand(item)
      }
    }
  }
}
