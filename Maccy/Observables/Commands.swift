import Defaults
import Foundation
import Observation
import SwiftData

@Observable
class CommandsManager: ItemsContainer {
  static let shared = CommandsManager()

  var items: [CommandDecorator] = []

  var pinnedItems: [CommandDecorator] { items.filter(\.isPinned) }
  var unpinnedItems: [CommandDecorator] { items.filter { !$0.isPinned } }

  var searchQuery: String = "" {
    didSet {
      updateVisibleItems()
    }
  }

  @ObservationIgnored
  var all: [CommandDecorator] = []

  @MainActor
  func load() {
    let results = Storage.shared.fetchCommands()
    all = results.map { CommandDecorator($0) }
    items = all
    updateShortcuts()
  }

  @MainActor
  func add(title: String, body: String, folder: CommandFolder? = nil) {
    let targetFolder = folder ?? defaultFolder()
    let command = Command(title: title, body: body, folder: targetFolder)
    Storage.shared.addCommand(command)

    let decorator = CommandDecorator(command)
    all.insert(decorator, at: 0)
    items = all
    updateShortcuts()
    AppState.shared.popup.needsResize = true
  }

  @MainActor
  func update(_ decorator: CommandDecorator, title: String, body: String, folder: CommandFolder?) {
    decorator.command.title = title
    decorator.command.body = body
    decorator.command.folder = folder
    decorator.title = title
    decorator.body = body
    decorator.folderName = folder?.name ?? ""
    try? Storage.shared.context.save()
  }

  @MainActor
  func delete(_ item: CommandDecorator?) {
    guard let item else { return }
    Storage.shared.deleteCommand(item.command)
    all.removeAll { $0 == item }
    items.removeAll { $0 == item }
    AppState.shared.popup.needsResize = true
  }

  @MainActor
  func togglePin(_ item: CommandDecorator?) {
    guard let item else { return }
    item.command.isPinned.toggle()
    try? Storage.shared.context.save()
    load()
  }

  @MainActor
  func create(fromHistoryText text: String) {
    add(title: String(text.prefix(50)), body: text)
  }

  private func updateVisibleItems() {
    if searchQuery.isEmpty {
      items = all
    } else {
      items = all.filter { $0.matches(query: searchQuery) }
    }
    updateShortcuts()
  }

  private func updateShortcuts() {
    let visibleUnpinned = items.filter { !$0.isPinned && $0.isVisible }
    for item in visibleUnpinned {
      item.shortcuts = []
    }

    var index = 1
    for item in visibleUnpinned.prefix(9) {
      item.shortcuts = KeyShortcut.create(character: String(index))
      index += 1
    }
  }

  @MainActor
  private func defaultFolder() -> CommandFolder {
    Storage.shared.ensureDefaultFolder()
    return Storage.shared.fetchFolders().first ?? CommandFolder(name: "Default")
  }
}
