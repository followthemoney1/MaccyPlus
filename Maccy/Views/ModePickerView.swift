import SwiftUI

struct ModePickerView: View {
  @Environment(AppState.self) private var appState

  var body: some View {
    @Bindable var state = appState
    Picker("", selection: $state.mode) {
      Image(systemName: "clock.arrow.circlepath")
        .accessibilityIdentifier("mode_picker_history")
        .tag(AppMode.history)
      Image(systemName: "terminal")
        .accessibilityIdentifier("mode_picker_commands")
        .tag(AppMode.commands)
    }
    .pickerStyle(.segmented)
    .frame(width: 90, height: 24)
    .accessibilityIdentifier("mode_picker")
  }
}
