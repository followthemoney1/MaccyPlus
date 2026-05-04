# Architect Round 1 — Open Questions

The plan at `current-plan.md` is solid in shape, but source-grounded validation surfaced **four blocker contradictions** plus **six product/UX decisions** that the user must resolve. Below, contradictions are first (they invalidate plan sections); product items second.

Cite-back format used: `file:line` from MaccyPlus source.

---

## A. Plan-vs-Source Contradictions (must resolve before READY_TO_SPEC)

### A1. `Search.Searchable` is a typealias, not a protocol

**Claim in plan**: "`CommandDecorator` conforms to `Search.Searchable`" (Files-to-Modify row 13; Phase 2 deliverable).
**Source reality**: `Maccy/Search.swift:34` — `typealias Searchable = HistoryItemDecorator`. Every method on `Search` takes `[HistoryItemDecorator]`. There is no protocol to conform to; `Search` is hard-bound to `HistoryItemDecorator`.

**Fork the user must pick**:

- **A1a — Refactor `Search` to be generic** over a new `Searchable` protocol. Both `HistoryItemDecorator` and `CommandDecorator` adopt it. Adds risk to history-mode search behavior; needs regression coverage.
- **A1b — Duplicate `Search` as `CommandSearch`** scoped to `[CommandDecorator]`. Zero risk to history search; two near-identical search files to maintain.
- **A1c — Run two `Search` instances** parameterized by closure-extractors instead of a protocol. Less invasive than A1a, fewer abstractions.

> Recommendation if undecided: **A1b** for v1 (lowest risk). Refactor later when a third searchable type appears.

### A2. `NavigationManager` is hard-bound to `HistoryItemDecorator`

**Claim in plan**: "Reuse `NavigationManager` with a small refactor" (Architecture Decisions §3); "Selection abstraction so it can target commands.visibleItems" (Files-to-Modify row 11).
**Source reality**: `Maccy/Observables/NavigationManager.swift:14` — `var selection: Selection<HistoryItemDecorator>`. `leadHistoryItem` (line 31), `select(item: HistoryItemDecorator?, ...)` (line 79), every `extendSelection / highlightFirst / highlightNext / highlightLast` references `history.firstVisibleItem`, `history.visibleItem(after:)`, `history.lastVisibleItem`. The "small refactor" is in fact a generic-or-bifurcate decision identical to A1.

**Fork the user must pick**:

- **A2a — Generic `NavigationManager`** parameterized over a `NavigableItemContainer` protocol that both `History` and `Commands` implement. Touches 100 % of NavigationManager surface; high regression risk on keyboard nav (the core UX of the app).
- **A2b — Add a sibling `CommandsNavigationManager`** mirroring NavigationManager. `AppState` exposes `var navigator` that returns the right one based on `mode`. Two near-identical files; minimal risk to history nav.
- **A2c — Single navigator with two private collections + a `mode` switch internally**. Single file, but `selection` field type still has to bifurcate (see A1) — does NOT reduce overall complexity.

> Recommendation if undecided: **A2b** for v1 — pairs cleanly with A1b.

### A3. `Footer` is built once in `init()`, FooterView indexes positionally

**Claim in plan**: "Footer items mode-aware (Clear → Add Command in commands mode)" (Files-to-Modify row 16; Phase 9).
**Source reality**:

- `Maccy/Observables/Footer.swift:27` — `init()` sets `items = [...]` once with five `FooterItem`s in fixed positions (`clear`, `clear_all`, `preferences`, `about`, `quit`).
- `Maccy/Views/FooterView.swift:14-18` — `clearAllModifiersPressed` reads `footer.items[0].shortcuts` and `footer.items[1].shortcuts` POSITIONALLY. Lines 28-32 render `FooterItemView(item: footer.items[0])` and `[1]` directly. If commands mode rebuilds `items` so position 0 is "Add Command", history-mode behavior breaks; if commands mode keeps positions 0/1 reserved as `clear`/`clear_all` no-ops, UI shows phantom items.

**Fork the user must pick**:

- **A3a — Replace positional indexing with title-keyed lookup** in `FooterView` (`footer.items.first(where: { $0.title == "clear" })`). Same pattern already used in `KeyHandlingView.swift:31`. Makes the footer truly mode-driven. Effort: one focused PR-sized change, low risk.
- **A3b — Keep `Footer` history-only**, add a separate `CommandsFooter` observable, swap the entire `FooterView` based on `appState.mode`. Two footer files; cleanest separation; biggest churn in `ContentView`.
- **A3c — Hide the footer in commands mode entirely**, surface "Add Command" as a list-empty-state CTA + a `+` button in the new `ModePickerView`. Smallest scope; user loses Preferences / About / Quit shortcut access when commands mode is open (mitigated by `⌘,` and `⌘Q` still working from `KeyHandlingView`).

> Recommendation if undecided: **A3a + A3c combined** — keep one footer (`clear` hidden in commands mode by `isVisible`), add inline "Add Command" CTA. Smallest footprint, no extra file.

### A4. `Storage.swift` does NOT use `VersionedSchema` or a migration plan

**Claim in plan**: SwiftData Schema Migration section shows `enum SchemaV2: VersionedSchema`, `enum CommandsMigrationPlan: SchemaMigrationPlan`, `ModelContainer(for: SchemaV2.self, migrationPlan: ...)`.
**Source reality**: `Maccy/Storage.swift:30` — `container = try ModelContainer(for: HistoryItem.self, configurations: config)`. Bare schema. No `VersionedSchema`, no migration plan ever existed.

**Implication**: We don't need to "upgrade v1 → v2" — there is no v1 versioned schema. We just add the new `@Model` types to the `ModelContainer(for:)` call:

```
ModelContainer(for: HistoryItem.self, Command.self, CommandFolder.self, CommandVariable.self, configurations: config)
```

SwiftData performs lightweight migration automatically (additive `@Model` types only).

**Decision needed only if user wants to introduce explicit `VersionedSchema` / `SchemaMigrationPlan` infrastructure now** as future-proofing. Recommendation: **NO** — adopt versioned schemas only when the first NON-additive change lands. v1 of Commands is purely additive.

> If user agrees, plan section "SwiftData Schema Migration" is REWRITTEN to one-line: "Add the three new `@Model` types into `Storage.swift:30` `ModelContainer(for:)` arg list. SwiftData lightweight-migrates additive schemas with zero ceremony."
> The `Maccy/Storage.xcdatamodeld` modify line item is **dropped from the impact table** — SwiftData drives schema from `@Model` types, not from the legacy `.xcdatamodeld` (which is residual from the Maccy Core Data → SwiftData migration; `representedClassName="HistoryItemL"` at `Storage.xcdatamodeld/Storage.xcdatamodel/contents:3` is the original-class shim).

---

## B. Product / UX Decisions (the original 7 confirmation items)

### B1. Mode-switch hotkey default

Plan suggests `⌃Tab` (Control-Tab). Source reality: `Maccy/KeyChord.swift:77-83` reserves `⌃u`, `⌃h`, `⌃w` for search edits; `⌃j`/`⌃k`/`⌃n`/`⌃p` for navigation. `⌃Tab` is not currently bound — safe slot.

**Question**: confirm `⌃Tab` (recommendation), or pick `⇧⌘C`, `⌃M`, or "no global hotkey, only the segmented picker click"?

### B2. Click-on-command semantics

Plan defaults to "copy + auto-paste matching history click" (Phase 8). History does this via `Defaults[.pasteByDefault]` (`History.swift:310`). Commands could:

- **B2a** — Honor the SAME `pasteByDefault` flag (consistency).
- **B2b** — Always copy + paste (most useful for snippet expansion).
- **B2c** — Always copy only (safest; user pastes manually).
- **B2d** — Add a NEW `commandsPasteByDefault` Defaults key so commands can be configured independently.

**Question**: which?

### B3. `%INPUT:label%` UX surface

Plan: "inline sheet on the panel". The panel is an `NSPanel` with `.nonactivatingPanel` style mask (`FloatingPanel.swift:27`); SwiftUI `.sheet` on a non-activating panel is uncharted territory in Maccy and may flicker focus. Alternatives:

- **B3a** — Replace the list temporarily with the input form IN-PLACE inside the same panel (no sheet; just swap a SwiftUI subtree). Most reliable.
- **B3b** — Open a separate window with the input form. Loses the popup-feel.
- **B3c** — Inline `.sheet` (plan default). Requires testing on macOS 14 / 15 / 26.

**Question**: B3a (recommended for v1), B3b, or B3c?

### B4. Drag-to-convert — v1 or v1.1?

Source reality: `FloatingPanel.swift` uses `.nonactivatingPanel` + `level = .statusBar` (line 40). NSPanel drag sessions are documented to be flaky on `.nonactivatingPanel` style mask without `becomesKeyOnlyIfNeeded` overrides. Plan flags this risk in "Risks / Open items" but still slots drag in Phase 10.

**Question**:

- **B4a** — Ship in v1 with explicit acceptance test on each macOS version (14 / 15 / 26).
- **B4b** — Defer drag-to-convert to v1.1. v1 conversion path = right-click history row → "Save as Command" context menu. Smaller scope, no NSPanel drag concerns.

> Recommendation: **B4b**. The right-click "Save as Command" path is one `.contextMenu(for:)` modifier on `HistoryItemView` and reuses the same `Commands.create(fromText:)` API; it's strictly smaller than the drag implementation and not blocked by panel-drag uncertainty.

### B5. Folder sidebar visibility for v1

Plan says "ships behind `Defaults[.showCommandFolders]` (default false)". This means file `CommandFolderSidebarView.swift` is created but never shown in v1 — pure dead code in shipping binary unless feature-flagged.

**Question**:

- **B5a** — Ship folders with sidebar visible by default in v1. Supports future user flows immediately. Adds layout complexity to the popup.
- **B5b** — Defer the entire folder concept to v1.1. v1 has flat command list + a "tags" string field on each command for free-form grouping. Smaller surface, no `CommandFolder` model, no sidebar view, no relationship cascade.
- **B5c** — Ship as plan suggests: model + sidebar exist behind a flag, default off.

> Recommendation: **B5b**. Drop `CommandFolder` from v1 entirely. The relationship+cascade plumbing pays for itself only when the sidebar is visible. We can add it cleanly in v1.1 with an additive `@Model` migration (same path as Commands itself).

### B6. Per-command global hotkey (`KeyboardShortcuts.Recorder` in editor)

Plan: "Per-command global hotkey wiring — model field exists; recorder UI exists; the hotkey listener registration is deferred to v1.1" (Future Work).
But Phase 7 deliverable lists `command_editor_hotkey_recorder` as a v1 accessibility identifier — UI is shipped in v1 with no listener wired.

**Question**:

- **B6a** — Drop the recorder UI from v1 entirely. Add it in v1.1 alongside the listener. Avoids ship-shaped dead UI.
- **B6b** — Ship the recorder but disable + tooltip "available in v1.1". Soft-tease a future feature; risk users complain it doesn't work.
- **B6c** — Ship the recorder + listener fully wired. Out-of-scope for the plan's stated v1 boundary.

> Recommendation: **B6a**.

### B7. Lightweight migration sufficiency

Resolved silently — see A4 above. SwiftData additive migration is automatic. No user decision needed unless the user wants explicit `VersionedSchema` infrastructure scaffolded ahead of time (recommendation: no, defer to first non-additive change).

---

## C. Bug Sweep on Touched Files (in scope)

Numbered, severity-ranked. None blocks the spec; reviewer should track them.

1. **MEDIUM** — `Maccy/Views/FooterView.swift:14-18, 28-32, 37-40` — positional `footer.items[0/1]` indexing. Pre-existing fragility; explicitly documented in A3 above. Plan changes interact directly.
2. **MEDIUM** — `Maccy/Observables/AppState.swift:9` — `static let shared = AppState(history: History.shared, footer: Footer())` constructs `Footer()` eagerly with hard-coded items. Mode-aware footer (plan Phase 9) requires `Footer` to know about `AppState.shared.mode` — a back-reference cycle. Either delay footer creation or invert: `Footer` reads `AppState.shared.mode` lazily in computed `items` (allowed because Observation-aware property reads re-render).
3. **LOW** — `Maccy/Storage.swift:31-33` — `fatalError("Cannot load database: …")` on container-init failure. Adding new `@Model` types could trip this on first run if SwiftData's auto-migration ever fails. Plan's "Failure Modes" row for migration crashes is real and the canary fallback proposed (`do { try ModelContainer(...) } catch { fallback empty container + report }`) is the correct mitigation — but `Storage.swift:6` `static let shared` makes a fallback container hard to surface to UI. Reviewer should require either (a) a non-crash error path or (b) acceptance that any migration failure stays a `fatalError`.
4. **LOW** — `Maccy/Observables/History.swift:22-36` — `searchQuery didSet` fires `throttler.throttle { … }` with closure capturing `self`. The `Commands.searchQuery` should mirror this pattern; reviewer must verify no retain cycle in the new `Commands` observable (pattern test: instantiate, deinit assertion).
5. **LOW** — `Maccy/Views/HistoryItemView.swift:52-60` — `.onTapGesture` performs `appState.history.select(item)` directly inside `Task {}`. If commands rows mirror this and `.select()` opens the `%INPUT:%` form, the panel must NOT close before the form completes. Plan's "Failure Modes" `%INPUT:%` row addresses this; reviewer must confirm the implementation doesn't accidentally trigger `popup.close()` before the input continuation resolves.
6. **INFO** — `Maccy/Views/ContentView.swift:19, 29` — `searchQuery: $appState.history.searchQuery` is bound twice (once to `KeyHandlingView`, once to `HistoryListView`). The plan's mode-routed binding (`appState.searchQuery` computed) must replace BOTH bindings consistently. If only one is rerouted, history-mode search and commands-mode search will silently diverge.
7. **INFO** — `Maccy/Observables/Footer.swift:27-83` — `init()` is `function_body_length`-annotated suppression, ~57 lines. Adding a commands-mode item set inline grows it past 80; reviewer should require splitting into `historyItems()` / `commandsItems()` private factories.

---

## D. Placement Check (Files to Create)

All 22 paths in the plan resolve to plausible MaccyPlus directories EXCEPT three:

| Plan path | Issue | Suggested fix |
|-----------|-------|---------------|
| `Maccy/KeyHandlingView.swift` (Files-to-Modify row 10) | Actual location is `Maccy/Views/KeyHandlingView.swift` (verified). Plan path is wrong. | Update path. |
| `Maccy/NavigationManager.swift` (Files-to-Modify row 11) | Actual location is `Maccy/Observables/NavigationManager.swift` (verified). Plan path is wrong. | Update path. |
| `Maccy/VariableExpander.swift` (Files-to-Create row 12) | Plan places it at `Maccy/` root. Reasonable per "AppKit-edge service like `Clipboard.swift`" — but `Maccy/Clipboard.swift` is the only such root file; everything else is layered. Either accept root placement (consistent with `Clipboard`) or move to `Maccy/Services/VariableExpander.swift`. | User pick; minor. |

All other paths conform.

---

## E. Round Outcome

`NEEDS_ANSWERS` — four contradictions (A1–A4) and six product decisions (B1–B6) need user resolution before the plan is build-ready. A4 has a strong silent default (lightweight migration via additive `@Model`) but A1, A2, A3 each have real fork choices that change phase counts and file counts.

After answers, architect Round 2 will write a `Round 1 Resolutions` delta section appended near the top of `current-plan.md` (does NOT rewrite earlier sections per spec).
