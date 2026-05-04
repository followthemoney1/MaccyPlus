import Foundation
import SwiftData

@Model
class Command {
  var title: String = ""
  var body: String = ""
  var kind: String = "text"
  var isPinned: Bool = false
  var createdAt: Date = Date.now
  var lastUsedAt: Date = Date.now
  var useCount: Int = 0
  var hotkeyName: String?

  @Relationship
  var folder: CommandFolder?

  @Relationship(deleteRule: .cascade, inverse: \CommandVariable.command)
  var variables: [CommandVariable] = []

  init(
    title: String,
    body: String,
    kind: String = "text",
    folder: CommandFolder? = nil
  ) {
    self.title = title
    self.body = body
    self.kind = kind
    self.folder = folder
  }
}
