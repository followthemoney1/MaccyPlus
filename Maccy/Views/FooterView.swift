import Defaults
import SwiftUI

struct FooterView: View {
  @Bindable var footer: Footer

  @Environment(AppState.self) private var appState
  @Environment(ModifierFlags.self) private var modifierFlags
  @Default(.showFooter) private var showFooter
  @State private var clearOpacity: Double = 1
  @State private var clearAllOpacity: Double = 0

  private var clearItem: FooterItem? {
    footer.items.first { $0.title == "clear" }
  }

  private var clearAllItem: FooterItem? {
    footer.items.first { $0.title == "clear_all" }
  }

  var clearAllModifiersPressed: Bool {
    let clearModifiers = clearItem?.shortcuts.first?.modifierFlags ?? []
    let clearAllModifiers = clearAllItem?.shortcuts.first?.modifierFlags ?? []
    return !modifierFlags.flags.isEmpty
      && !modifierFlags.flags.isSubset(of: clearModifiers)
      && modifierFlags.flags.isSubset(of: clearAllModifiers)
  }

  private var visibleItems: [FooterItem] {
    footer.items.filter { $0.isVisible(in: appState.mode) }
  }

  var body: some View {
    VStack(spacing: 0) {
      Divider()
        .padding(.horizontal, Popup.horizontalSeparatorPadding)
        .padding(.bottom, Popup.verticalSeparatorPadding)

      if appState.mode == .history {
        if let clear = clearItem, let clearAll = clearAllItem {
          ZStack {
            FooterItemView(item: clear)
              .opacity(clearOpacity)
            FooterItemView(item: clearAll)
              .opacity(clearAllOpacity)
          }
          .onChange(of: modifierFlags.flags) {
            if clearAllModifiersPressed {
              clearOpacity = 0
              clearAllOpacity = 1
              clear.isVisible = false
              clearAll.isVisible = true
              if appState.footer.selectedItem == clear {
                appState.navigator.select(footerItem: clearAll)
              }
            } else {
              clearOpacity = 1
              clearAllOpacity = 0
              clear.isVisible = true
              clearAll.isVisible = false
              if appState.footer.selectedItem == clearAll {
                appState.navigator.select(footerItem: clear)
              }
            }
          }
        }
      }

      ForEach(visibleItems.filter({ $0.title != "clear" && $0.title != "clear_all" })) { item in
        FooterItemView(item: item)
      }
    }
    .opacity(showFooter ? 1 : 0)
    .frame(maxHeight: showFooter ? nil : 0)
    .padding(.bottom, showFooter ? Popup.verticalPadding : 0)
    .readHeight(appState, into: \.popup.footerHeight)
  }
}
