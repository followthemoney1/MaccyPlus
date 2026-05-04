import Foundation
import Observation

@Observable
class CommandDecorator: Identifiable, Hashable, HasVisibility {
  static func == (lhs: CommandDecorator, rhs: CommandDecorator) -> Bool {
    return lhs.id == rhs.id
  }

  let id = UUID()

  var title: String = ""
  var body: String = ""
  var folderName: String = ""
  var isVisible: Bool = true
  var selectionIndex: Int = -1
  var isSelected: Bool { selectionIndex != -1 }
  var shortcuts: [KeyShortcut] = []
  var isPinned: Bool { command.isPinned }

  private(set) var command: Command

  init(_ command: Command) {
    self.command = command
    self.title = command.title
    self.body = command.body
    self.folderName = command.folder?.name ?? ""
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(title)
    hasher.combine(body)
  }

  func matches(query: String) -> Bool {
    guard !query.isEmpty else { return true }
    return title.localizedCaseInsensitiveContains(query)
      || body.localizedCaseInsensitiveContains(query)
      || folderName.localizedCaseInsensitiveContains(query)
  }
}
