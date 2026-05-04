import Foundation
import SwiftData

@Model
class CommandVariable {
  var label: String = ""
  var defaultValue: String = ""

  @Relationship
  var command: Command?

  init(label: String, defaultValue: String = "") {
    self.label = label
    self.defaultValue = defaultValue
  }
}
