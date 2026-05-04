import AppKit
import Defaults
import Foundation
import Settings
import SwiftUI

enum AppMode: String, Defaults.Serializable {
  case history
  case commands
}

@Observable
class AppState: Sendable {
  static let shared = AppState(history: History.shared, commands: CommandsManager.shared, footer: Footer())

  let multiSelectionEnabled = false

  var appDelegate: AppDelegate?
  var popup: Popup
  var history: History
  var commands: CommandsManager
  var footer: Footer
  var navigator: NavigationManager
  var preview: SlideoutController

  var mode: AppMode = .history {
    didSet {
      Defaults[.lastMode] = mode
      AppState.shared.popup.needsResize = true
    }
  }

  /// When non-nil, the commands list shows the variable input view for this command.
  var activeInputCommand: CommandDecorator?
  /// Shows the command editor sheet.
  var showCommandEditor = false
  var editingCommand: CommandDecorator?
  var commandEditorPrefillBody: String?

  var searchQuery: String {
    get {
      switch mode {
      case .history: return history.searchQuery
      case .commands: return commands.searchQuery
      }
    }
    set {
      switch mode {
      case .history: history.searchQuery = newValue
      case .commands: commands.searchQuery = newValue
      }
    }
  }

  var searchVisible: Bool {
    if !Defaults[.showSearch] { return false }
    switch Defaults[.searchVisibility] {
    case .always: return true
    case .duringSearch: return !searchQuery.isEmpty
    }
  }

  var menuIconText: String {
    var title = history.unpinnedItems.first?.text.shortened(to: 100)
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    title.unicodeScalars.removeAll(where: CharacterSet.newlines.contains)
    return title.shortened(to: 20)
  }

  private let about = About()
  private var settingsWindowController: SettingsWindowController?

  init(history: History, commands: CommandsManager, footer: Footer) {
    self.history = history
    self.commands = commands
    self.footer = footer
    self.mode = Defaults[.lastMode]
    popup = Popup()
    navigator = NavigationManager(history: history, footer: footer)
    preview = SlideoutController(
      onContentResize: { contentWidth in
        Defaults[.windowSize].width = contentWidth
      },
      onSlideoutResize: { previewWidth in
        Defaults[.previewWidth] = previewWidth
      })
    preview.contentWidth = Defaults[.windowSize].width
    preview.slideoutWidth = Defaults[.previewWidth]
  }

  @MainActor
  func select() {
    switch mode {
    case .history:
      selectInHistoryMode()
    case .commands:
      selectInCommandsMode()
    }
  }

  @MainActor
  private func selectInHistoryMode() {
    if !navigator.selection.isEmpty {
      if navigator.isMultiSelectInProgress {
        navigator.isManualMultiSelect = false
        history.startPasteStack(selection: &navigator.selection)
      } else {
        history.select(navigator.selection.first)
      }
    } else if let item = footer.selectedItem {
      if item.confirmation != nil, Defaults[.suppressClearAlert] == false {
        item.showConfirmation = true
      } else {
        item.action()
      }
    } else {
      Clipboard.shared.copy(history.searchQuery)
      history.searchQuery = ""
    }
  }

  @MainActor
  private func selectInCommandsMode() {
    if !navigator.commandsSelection.isEmpty {
      if let item = navigator.commandsSelection.first {
        Task {
          await executeCommand(item)
        }
      }
    } else if let item = footer.selectedItem {
      if item.confirmation != nil, Defaults[.suppressClearAlert] == false {
        item.showConfirmation = true
      } else {
        item.action()
      }
    }
  }

  @MainActor
  func executeCommand(_ item: CommandDecorator) async {
    let bodyText = item.command.body

    // Check for %INPUT:...% tokens
    if VariableExpander.shared.hasInputTokens(in: bodyText) {
      activeInputCommand = item
      return
    }

    guard let resolved = await VariableExpander.shared.expand(bodyText) else { return }
    finalizeCommandExecution(item, resolved: resolved)
  }

  @MainActor
  func finalizeCommandExecution(_ item: CommandDecorator, resolved: String) {
    item.command.lastUsedAt = Date.now
    item.command.useCount += 1
    try? Storage.shared.context.save()

    Clipboard.shared.copy(resolved)
    popup.close()
    Clipboard.shared.paste()
  }

  @MainActor
  func submitVariableInput(_ values: [String: String]) {
    guard let item = activeInputCommand else { return }
    let resolved = VariableExpander.shared.expand(item.command.body, inputValues: values)
    activeInputCommand = nil
    finalizeCommandExecution(item, resolved: resolved)
  }

  @MainActor
  func cancelVariableInput() {
    activeInputCommand = nil
  }

  @MainActor
  func togglePin() {
    switch mode {
    case .history:
      withTransaction(Transaction()) {
        navigator.selection.forEach { _, item in
          history.togglePin(item)
        }
      }
    case .commands:
      withTransaction(Transaction()) {
        navigator.commandsSelection.forEach { _, item in
          commands.togglePin(item)
        }
      }
    }
  }

  @MainActor
  func removePasteStack() {
    history.interruptPasteStack()
    navigator.highlightFirst()
  }

  @MainActor
  func deleteSelection() {
    switch mode {
    case .history:
      guard let leadItem = navigator.leadHistoryItem else { return }
      let nextUnselectedItem = history.visibleItems.nearest(to: leadItem) { !$0.isSelected }

      withTransaction(Transaction()) {
        navigator.selection.forEach { _, item in
          history.delete(item)
        }
        navigator.select(item: nextUnselectedItem)
      }
    case .commands:
      withTransaction(Transaction()) {
        navigator.commandsSelection.forEach { _, item in
          commands.delete(item)
        }
      }
    }
  }

  func toggleMode() {
    mode = (mode == .history) ? .commands : .history
  }

  func openAbout() {
    about.openAbout(nil)
  }

  @MainActor
  func openPreferences() { // swiftlint:disable:this function_body_length
    if settingsWindowController == nil {
      settingsWindowController = SettingsWindowController(
        panes: [
          Settings.Pane(
            identifier: Settings.PaneIdentifier.general,
            title: NSLocalizedString("Title", tableName: "GeneralSettings", comment: ""),
            toolbarIcon: NSImage.gearshape!
          ) {
            GeneralSettingsPane()
          },
          Settings.Pane(
            identifier: Settings.PaneIdentifier.storage,
            title: NSLocalizedString("Title", tableName: "StorageSettings", comment: ""),
            toolbarIcon: NSImage.externaldrive!
          ) {
            StorageSettingsPane()
          },
          Settings.Pane(
            identifier: Settings.PaneIdentifier.appearance,
            title: NSLocalizedString("Title", tableName: "AppearanceSettings", comment: ""),
            toolbarIcon: NSImage.paintpalette!
          ) {
            AppearanceSettingsPane()
          },
          Settings.Pane(
            identifier: Settings.PaneIdentifier.pins,
            title: NSLocalizedString("Title", tableName: "PinsSettings", comment: ""),
            toolbarIcon: NSImage.pincircle!
          ) {
            PinsSettingsPane()
              .environment(self)
              .modelContainer(Storage.shared.container)
          },
          Settings.Pane(
            identifier: Settings.PaneIdentifier.ignore,
            title: NSLocalizedString("Title", tableName: "IgnoreSettings", comment: ""),
            toolbarIcon: NSImage.nosign!
          ) {
            IgnoreSettingsPane()
          },
          Settings.Pane(
            identifier: Settings.PaneIdentifier.advanced,
            title: NSLocalizedString("Title", tableName: "AdvancedSettings", comment: ""),
            toolbarIcon: NSImage.gearshape2!
          ) {
            AdvancedSettingsPane()
          }
        ]
      )
    }
    settingsWindowController?.show()
    settingsWindowController?.window?.orderFrontRegardless()
  }

  func quit() {
    NSApp.terminate(self)
  }
}
