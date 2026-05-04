import Defaults
import SwiftUI

struct CommandsListView: View {
  @Environment(AppState.self) private var appState
  @Environment(\.scenePhase) private var scenePhase

  @Default(.showFooter) private var showFooter

  private var commands: [CommandDecorator] {
    appState.commands.items
  }

  private var topPadding: CGFloat {
    Popup.verticalSeparatorPadding
  }

  private var bottomPadding: CGFloat {
    showFooter
      ? Popup.verticalSeparatorPadding
      : (Popup.verticalSeparatorPadding - 1)
  }

  var body: some View {
    if commands.isEmpty {
      emptyState
    } else {
      commandsList
    }
  }

  private func triggerResize() {
    appState.popup.needsResize = true
  }

  private var emptyState: some View {
    VStack(spacing: 8) {
      Spacer()
      Image(systemName: "terminal")
        .font(.largeTitle)
        .foregroundStyle(.secondary)
      Text(String(localized: "commands_empty_title"))
        .font(.headline)
        .foregroundStyle(.secondary)
      Text(String(localized: "commands_empty_description"))
        .font(.caption)
        .foregroundStyle(.tertiary)
        .multilineTextAlignment(.center)
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
    .accessibilityIdentifier("commands_empty_state")
    .background {
      GeometryReader { geo in
        Color.clear
          .task(id: appState.popup.needsResize) {
            try? await Task.sleep(for: .milliseconds(10))
            guard !Task.isCancelled else { return }

            if appState.popup.needsResize {
              appState.popup.resize(height: geo.size.height)
            }
          }
      }
    }
  }

  private var commandsList: some View {
    VStack(spacing: 0) {
      ScrollView {
        ScrollViewReader { proxy in
          LazyVStack(spacing: 0) {
            ForEach(commands) { item in
              CommandRowView(item: item)
            }
          }
          .padding(.top, topPadding)
          .padding(.bottom, bottomPadding)
          .task(id: appState.navigator.scrollTarget) {
            guard appState.navigator.scrollTarget != nil else { return }

            try? await Task.sleep(for: .milliseconds(10))
            guard !Task.isCancelled else { return }

            if let target = appState.navigator.scrollTarget {
              proxy.scrollTo(target)
              appState.navigator.scrollTarget = nil
            }
          }
          .background {
            GeometryReader { geo in
              Color.clear
                .task(id: appState.popup.needsResize) {
                  try? await Task.sleep(for: .milliseconds(10))
                  guard !Task.isCancelled else { return }

                  if appState.popup.needsResize {
                    appState.popup.resize(height: geo.size.height)
                  }
                }
            }
          }
        }
        .contentMargins(.leading, 10, for: .scrollIndicators)
        .contentMargins(.top, topPadding, for: .scrollIndicators)
        .contentMargins(.bottom, bottomPadding, for: .scrollIndicators)
      }
    }
    .accessibilityIdentifier("commands_list")
  }
}
