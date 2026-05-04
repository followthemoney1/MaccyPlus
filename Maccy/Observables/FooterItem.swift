import SwiftUI

@Observable
class FooterItem: Equatable, Identifiable, HasVisibility {
  struct Confirmation {
    var message: LocalizedStringKey
    var comment: LocalizedStringKey
    var confirm: LocalizedStringKey
    var cancel: LocalizedStringKey
  }

  static func == (lhs: FooterItem, rhs: FooterItem) -> Bool {
    return lhs.id == rhs.id
  }

  let id = UUID()

  var title: String
  var shortcuts: [KeyShortcut] = []
  var help: LocalizedStringKey?
  var isSelected: Bool = false
  var confirmation: Confirmation?
  var showConfirmation: Bool = false
  var suppressConfirmation: Binding<Bool>?
  var isVisible: Bool = true
  var visibleInModes: Set<AppMode>
  var action: () -> Void

  init(
    title: String,
    shortcuts: [KeyShortcut] = [],
    help: LocalizedStringKey? = nil,
    confirmation: Confirmation? = nil,
    suppressConfirmation: Binding<Bool>? = nil,
    visibleInModes: Set<AppMode> = [.history, .commands],
    action: @escaping () -> Void
  ) {
    self.title = title
    self.shortcuts = shortcuts
    self.help = help
    self.confirmation = confirmation
    self.suppressConfirmation = suppressConfirmation
    self.visibleInModes = visibleInModes
    self.action = action
  }

  func isVisible(in mode: AppMode) -> Bool {
    return visibleInModes.contains(mode)
  }
}
