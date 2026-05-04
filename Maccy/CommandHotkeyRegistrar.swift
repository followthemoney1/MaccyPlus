import Foundation
import KeyboardShortcuts

/// Manages per-command global hotkey registration.
/// Diffs commands on every change to register/de-register shortcuts.
@MainActor
class CommandHotkeyRegistrar {
  static let shared = CommandHotkeyRegistrar()

  /// Reserved shortcut names that commands cannot use.
  private let reservedNames: Set<KeyboardShortcuts.Name> = [
    .popup, .pin, .delete, .togglePreview, .toggleMode
  ]

  private var registeredNames: Set<String> = []

  func start() {
    syncRegistrations()
  }

  func syncRegistrations() {
    let commands = Storage.shared.fetchCommands()
    let currentHotkeyNames = Set(commands.compactMap { $0.hotkeyName })

    // De-register removed
    let removed = registeredNames.subtracting(currentHotkeyNames)
    for name in removed {
      let shortcutName = KeyboardShortcuts.Name(name)
      KeyboardShortcuts.disable(shortcutName)
    }

    // Register new
    let added = currentHotkeyNames.subtracting(registeredNames)
    for name in added {
      let shortcutName = KeyboardShortcuts.Name(name)
      KeyboardShortcuts.onKeyDown(for: shortcutName) { [weak self] in
        Task { @MainActor in
          self?.handleHotkeyFired(name: name)
        }
      }
    }

    registeredNames = currentHotkeyNames
  }

  func isCollision(shortcutName: String) -> Bool {
    // Check against reserved names
    for reserved in reservedNames where reserved.rawValue == shortcutName {
      return true
    }
    // Check against other commands
    let commands = Storage.shared.fetchCommands()
    let existingNames = commands.compactMap { $0.hotkeyName }
    return existingNames.filter { $0 == shortcutName }.count > 1
  }

  private func handleHotkeyFired(name: String) {
    let commands = Storage.shared.fetchCommands()
    guard let command = commands.first(where: { $0.hotkeyName == name }) else { return }

    let decorator = CommandDecorator(command)

    if VariableExpander.shared.hasInputTokens(in: command.body) {
      // Show panel and jump to input view
      AppState.shared.popup.open(height: AppState.shared.popup.height)
      AppState.shared.mode = .commands
      AppState.shared.activeInputCommand = decorator
    } else {
      Task {
        await AppState.shared.executeCommand(decorator)
      }
    }
  }
}
