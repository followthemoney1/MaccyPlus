import Foundation
import SwiftData

@MainActor
class Storage {
  static let shared = Storage()

  var container: ModelContainer
  var context: ModelContext { container.mainContext }
  var size: String {
    guard let size = try? url.resourceValues(forKeys: [.fileSizeKey]).allValues.first?.value as? Int64, size > 1 else {
      return ""
    }

    return ByteCountFormatter().string(fromByteCount: size)
  }

  private let url = URL.applicationSupportDirectory.appending(path: "Maccy/Storage.sqlite")

  init() {
    var config = ModelConfiguration(url: url)

    #if DEBUG
    if CommandLine.arguments.contains("enable-testing") {
      config = ModelConfiguration(isStoredInMemoryOnly: true)
    }
    #endif

    do {
      container = try ModelContainer(
        for: HistoryItem.self, Command.self, CommandFolder.self, CommandVariable.self,
        configurations: config
      )
    } catch let error {
      fatalError("Cannot load database: \(error.localizedDescription).")
    }
  }

  // MARK: - Commands

  func addCommand(_ command: Command) {
    context.insert(command)
    context.processPendingChanges()
    try? context.save()
  }

  func deleteCommand(_ command: Command) {
    context.delete(command)
    context.processPendingChanges()
    try? context.save()
  }

  func fetchCommands() -> [Command] {
    let descriptor = FetchDescriptor<Command>(
      sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
    )
    return (try? context.fetch(descriptor)) ?? []
  }

  // MARK: - Command Folders

  func addFolder(_ folder: CommandFolder) {
    context.insert(folder)
    context.processPendingChanges()
    try? context.save()
  }

  func deleteFolder(_ folder: CommandFolder) {
    context.delete(folder)
    context.processPendingChanges()
    try? context.save()
  }

  func fetchFolders() -> [CommandFolder] {
    let descriptor = FetchDescriptor<CommandFolder>(
      sortBy: [SortDescriptor(\.sortOrder)]
    )
    return (try? context.fetch(descriptor)) ?? []
  }

  func ensureDefaultFolder() {
    let descriptor = FetchDescriptor<CommandFolder>()
    let count = (try? context.fetchCount(descriptor)) ?? 0
    if count == 0 {
      let defaultFolder = CommandFolder(name: NSLocalizedString("default_folder", comment: ""))
      addFolder(defaultFolder)
    }
  }
}
