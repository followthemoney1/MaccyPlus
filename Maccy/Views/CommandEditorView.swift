import SwiftUI

struct CommandEditorView: View {
  @Environment(AppState.self) private var appState

  var editingCommand: CommandDecorator?
  var prefillBody: String?

  @State private var title = ""
  @State private var bodyText = ""
  @State private var selectedFolder: CommandFolder?
  @State private var folders: [CommandFolder] = []

  var body: some View {
    VStack(spacing: 12) {
      Text(editingCommand != nil
        ? String(localized: "command_editor_edit_title")
        : String(localized: "command_editor_add_title"))
        .font(.headline)

      TextField(String(localized: "command_editor_title_placeholder"), text: $title)
        .textFieldStyle(.roundedBorder)
        .accessibilityIdentifier("command_editor_title_field")

      TextEditor(text: $bodyText)
        .font(.body.monospaced())
        .frame(minHeight: 80, maxHeight: 200)
        .border(Color.secondary.opacity(0.3))
        .accessibilityIdentifier("command_editor_body_editor")

      if !folders.isEmpty {
        Picker(String(localized: "command_editor_folder_label"), selection: $selectedFolder) {
          ForEach(folders, id: \.name) { folder in
            Text(verbatim: folder.name).tag(Optional(folder))
          }
        }
        .accessibilityIdentifier("command_editor_folder_picker")
      }

      Text(String(localized: "command_editor_variables_hint"))
        .font(.caption)
        .foregroundStyle(.secondary)

      HStack {
        Button(String(localized: "command_editor_cancel")) {
          closeEditor()
        }
        .keyboardShortcut(.cancelAction)
        .accessibilityIdentifier("command_editor_cancel_button")

        Spacer()

        Button(String(localized: "command_editor_save")) {
          save()
          closeEditor()
        }
        .keyboardShortcut(.defaultAction)
        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
        .accessibilityIdentifier("command_editor_save_button")
      }
    }
    .padding()
    .frame(maxWidth: .infinity)
    .task {
      loadData()
    }
  }

  @MainActor
  private func closeEditor() {
    appState.showCommandEditor = false
    appState.editingCommand = nil
    appState.commandEditorPrefillBody = nil
    appState.commands.load()
  }

  @MainActor
  private func loadData() {
    folders = Storage.shared.fetchFolders()
    if let command = editingCommand {
      title = command.title
      bodyText = command.body
      selectedFolder = command.command.folder
    } else if let prefill = prefillBody {
      bodyText = prefill
      title = String(prefill.prefix(50))
    }
    if selectedFolder == nil {
      selectedFolder = folders.first
    }
  }

  @MainActor
  private func save() {
    let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
    guard !trimmedTitle.isEmpty else { return }

    if let existing = editingCommand {
      appState.commands.update(existing, title: trimmedTitle, body: bodyText, folder: selectedFolder)
    } else {
      appState.commands.add(title: trimmedTitle, body: bodyText, folder: selectedFolder)
    }
  }
}
