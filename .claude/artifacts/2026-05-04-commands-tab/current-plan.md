# Implementation Plan: Commands Tab (MaccyPlus)

> Source brief: ClipDeck "Snippets / Commands" feature, retrofitted onto the existing MaccyPlus floating-panel UI shown in the screenshot. New top tab switcher beside the search field. Mode 1 = History (current). Mode 2 = Commands (new — persistent, user-curated, with smart variables). User can drag a history row into the Commands list to convert it. Click a command → expand variables → paste.

---

## Plan Summary

**Scope**: Add second mode "Commands" to the existing floating panel. Tab switcher in `ListHeaderView`. New `Command` SwiftData model. New `Commands` observable. New `CommandsListView` mirroring `HistoryListView`. New editor sheet. Smart-variable expansion (`%CLIPBOARD%`, `%DATE%`, `%TIME%`, `%UUID%`, `%INPUT:label%`). Drag-to-convert from history → command. Search works in both modes.
**Complexity**: High — touches `AppState`, header chrome, footer, navigation, key-handling, persistence schema, paste pipeline, drag-and-drop, localization across 30+ locales.
**Estimated files**: ~24 new, ~9 modified.

### What will be built
- Tab switcher in the header — toggles between **History** and **Commands**.
- Persistent **Commands** library: title + body + kind (text / future-script) + optional variables + folder grouping + pin.
- Click a command → expand variables → place result on `NSPasteboard` → **always** auto-paste (snippet UX).
- Right-click a history row → context menu "Save as Command" → opens `CommandEditorView` prefilled.
- Variables: `%CLIPBOARD%`, `%DATE%`, `%TIME%`, `%UUID%`, `%INPUT:label%` (last one shows in-place input view inside the panel).
- Search field is mode-aware: filters the visible list (history rows OR commands). History uses existing `Search`; commands use a direct case-insensitive substring filter.
- Folders ship visible by default (no flag gate). Each command belongs to a folder; folder cascade-deletes commands (with confirm dialog).
- Per-command global hotkey: recorder in editor + listener registered at app launch + on every command create/update/delete.

### Key decisions
- **Tab switcher = SwiftUI segmented `Picker`** placed inside `ListHeaderView`, left of `SearchFieldView`. Reuses existing `ListHeaderView` slot — no new top-level chrome row.
- **Persistence = SwiftData** (new `@Model` types in `Maccy/Models/Command.swift`, `Maccy/Models/CommandVariable.swift`, `Maccy/Models/CommandFolder.swift`). Reuses `Storage.shared.container` — single `ModelContainer`. **Bare `Schema(...)` additive registration** — SwiftData lightweight-migrates new `@Model` types automatically; no `VersionedSchema` / `SchemaMigrationPlan` needed.
- **`Commands` as a top-level `@Observable`** in `Maccy/Observables/Commands.swift` — mirrors `History`. Hangs off `AppState` next to `history`.
- **Mode lives on `AppState`** as `enum AppMode { case history, commands }` + `var mode: AppMode = .history`. `searchVisible` and `select()` branch on `mode`.
- **Hotkey for tab switch** = new `KeyboardShortcuts.Name.toggleMode` (default `⌃Tab`). Existing `⌘1`–`⌘9` already select top-N history items and stay reserved.
- **Scripts deferred** — `kind` field exists in the model with values `text` and (reserved) `script`, but `script` execution is NOT wired in v1. Editor exposes only the `text` kind. Punted to v2.
- **Right-click conversion** uses `.contextMenu` on `HistoryItemView` → "Save as Command" item. Drag-to-convert deferred to v1.1.

### Risks / Open items
- **SwiftData schema additive registration**: confirm `Storage.swift` `ModelContainer(for: ...)` accepts the additive list cleanly. SwiftData handles new `@Model` types without explicit migration; verify by loading a populated v1 store on first launch with the new schema.
- **Search field re-binding**: `appState.history.searchQuery` is hardcoded into `KeyHandlingView` (`ContentView.swift:19`). Need a mode-routed binding (`appState.searchQuery` computed property) or two separate fields.
- **Footer** currently exposes Clear / Preferences / About / Quit. Move to title-keyed lookup with `isVisible(in mode:)` predicates so commands mode hides "Clear" and shows "Add Command".
- **Paste-with-variables** must run BEFORE the panel closes, otherwise `%INPUT:label%` prompt would appear after the popup goes away. Sequence: click → expand → if any `%INPUT:%` present, swap list view for `VariableInputView` IN-PLACE → on submit, write to pasteboard, close panel, simulate ⌘V (always — snippet UX).
- **Per-command hotkey collision**: registering N user-defined `KeyboardShortcuts.Name` instances on launch must detect duplicates among themselves and against existing app shortcuts. Surface inline error in editor on collision.
- **Folder cascade-delete**: deleting a folder cascades commands AND their pins/hotkeys; user must see a confirm dialog with the affected count.
- **Localization explosion**: 30+ `.lproj/` directories. Add keys to `en` only, run BartyCrouch sync as a separate maintainer step.

---

## Architect Round 1 Resolutions

Round 1 questions closed. See `.claude/artifacts/2026-05-04-commands-tab/architect-questions.md` for full reasoning per item; this section captures the decisions that drive the table edits below.

| Item | Decision | Implication |
|------|----------|-------------|
| **A1** Search reuse | Reuse existing `Search` for History only. Commands skip Fuse — direct `localizedCaseInsensitiveContains(query)` on title + body + folder. | Drops `Search.swift` modify row. `CommandDecorator` no longer conforms to `Search.Searchable`. |
| **A2** NavigationManager | Single `NavigationManager` with internal mode switch (private `historySelection` + `commandsSelection`; `currentSelection` reads `appState.mode`). NO sibling manager, NO generic protocol. | NavigationManager modify row stays HIGH risk. Consider extension files to keep file under 200 lines. |
| **A3** Footer | Single `Footer.items` built once in `init()`; `FooterItem.isVisible(in mode:)` predicate; `FooterView` uses title-keyed lookup. | Footer modify row reduced to "add isVisible + commands items". FooterView modify row updated. Bug Sweep #1 (positional indexing) fixed here. |
| **A4** Schema | Drop `VersionedSchema` / `SchemaMigrationPlan`. `ModelContainer(for: HistoryItem.self, Command.self, CommandFolder.self, CommandVariable.self, ...)`. Lightweight automatic. | `Storage.xcdatamodeld` modify row REMOVED. Schema migration section rewritten to one paragraph. Migration test simplified to "load fixture, add types, no data loss". |
| **B1** Hotkey | `⌃Tab` default for `KeyboardShortcuts.Name.toggleMode`. User-overridable. | No table change. |
| **B2** Click semantics | **Always copy + auto-paste**, independent of `Defaults[.pasteByDefault]`. | Phase 8 deliverable updated. |
| **B3** `%INPUT:%` UX | In-place subtree swap inside the floating panel — replace `CommandsListView` with `VariableInputView`. NOT a SwiftUI `.sheet`. | `VariableInputSheet.swift` renamed to `VariableInputView.swift`. ContentView modify includes in-place swap. |
| **B4** Drag-to-convert | DEFER drag to v1.1. v1 = right-click history row → "Save as Command" via `.contextMenu`. | Phase 10 renamed to "Right-Click Save-as-Command". `HistoryItemView` modify row changes from `.onDrag` to `.contextMenu`. NSPanel drag risk REMOVED. UI test scenario REPLACED. |
| **B5** Folders | Ship folders VISIBLE by default. Default folder created on first launch. Drag-between-folders out of scope. | `CommandFolderSidebarView.swift` UNGATED (no `Defaults[.showCommandFolders]`). NEW Phase 6.5 "Folder CRUD UX". NEW failure mode: cascade-delete confirmation. |
| **B6** Per-command hotkey | Ship FULLY in v1: recorder + collision detection + persistent registration via `CommandHotkeyRegistrar`. Hotkey-fired command containing `%INPUT:%` must auto-show panel + jump to input view. | NEW Phase 11.5 "Per-Command Hotkey Wiring". NEW file `Maccy/CommandHotkeyRegistrar.swift`. NEW failure modes (3). NEW UI test. NOT-in-scope row REMOVED. |

Tables updated in-place below.

---

## Rules Spec

Rule files Developer + Reviewer must honor (auto-loaded from `.claude/rules/` when populated; defaults otherwise from `.claude/agents/*.md`):
- swiftui-views.md (one View per file, `@Bindable` for `@Observable`, `accessibilityIdentifier` on every interactive)
- observable-state.md (Observation framework only, NO `ObservableObject`)
- core-data.md / swift-data.md (no view writes; go through Storage / observable; lightweight migration)
- swift-style.md (no force unwraps in production, MainActor on UI types)
- localization.md (en source, BartyCrouch syncs other locales)
- accessibility.md (VoiceOver labels on every interactive, hit-target ≥ 24pt)
- testing.md / testing-ui.md (XCTest for logic, XCUITest for flows)

Lessons referenced: none yet — likely candidates surfaced during implementation.

---

## Architecture Decisions

- **Single panel, mode toggle** (NOT a separate window). Lower cognitive load; user already knows the panel; tab switcher matches every screenshot reference (Alfred, Raycast, Paste).
- **Reuse `ListItemView`** for command rows. Same row chrome (selection highlight, hotkey hint). Pass content via the existing `Decorator` pattern — introduce `CommandDecorator` parallel to `HistoryItemDecorator`.
- **Single `NavigationManager` with mode-internal switch** (per A2). Two private selection collections (`historySelection`, `commandsSelection`); `currentSelection` returns the active one based on `appState.mode`. Mode-scoped extensions split the file if it grows past 200 lines.
- **SwiftData + same `ModelContainer`** rather than two separate stores — simplifies backup, export, future iCloud sync. Additive registration of new `@Model` types — SwiftData lightweight-migrates automatically; no explicit `VersionedSchema` / `SchemaMigrationPlan` (per A4).
- **History uses `Search` (Fuse)**; commands use direct substring match (per A1). Lower complexity on the commands side; users curate the corpus and don't need fuzzy.
- **Variable expansion is sync** for `%DATE%` / `%TIME%` / `%UUID%` / `%CLIPBOARD%`, **async** when `%INPUT:%` tokens present (awaits user input via in-place view swap, NOT a sheet — per B3). Single `VariableExpander.expand(_:) async -> String` API hides the distinction.
- **Always copy + auto-paste** for commands (per B2) — independent of `Defaults[.pasteByDefault]`. That's the snippet-expansion UX.
- **Per-command hotkey wiring lives in v1** via `CommandHotkeyRegistrar` (per B6). Diff-based registration on every Commands.items change.
- **Reference feature for pattern**: `History` observable + `HistoryListView` + `HistoryItemDecorator` + `Storage.add` flow. Commands feature mirrors this 1:1 to keep the codebase readable.

---

## Data / State Map

| Data | Source | Path | Persistence |
|------|--------|------|-------------|
| `appState.mode` | `AppState` | `Maccy/Observables/AppState.swift` | in-memory + `Defaults[.lastMode]` for restore |
| `appState.commands` | `Commands` | `Maccy/Observables/Commands.swift` | SwiftData via `Storage.shared.container` |
| Command record | `Command` `@Model` | `Maccy/Models/Command.swift` | SwiftData |
| Command folder | `CommandFolder` `@Model` | `Maccy/Models/CommandFolder.swift` | SwiftData |
| Per-command variable defaults | `CommandVariable` `@Model` | `Maccy/Models/CommandVariable.swift` | SwiftData |
| Per-command hotkey registry | `CommandHotkeyRegistrar` | `Maccy/CommandHotkeyRegistrar.swift` | macOS keychain via `KeyboardShortcuts` lib |
| Search query (mode-aware) | `AppState.searchQuery` (computed) | `AppState.swift` | in-memory; clears on panel close |
| Toggle-mode hotkey | `KeyboardShortcuts.Name.toggleMode` | `Maccy/GlobalHotKey.swift` (extend names enum) | macOS keychain via lib |

---

## State Flow

```
[User clicks tab "Commands"]
  → AppState.mode = .commands
    → ContentView body recomputes
      → renders CommandsListView instead of HistoryListView
        → Commands.visibleItems read from SwiftData via Storage.shared.context
          → @Observable tracking re-renders rows
            → User clicks a command
              → AppState.select() branches on .commands
                → VariableExpander.expand(command.body)
                  → if has %INPUT:label% tokens
                    → swap CommandsListView body for VariableInputView (in-place)
                      → user fills + submits
                      → Esc / cancel reverts to list view
                  → resolved string
                    → Clipboard.shared.copy(resolvedString)
                      → Popup.close()
                        → Clipboard.shared.simulatePaste()  [ALWAYS — snippet UX]
```

```
[User right-clicks a history row → "Save as Command"]
  → HistoryItemView.contextMenu emits action
    → Commands.create(fromHistoryText: ...)
      → SwiftData insert
        → mode auto-switches to .commands
          → CommandEditorView opens prefilled
```

```
[Per-command global hotkey fires from anywhere]
  → KeyboardShortcuts handler in CommandHotkeyRegistrar
    → Commands.execute(byHotkeyName:)
      → if command body contains %INPUT:%
        → Popup.show()  [must surface the panel]
          → AppState.mode = .commands
            → swap to VariableInputView pre-targeted at this command
      → else
        → VariableExpander.expand → Clipboard.copy → simulatePaste
```

---

## Failure Modes

| Failure | Detection | Mitigation | Test |
|---------|-----------|------------|------|
| SwiftData additive-schema crash on first launch after update | Crash in `Storage.init` | Bare `ModelContainer(for: HistoryItem.self, Command.self, ...)` lightweight-migrates; canary `do { try ModelContainer(...) } catch { fallback empty container + report }` | Unit: load fixture pre-migration store and assert success |
| `%INPUT:label%` view never resolves (panel loses key) | Future closed continuation | `withCheckedContinuation` + timeout 60s, cancels with `.cancelled` error → user sees cancellation toast | Unit: simulate continuation never resumed; expect timeout |
| ~~Drag from history to commands while panel auto-closes~~ | ~~NSPanel resign-key cancels drag~~ | ~~Hold panel open until drag session ends~~ | ~~UI: drag flow with delay~~ — REMOVED per B4 |
| Variable expansion infinite loop (`%CLIPBOARD%` body containing `%CLIPBOARD%` token) | Recursion when expanding | Token expansion is single-pass — placeholder values are NOT re-scanned | Unit: nested-token input expands once |
| Mode-switch hotkey collides with user's custom binding | KeyboardShortcuts conflict warning | Default `⌃Tab` chosen (not `⌘1-9`, not `⌘V`); user-overridable in Settings | Manual: register collision; assert lib warns |
| Localization key missing in non-en locale | Runtime shows raw key | en is source; BartyCrouch nightly job propagates; new keys ship en + other locales the next maintainer-run | grep gate in reviewer for hard-coded strings |
| **NEW Per-command hotkey collision (across two commands)** | `KeyboardShortcuts` dup registration throws on registrar pass | Registrar diffs Commands.items hotkeys; on collision, marks the OLDER command as authoritative and surfaces an inline error toast on the newer command's editor | Unit: register two commands with same shortcut; expect rejection of second |
| **NEW Per-command hotkey collides with built-in app shortcut** (e.g., `⌘1`) | Registrar checks against reserved set | Reserved-set list in `CommandHotkeyRegistrar` rejects + toasts user | Unit: assign `⌘1`; expect rejection |
| **NEW Hotkey-fired command containing `%INPUT:%` while panel closed** | Resolved string would never reach user | Registrar's handler calls `Popup.shared.show()` → sets `appState.mode = .commands` → triggers VariableInputView pre-targeted at the command | UI: register hotkey, fire it from another app, expect panel to surface with input view |
| **NEW Folder cascade-delete loses pinned commands silently** | User deletes folder, pins disappear without notice | Confirm dialog: "Delete folder X? This will also delete N commands and their hotkeys." Cascade is then explicit | UI: create folder + pinned command in it, delete folder, expect confirm + N count |
| Pinned command has hotkey identical to existing pin shortcut | KeyboardShortcuts dup registration | When user assigns a per-command hotkey, library throws; surface inline error in editor | Unit: assign duplicate; expect rejection |
| Panel resize after editor sheet closes leaves blank list | `.task` reload doesn't re-fire | Wrap CommandsListView body in `.task(id: appState.mode)` so reload triggers on mode entry | UI: enter commands mode → edit → close → assert list re-renders |

---

## Disposable Audit

| Resource | Created in | Released in deinit / cancel? |
|----------|-----------|------------------------------|
| `Task` for variable expansion (when async) | `AppState.select()` | Yes — `Task` is one-shot; if user re-clicks before resolve, cancel previous |
| `withCheckedContinuation` for `%INPUT:label%` | `VariableExpander.expand` | Yes — resume(throwing: .cancelled) on panel close |
| `KeyboardShortcuts.onKeyDown` listener for `.toggleMode` | `AppDelegate` / `MaccyApp` | Yes — `KeyboardShortcuts.disable` on terminate |
| **NEW** Per-command `KeyboardShortcuts.onKeyDown` listeners | `CommandHotkeyRegistrar` | Yes — `disable(name)` on command delete; full re-diff on commands change |
| **NEW** Confirm-dialog continuation for folder cascade-delete | `CommandFolderSidebarView` | Yes — resume on dialog dismiss; cancel = no-op |

---

## Observability

| What | Where | Notes |
|------|-------|-------|
| Mode toggle counter | `AppState.mode` didSet | Optional Sentry breadcrumb (no PII) |
| Command create / update / delete | `Commands` mutators | Breadcrumb only — never log command body (may contain secrets) |
| Variable expansion failure | `VariableExpander.expand` catch site | Sentry exception with token name; NEVER body |
| Migration success / fail | `Storage.init` | One-shot info-level log on first run after upgrade |
| Per-command hotkey registered / collision | `CommandHotkeyRegistrar` diff pass | Breadcrumb count of registered + count of rejections; NEVER hotkey value |

---

## Assumptions Ledger

| Assumption | If wrong, what breaks | How to verify |
|------------|----------------------|---------------|
| `Storage.shared.container` accepts additive `@Model` types via bare `Schema` lightweight migration | Migration crashes existing users | Read `Maccy/Storage.swift` — confirm `ModelContainer` config; spike a migration test |
| `History.xcdatamodeld` is dormant (legacy) and `Storage.xcdatamodeld` is live | Migrating wrong file = data loss | `git log --diff-filter=A -- Maccy/Storage.xcdatamodeld` + check which is referenced by `Storage.swift` |
| `ListHeaderView` accepts a leading-edge slot for the tab picker without overflowing the panel width minimum (`Defaults[.windowSize].width`) | Header wraps / clips | Read `ListHeaderView.swift`; pre-size mock; preview at min width |
| `KeyHandlingView` can route key events to either history nav OR commands nav based on mode | Mode-switch hotkey conflicts with letter-typed search | `KeyHandlingView.swift` already filters; extend filter |
| Per-command `KeyboardShortcuts.Name` can be created dynamically (one per Command.id) | Registrar can't address them stably | Read `KeyboardShortcuts` lib docs — confirm `Name(_:default:)` initializer |
| 30+ locale parity is acceptable lagging by one maintainer-run | Users see English fallback briefly | Acceptable per project's existing BartyCrouch flow |

---

## Pre-existing Bugs Found in Scope

| Severity | File:Line | Issue | Disposition |
|----------|-----------|-------|-------------|
| Low | `AppState.swift:11` | `multiSelectionEnabled` is hard-coded `false` (dead-feature flag) | Out of scope — leave |
| Info | `AppState.swift:71` | When user types into search and presses Enter with empty selection, the search text becomes a clipboard entry — desired; document in plan so commands-mode submit doesn't accidentally inherit this | Carry to plan: `select()` must branch on `appState.mode` |
| Info | `Maccy/History.xcdatamodeld` + `Maccy/Storage.xcdatamodeld` co-exist with no obvious bridge; one is legacy | Investigate first, document in `Storage Migration` section |
| **Bug Sweep #1** | `Maccy/Views/FooterView.swift:14-32` | Footer items addressed positionally (`items[0]`/`[1]`) — fragile when items are mode-filtered | Fixed as part of A3: title-keyed lookup + `isVisible(in mode:)` predicate |

---

## Impact Analysis

| File | Change Type | What Changes | Risk | Notes |
|------|-------------|--------------|------|-------|
| `Maccy/Observables/AppState.swift` | Modify | Add `enum AppMode`, `var mode`, computed `searchQuery`, branch `select()` and `togglePin()` and `deleteSelection()` on mode | High | Singleton everyone reads |
| `Maccy/Observables/Commands.swift` | Create | New `@Observable` mirroring `History` | Medium | Pattern-copy from History |
| `Maccy/Observables/CommandDecorator.swift` | Create | Wraps `Command` for list rendering. Direct substring filter; does NOT conform to `Search.Searchable` (per A1) | Low | Pattern-copy from `HistoryItemDecorator.swift` |
| `Maccy/Models/Command.swift` | Create | `@Model` SwiftData type | Medium | Schema additive |
| `Maccy/Models/CommandFolder.swift` | Create | `@Model` w/ `@Relationship(deleteRule: .cascade)` | Medium | Schema additive |
| `Maccy/Models/CommandVariable.swift` | Create | `@Model` w/ default value, label | Low | Schema additive |
| `Maccy/Storage.swift` | Modify | Bare additive registration: `ModelContainer(for: HistoryItem.self, Command.self, CommandFolder.self, CommandVariable.self, ...)`. New helpers `addCommand`, `deleteCommand`, `fetchCommands(matching:)` | Medium | No `VersionedSchema` / `SchemaMigrationPlan` (per A4) |
| `Maccy/Views/HeaderView.swift` | Modify | Insert `ModePickerView` to the left of search | Medium | Layout-priority math |
| `Maccy/Views/ListHeaderView.swift` | Modify | Accept leading content slot | Medium | Public surface change |
| `Maccy/Views/ModePickerView.swift` | Create | Segmented picker bound to `appState.mode` | Low | New file |
| `Maccy/Views/CommandsListView.swift` | Create | Mirrors `HistoryListView`. Body swaps to `VariableInputView` when an input prompt is active (in-place, NOT a sheet — per B3) | Medium | Selection / nav bind |
| `Maccy/Views/CommandRowView.swift` | Create | Mirrors `HistoryItemView` row | Low | Pin / hotkey hint |
| `Maccy/Views/CommandEditorView.swift` | Create | Sheet for create / edit | Medium | Validation; per-command hotkey recorder + collision check |
| `Maccy/Views/VariableInputView.swift` | Create | In-place input view (NOT a `.sheet`); shown as a body subtree replacement of `CommandsListView` (per B3) | Medium | Continuation lifetime; Esc reverts to list |
| `Maccy/Views/ContentView.swift` | Modify | Switch between `HistoryListView` and `CommandsListView` based on `appState.mode`; bind search via `appState.searchQuery`; route in-place input view inside commands subtree | High | Root composition |
| `Maccy/Views/FooterView.swift` | Modify | Title-keyed lookup over `Footer.items` with mode filter (per A3); fixes Bug Sweep #1 | Medium | Footer is observable-driven |
| `Maccy/Observables/Footer.swift` | Modify | Add `FooterItem.isVisible(in mode: AppMode)` predicate; add commands-mode items ("Add Command", "Add Folder"); items still built once in `init()` (per A3) | Medium | Existing observable |
| `Maccy/Views/KeyHandlingView.swift` | Modify | Route key events to `Commands.navigate(...)` when `mode == .commands` (path corrected from Round 1 §D) | High | Existing key router |
| `Maccy/KeyChord.swift` | Modify | Add `case toggleMode` | Medium | Enum extension |
| `Maccy/GlobalHotKey.swift` (or where `KeyboardShortcuts.Name` extension lives) | Modify | Add `.toggleMode` shortcut name (default `⌃Tab`) | Low | Lib pattern |
| `Maccy/Observables/NavigationManager.swift` | Modify | Single manager, internal mode switch (per A2): private `historySelection`, `commandsSelection`; `currentSelection` reads `appState.mode`. Path corrected from Round 1 §D | High | Cross-cutting; consider extension files to keep ≤200 lines |
| ~~`Maccy/Search.swift`~~ | ~~Modify~~ | ~~Generic over `Searchable` already; verify `CommandDecorator` conforms~~ — REMOVED per A1: untouched | — | Reuse for History only |
| `Maccy/Sorter.swift` | Modify (additive) | Add command-specific sort options | Low | |
| `Maccy/VariableExpander.swift` | Create | `Maccy/` root (it's an AppKit-edge service like `Clipboard.swift`) | Medium | Token grammar |
| **NEW** `Maccy/CommandHotkeyRegistrar.swift` | Create | Diffs `Commands.items` hotkeys against `KeyboardShortcuts.Name` registry on every change; registers/de-registers listeners; routes fire to `Commands.execute(byHotkeyName:)` (per B6) | High | Collision detection (across commands + against reserved); init at app launch |
| `Maccy/Settings/CommandsSettingsPane.swift` | Create | New settings pane: defaults, hotkey for `.toggleMode`, behavior toggles | Low | Mirror existing panes |
| `Maccy/AppDelegate.swift` | Modify | Register `.toggleMode` `KeyboardShortcuts` listener; bootstrap `CommandHotkeyRegistrar` on launch | Medium | Lifecycle |
| `Maccy/en.lproj/Localizable.strings` (+ existing scoped en files) | Modify | Add ~30 new keys | Low | BartyCrouch will sync later |
| ~~`Maccy/Storage.xcdatamodeld/`~~ | ~~Modify~~ | ~~New version w/ `Command`, `CommandFolder`, `CommandVariable` entities~~ — REMOVED per A4: SwiftData `@Model` types live in source files; no xcdatamodeld edit | — | Bare additive in `Storage.swift` |
| `Maccy/Views/HistoryItemView.swift` | Modify | Add `.contextMenu { Button("Save as Command") { ... } }` (per B4 — replaces `.onDrag`) | Medium | Right-click conversion |
| **NEW** `Maccy/Views/CommandFolderSidebarView.swift` | Create | Visible folder sidebar in commands mode (UNGATED per B5) | Medium | Folder CRUD |
| `MaccyTests/CommandsTests.swift` | Create | Unit: CRUD, sort, search | Low | |
| `MaccyTests/VariableExpanderTests.swift` | Create | Unit: every variable token + `%INPUT:%` continuation | Low | |
| `MaccyTests/CommandsMigrationTests.swift` | Create | Loads pre-migration fixture, asserts success after additive registration | Low | Simplified per A4 |
| **NEW** `MaccyTests/CommandFolderTests.swift` | Create | Folder CRUD, cascade-delete confirm, default-folder bootstrap | Low | |
| **NEW** `MaccyTests/CommandHotkeyRegistrarTests.swift` | Create | Collision detection, reserved-set rejection, fire-while-panel-closed flow | Medium | |
| `MaccyUITests/CommandsTabUITests.swift` | Create | UI: switch tab, add command, click to paste, **right-click history → Save as Command** (per B4), **per-command hotkey fires from another window** (per B6) | Medium | Drag scenario removed |

---

## SwiftData Schema Migration

`Storage.swift`'s `ModelContainer` initializer is updated to register the new `@Model` types additively: `ModelContainer(for: HistoryItem.self, Command.self, CommandFolder.self, CommandVariable.self, configurations: config)`. SwiftData performs lightweight migration automatically when new model types are added to an existing store — no `VersionedSchema`, no `SchemaMigrationPlan`, no `MigrationStage`. Existing `HistoryItem` rows are preserved verbatim. Per A4. The migration test (`MaccyTests/CommandsMigrationTests.swift`) seeds a populated `HistoryItem` fixture under the v1 schema, swaps in the v2 model list, and asserts zero data loss + new types insert cleanly.

---

## Files to Create

| # | File | Type | Purpose | Lines (est.) |
|---|------|------|---------|--------------|
| 1 | `Maccy/Models/Command.swift` | model | `@Model` Command | 35 |
| 2 | `Maccy/Models/CommandFolder.swift` | model | `@Model` CommandFolder | 25 |
| 3 | `Maccy/Models/CommandVariable.swift` | model | `@Model` CommandVariable (label, defaultValue, kind) | 25 |
| 4 | `Maccy/Observables/Commands.swift` | observable | CRUD + visibleItems + searchQuery (commands-scoped, direct substring filter per A1) | 140 |
| 5 | `Maccy/Observables/CommandDecorator.swift` | observable | Display wrapper; does NOT conform to Search.Searchable (per A1) | 80 |
| 6 | `Maccy/Views/ModePickerView.swift` | view | Segmented Picker, 2 segments | 35 |
| 7 | `Maccy/Views/CommandsListView.swift` | view | List of commands w/ keyboard nav; in-place swap to VariableInputView | 100 |
| 8 | `Maccy/Views/CommandRowView.swift` | view | Row mirroring HistoryItemView | 80 |
| 9 | `Maccy/Views/CommandEditorView.swift` | view | Sheet: title, body, folder, hotkey recorder + collision check, variables list | 170 |
| 10 | `Maccy/Views/VariableInputView.swift` | view | In-place input view for `%INPUT:label%` (NOT a `.sheet` — per B3) | 90 |
| 11 | `Maccy/Views/CommandFolderSidebarView.swift` | view | Visible folder sidebar (UNGATED per B5); CRUD + cascade-delete confirm | 90 |
| 12 | `Maccy/VariableExpander.swift` | service | Token grammar + expand(_:) async | 110 |
| 13 | **NEW** `Maccy/CommandHotkeyRegistrar.swift` | service | Diff-based per-command `KeyboardShortcuts` registrar (per B6); collision detection; routes to `Commands.execute(byHotkeyName:)` | 140 |
| 14 | `Maccy/Settings/CommandsSettingsPane.swift` | settings | Pane: hotkey, defaults, danger zone | 90 |
| 15 | `Maccy/Settings/en.lproj/CommandsSettings.strings` | strings | Settings pane keys | 30 |
| 16 | `MaccyTests/CommandsTests.swift` | test | CRUD / sort / search | 120 |
| 17 | `MaccyTests/VariableExpanderTests.swift` | test | Each token + `%INPUT:%` continuation + cancel + nested guard | 140 |
| 18 | `MaccyTests/CommandsMigrationTests.swift` | test | Additive schema registration (v1 fixture → load with v2 schema, no data loss) | 70 |
| 19 | **NEW** `MaccyTests/CommandFolderTests.swift` | test | Folder CRUD, cascade-delete, default-folder bootstrap | 100 |
| 20 | **NEW** `MaccyTests/CommandHotkeyRegistrarTests.swift` | test | Collision detection (across commands + reserved set); fire-while-closed surface flow | 130 |
| 21 | `MaccyUITests/CommandsTabUITests.swift` | uitest | Switch tab, add command, click to paste, right-click history → Save as Command, per-command hotkey fires from another window | 200 |
| 22 | `Maccy/en.lproj/Commands.strings` | strings | Mode picker labels + footer items + toasts | 25 |
| 23 | `Maccy/Views/en.lproj/CommandsListView.strings` | strings | List empty-state + drop-target prompt | 15 |
| 24 | `Maccy/Views/en.lproj/CommandEditorView.strings` | strings | Editor labels / placeholders / errors | 25 |
| 25 | `Maccy/Views/en.lproj/VariableInputView.strings` | strings | Input view title + Submit / Cancel | 10 |

## Files to Modify

| # | File | What changes | Risk |
|---|------|--------------|------|
| 1 | `Maccy/Observables/AppState.swift` | Add `AppMode`, `mode`, computed `searchQuery`, mode-aware `select()` / `togglePin()` / `deleteSelection()` | High |
| 2 | `Maccy/Observables/Footer.swift` | `FooterItem.isVisible(in mode:)` predicate; build items once in `init()`; new "Add Command" + "Add Folder" entries (per A3) | Medium |
| 3 | `Maccy/Storage.swift` | Bare additive `ModelContainer` registration (per A4); new helpers `addCommand` / `deleteCommand` / `fetchCommands(matching:)` | Medium |
| ~~4~~ | ~~`Maccy/Storage.xcdatamodeld`~~ | ~~Add Command / CommandFolder / CommandVariable entities (new model version)~~ — REMOVED per A4 | — |
| 5 | `Maccy/Views/ContentView.swift` | Render `HistoryListView` OR `CommandsListView` based on `appState.mode`; bind search field via `appState.searchQuery`; route in-place `VariableInputView` swap inside the commands subtree (per B3) | High |
| 6 | `Maccy/Views/HeaderView.swift` | Insert `ModePickerView` leading the search row | Medium |
| 7 | `Maccy/Views/ListHeaderView.swift` | Accept leading content slot (or new dedicated slot for mode picker) | Medium |
| 8 | `Maccy/Views/HistoryItemView.swift` | Add `.contextMenu { Button("Save as Command") { ... } }` (per B4 — replaces `.onDrag`) | Medium |
| 9 | `Maccy/KeyChord.swift` | New case `toggleMode` | Medium |
| 10 | `Maccy/Views/KeyHandlingView.swift` | Route arrow / enter / pin / delete to `Commands` navigator when `mode == .commands` (path corrected from Round 1 §D) | High |
| 11 | `Maccy/Observables/NavigationManager.swift` | Single manager, internal mode switch with private `historySelection` + `commandsSelection`; `currentSelection` reads `appState.mode` (per A2); path corrected from Round 1 §D | High |
| 12 | `Maccy/AppDelegate.swift` | Register `KeyboardShortcuts.onKeyDown(for: .toggleMode) { AppState.shared.toggleMode() }`; bootstrap `CommandHotkeyRegistrar.shared.start()` on launch (per B6) | Medium |
| 13 | `Maccy/Views/FooterView.swift` | Title-keyed lookup over `Footer.items` with mode filter; fixes Bug Sweep #1 (per A3) | Medium |
| ~~14~~ | ~~`Maccy/Search.swift`~~ | ~~Confirm `CommandDecorator` is `Searchable`~~ — REMOVED per A1: untouched | — |

---

## Implementation Phases

Top → bottom. Same `Group` letter = parallel-safe. Reviewer runs ONCE at the end (per project policy in `CLAUDE.md`).

### Phase 1 — Schema & Models
**Group:** A · **Deps:** none
**Produces:** `Command`, `CommandFolder`, `CommandVariable`
**Consumes:** `Storage.shared.container`

- Add new `@Model` types
- Update `Storage.swift` `ModelContainer(for: ...)` to additive list (per A4)
- Storage helpers `addCommand`, `deleteCommand`, `fetchCommands(matching:)`
- Default-folder bootstrap on first launch
- Unit + (simplified) migration tests

### Phase 2 — Observable Layer
**Group:** B · **Deps:** Phase 1
**Produces:** `Commands`, `CommandDecorator`
**Consumes:** Phase 1

- `Commands` observable mirroring `History` shape: `items`, `pinnedItems`, `unpinnedItems`, `visibleItems`, `searchQuery`, `select(_:)`, `togglePin(_:)`, `delete(_:)`, `execute(byHotkeyName:)`
- `CommandDecorator` — display wrapper; **direct `localizedCaseInsensitiveContains` filter** in `Commands.visibleItems` (per A1)
- NO `Search.Searchable` conformance

### Phase 3 — App State Mode
**Group:** B · **Deps:** Phase 2
**Produces:** `AppMode`, `appState.mode`, `appState.searchQuery`, mode-aware `select()` / `togglePin()` / `deleteSelection()`
**Consumes:** Phase 2

- Extend `AppState`
- `Defaults[.lastMode]` for restore-on-launch
- Helper `appState.toggleMode()`

### Phase 4 — Variable Expander
**Group:** B · **Deps:** none
**Produces:** `Maccy/VariableExpander.swift`
**Consumes:** `NSPasteboard.general`

- Token grammar: `%CLIPBOARD%`, `%DATE%`, `%TIME%`, `%UUID%`, `%INPUT:label%`
- Single-pass replacement (no recursion into placeholder values)
- Async-only when `%INPUT:%` present
- Cancellation-aware (Task-cooperative)

### Phase 5 — UI: Mode Switcher + Header
**Group:** C · **Deps:** Phase 3
**Produces:** `ModePickerView`, modified `HeaderView` + `ListHeaderView`
**Consumes:** `appState.mode`

- Segmented `Picker` w/ SF Symbols (`clock.arrow.circlepath` + `terminal`)
- `accessibilityIdentifier`: `mode_picker`
- Hotkey hint label

### Phase 6 — UI: Commands List + Row
**Group:** C · **Deps:** Phase 2 + 5
**Produces:** `CommandsListView`, `CommandRowView`
**Consumes:** Phases 2 / 5

- Reuse `ListItemView` chrome
- Empty-state with prompt to right-click a clipboard item or "Add Command"
- Selection bridges through `NavigationManager` (per A2 mode switch)
- Body subtree swap point for `VariableInputView` (per B3)

### Phase 6.5 — Folder CRUD UX
**Group:** C · **Deps:** Phase 6
**Produces:** `CommandFolderSidebarView`
**Consumes:** Phases 1 / 2 / 6

- Visible folder sidebar in commands mode (UNGATED per B5)
- Folder CRUD (add, rename, delete with cascade-confirm)
- Default folder bootstrap (created on first launch in Phase 1)
- Folder picker integration in `CommandEditorView`

### Phase 7 — UI: Editor Sheet
**Group:** C · **Deps:** Phase 6.5
**Produces:** `CommandEditorView`, `VariableInputView`
**Consumes:** `Commands`

- Editor: title (required), body (multiline), folder picker, optional per-command hotkey via `KeyboardShortcuts.Recorder` + collision check, variables sub-list
- Validation: title non-empty; variable labels unique; hotkey not colliding with reserved set or other commands
- `VariableInputView`: dynamic form per `%INPUT:label%`, in-place body swap (NOT a sheet — per B3)

### Phase 8 — Wiring: Click → Expand → Paste
**Group:** D · **Deps:** Phase 4 + 6
**Produces:** modified `AppState.select()`
**Consumes:** Phase 4

- When `mode == .commands` and selection non-empty:
  - `let resolved = await VariableExpander.shared.expand(command.body)`
  - if `%INPUT:%` tokens present → swap subtree to `VariableInputView` → await user
  - `Clipboard.shared.copy(resolved)`
  - close popup → **always** `Clipboard.shared.simulatePaste()` (per B2 — independent of `Defaults[.pasteByDefault]`)

### Phase 9 — Footer + Settings + Toggle-Mode Hotkey
**Group:** D · **Deps:** Phase 3
**Produces:** Footer mode-aware items via `isVisible(in:)` predicate, `CommandsSettingsPane`, `KeyboardShortcuts.Name.toggleMode`
**Consumes:** Phase 3

- Footer items built once, filtered by `isVisible(in mode:)` (per A3): commands-mode shows "Add Command", "Add Folder", "Preferences", "About", "Quit"
- `FooterView` switches to title-keyed lookup (fixes Bug Sweep #1)
- Settings pane: hotkey recorder, "Delete all commands" (confirm)
- AppDelegate registers `.toggleMode` listener

### Phase 10 — Right-Click "Save as Command"
**Group:** D · **Deps:** Phase 6
**Produces:** modified `HistoryItemView` (`.contextMenu` per B4)
**Consumes:** Phase 2 / 6

- `HistoryItemView.contextMenu` adds "Save as Command"
- Action calls `Commands.create(fromHistoryText: ...)` → switches mode → opens `CommandEditorView` prefilled
- Drag-to-convert deferred to v1.1 (per B4)

### Phase 11 — KeyHandling + Navigation
**Group:** D · **Deps:** Phase 3 / 6
**Produces:** modified `KeyHandlingView` (path corrected from Round 1 §D), `NavigationManager` (single manager mode switch per A2), `KeyChord.toggleMode`
**Consumes:** all prior

- Route arrow / enter / pin / delete to commands navigator when `mode == .commands`
- Numeric `⌘1`–`⌘9` STILL select top-N commands (matches user's existing mental model from history mode)
- `⌃Tab` (default) toggles mode

### Phase 11.5 — Per-Command Hotkey Wiring
**Group:** D · **Deps:** Phase 7 / 11
**Produces:** `Maccy/CommandHotkeyRegistrar.swift`, modified `AppDelegate` (per B6)
**Consumes:** Phase 2 / 7

- Diff-based registrar: on every `Commands.items` change, compute additions/removals against current `KeyboardShortcuts.Name` registry → register/de-register listeners
- Collision detection: across all commands AND against reserved set (`⌘1`–`⌘9`, app shortcuts) — surface inline error in editor on collision
- Hotkey-fired handler: `Commands.execute(byHotkeyName:)` resolves variables, copies, simulates paste — when command body contains `%INPUT:%` and panel is closed, `Popup.shared.show()` first → set `appState.mode = .commands` → swap to `VariableInputView` pre-targeted at the command
- Bootstrap on app launch: re-register every persisted command hotkey
- Re-register on app foreground in case macOS dropped a shortcut

### Phase 12 — Localization
**Group:** D · **Deps:** Phase 5–11.5 (parallel with Phase 11.5)
**Produces:** new `en.lproj/*.strings`
**Consumes:** all view files

- Add `en` source keys for every new user-facing string
- Maintainer runs BartyCrouch (`bartycrouch update --tasks interfaces translate normalize`) before release; agent does NOT auto-run translate (paid)

### Phase 13 — Tests
**Group:** E · **Deps:** Phases 1–12
**Produces:** `MaccyTests/CommandsTests.swift`, `MaccyTests/VariableExpanderTests.swift`, `MaccyTests/CommandsMigrationTests.swift`, `MaccyTests/CommandFolderTests.swift`, `MaccyTests/CommandHotkeyRegistrarTests.swift`, `MaccyUITests/CommandsTabUITests.swift`
**Consumes:** all prior

- Unit coverage: CRUD, sort, search (substring), expander, additive migration, folder cascade, hotkey collision + fire-while-closed
- UI coverage: mode switch, add command, click-to-paste, right-click-save-as-command (per B4), per-command hotkey fires from another app (per B6)

### Phase 14 — Documentation
**Group:** F · **Deps:** Phases 1–13
**Produces:** `docs/business/commands-tab.md`, `docs/technical/commands-tab/commands-tab.md`, README section
**Consumes:** all prior (read source for citations)

### Graph

```
1 ─→ 2 ─→ 3 ─┬─→ 5 ─┬─→ 6 ─→ 6.5 ─→ 7 ─┬─→ 8 ─┐
              │       │                  └─→ 10 ─┐
              │       └─────────────────────→ 11 ─→ 11.5
              └─────────────────────────→ 9
4 ─────────────────────────────→ 8
12 (parallel with 5–11.5)
1..12 ─→ 13 ─→ 14
```

**Phase count: 15** (was 14 — Phase 6.5 + Phase 11.5 inserted; old Phase 10 renamed).

---

## Accessibility Identifiers (for XCUITest)

- `mode_picker` — `ModePickerView` Picker
- `mode_picker_history` — segment 1
- `mode_picker_commands` — segment 2
- `commands_list` — `CommandsListView` List
- `command_row_<id>` — each row (id from Command.id)
- `command_add_button` — Footer "Add Command" item
- `command_folder_sidebar` — `CommandFolderSidebarView`
- `command_folder_row_<id>` — each folder row
- `command_folder_delete_confirm` — cascade-delete confirm dialog
- `command_editor_title_field` — title TextField
- `command_editor_body_editor` — body TextEditor
- `command_editor_folder_picker` — folder Picker
- `command_editor_hotkey_recorder` — KeyboardShortcuts Recorder
- `command_editor_save_button` — save Button
- `command_editor_cancel_button` — cancel Button
- `variable_input_view_<label>` — each dynamic field
- `variable_input_submit` / `variable_input_cancel`
- `commands_empty_state` — empty placeholder
- `history_row_save_as_command` — context-menu item

---

## Test Plan

| Test file | Source under test | Scenarios |
|-----------|-------------------|-----------|
| `MaccyTests/CommandsTests.swift` | `Commands` observable + `Storage` helpers | CRUD happy / pin toggle / delete cascade / **substring search filter** (per A1) / sort by usage / sort by created |
| `MaccyTests/VariableExpanderTests.swift` | `VariableExpander` | each token / multiple tokens in one body / `%INPUT:%` async happy / cancel mid-resolve / nested-token guard / unknown token left literal |
| `MaccyTests/CommandsMigrationTests.swift` | `Storage` additive schema | seeded HistoryItem fixture loads under v2 schema; assert no data loss; new types insert cleanly |
| `MaccyTests/CommandFolderTests.swift` | `CommandFolder` + cascade rule | folder CRUD; cascade-delete with N child commands; default-folder bootstrap on first launch |
| `MaccyTests/CommandHotkeyRegistrarTests.swift` | `CommandHotkeyRegistrar` | register/unregister diff; collision across two commands; collision against reserved set; fire-while-panel-closed surfaces panel + jumps to input view |
| `MaccyUITests/CommandsTabUITests.swift` | end-to-end | mode switch via picker / via hotkey / add command / paste command / **right-click history → Save as Command** (per B4) / **per-command hotkey fires from another app** (per B6) |

Min 3 scenarios per touched view (per project rule). Storage / observable changes → unit tests required.

---

## Future Work / NOT in Scope

State each one line. Avoid scope creep.

- Script execution (`kind == "script"` running shell via `Process`) — model field reserved, UI hidden behind `Defaults[.commandsAllowScripts]` flag (default false). Ship in v2 with explicit warning + per-user enable.
- ~~Per-command global hotkey wiring — model field exists; recorder UI exists; the hotkey listener registration is deferred to v1.1 (needs collision detection across all commands).~~ — REMOVED per B6 (now in v1).
- Drag-to-convert from history → command — deferred to v1.1 (per B4). v1 ships right-click conversion only.
- Drag-between-folders — deferred to v1.1 (per B5). v1: command folder set via editor's folder picker only.
- iCloud sync, JSON import/export, Touch ID lock — punted to v2.
- Markdown / syntax-highlighted body editor — plain text in v1.
- BartyCrouch auto-translate run — maintainer manual step; assistant NEVER runs paid translate.
- Sparkle release bump — out of scope; release engineer step after merge.
- Telemetry / Sentry instrumentation beyond breadcrumbs — separate task.
- Existing `History.xcdatamodeld` cleanup (legacy file?) — investigate but don't delete in this task.

---

## Reference Code

- Similar feature pattern: `Maccy/Observables/History.swift` + `Maccy/Views/HistoryListView.swift` + `Maccy/Storage.swift`
- Similar settings pane: `Maccy/Settings/GeneralSettingsPane.swift`
- Similar editor sheet: search `Maccy/Views/` for `*Sheet` / `*EditorView` (none yet — design fresh, reuse `Form` + `TextField` + `KeyboardShortcuts.Recorder`)
- Hotkey naming pattern: extension on `KeyboardShortcuts.Name` — see existing `.delete`, `.pin`, `.togglePreview`
- ~~Drag emission pattern: review SwiftUI `.onDrag(_:)` — first MaccyPlus usage (greenfield)~~ — N/A per B4.
- Right-click pattern: SwiftUI `.contextMenu { ... }` modifier on existing rows.
- Per-command hotkey lib: `KeyboardShortcuts.Name(_:default:)` — see `Maccy/KeyChord.swift:77-83`

---

## Checklist for `/architect` round confirmation

Architect agent should confirm or push back on:

1. ~~Lightweight migration is sufficient (vs. heavy custom migration)~~ — RESOLVED A4: bare additive registration.
2. Single `ModelContainer` for both clipboard items and commands (vs. two stores) — confirmed.
3. ~~Mode switch hotkey default `⌃Tab` (vs. `⇧⌘C` / `⌃M`)~~ — RESOLVED B1: `⌃Tab`.
4. ~~Commands click semantics: copy + auto-paste (matching history click) vs. copy-only~~ — RESOLVED B2: always copy + auto-paste.
5. ~~Variable `%INPUT:%` UX: inline sheet on the panel (vs. opens a separate window)~~ — RESOLVED B3: in-place subtree swap.
6. ~~Drag-to-convert is in v1 (vs. defer to v1.1)~~ — RESOLVED B4: deferred; right-click in v1.
7. ~~Folder sidebar hidden behind a flag for v1 (vs. ship visible)~~ — RESOLVED B5: visible, ungated.

Architect rounds the user only on items the user must decide. Anything answerable by reading source → architect resolves silently and notes in Findings.
