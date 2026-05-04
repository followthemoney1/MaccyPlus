import SwiftUI

struct CommandFolderSidebarView: View {
  @Environment(AppState.self) private var appState

  @State private var folders: [CommandFolder] = []
  @State private var showDeleteConfirm = false
  @State private var folderToDelete: CommandFolder?
  @State private var newFolderName = ""
  @State private var showAddFolder = false

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      ForEach(folders, id: \.name) { folder in
        HStack {
          Image(systemName: "folder")
            .font(.caption)
          Text(verbatim: folder.name)
            .font(.caption)
            .lineLimit(1)
          Spacer()
          Text(verbatim: "\(folder.commands.count)")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .accessibilityIdentifier("command_folder_row_\(folder.name)")
        .contextMenu {
          Button(String(localized: "delete_folder")) {
            folderToDelete = folder
            showDeleteConfirm = true
          }
        }
      }
    }
    .accessibilityIdentifier("command_folder_sidebar")
    .task {
      loadFolders()
    }
    .alert(
      String(localized: "delete_folder_confirm_title"),
      isPresented: $showDeleteConfirm
    ) {
      Button(String(localized: "clear_alert_cancel"), role: .cancel) {
        folderToDelete = nil
      }
      Button(String(localized: "delete_folder_confirm"), role: .destructive) {
        if let folder = folderToDelete {
          deleteFolder(folder)
        }
      }
      .accessibilityIdentifier("command_folder_delete_confirm")
    } message: {
      if let folder = folderToDelete {
        Text(String(localized: "delete_folder_confirm_message \(folder.commands.count)"))
      }
    }
  }

  @MainActor
  private func loadFolders() {
    folders = Storage.shared.fetchFolders()
  }

  @MainActor
  private func deleteFolder(_ folder: CommandFolder) {
    Storage.shared.deleteFolder(folder)
    folderToDelete = nil
    loadFolders()
    appState.commands.load()
  }
}
