import Foundation
import SwiftData

@Model
class CommandFolder {
  var name: String = ""
  var createdAt: Date = Date.now
  var sortOrder: Int = 0

  @Relationship(deleteRule: .cascade, inverse: \Command.folder)
  var commands: [Command] = []

  init(name: String, sortOrder: Int = 0) {
    self.name = name
    self.sortOrder = sortOrder
  }
}
