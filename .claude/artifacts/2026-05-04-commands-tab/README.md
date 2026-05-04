# Artifact: Commands Tab (2026-05-04)

Generated from the ClipDeck "Commands / Snippets" brief, retrofitted onto MaccyPlus's existing floating panel UI (the popup that pairs with `NSStatusItem`).

## Files

- `current-plan.md` — full implementation plan ready for `/architect` confirmation round and `/build` consumption.
- `architect-questions.md` — produced by `/architect` Round 1 if user invocation needed clarifications (not yet present).
- `lesson-candidates.md` — appended during build/review when patterns surface that aren't covered by `.claude/rules/`.

## Pipeline

1. `/architect` reads `current-plan.md` + screenshot context, validates assumptions ledger, and either returns `READY_TO_SPEC` or asks the user to confirm the 7 checklist items at the plan tail.
2. `/build` implements all 14 phases sequentially per project policy, then `/review` audits once at the end.
3. `/review` runs SwiftLint, Periphery, `xcodebuild build`, `xcodebuild test`, accessibility-identifier audit, localization parity check.
4. `localizer` agent flags new keys and tells maintainer to run BartyCrouch.
5. `docs-writer` agent updates `docs/business/commands-tab.md` + `docs/technical/commands-tab/commands-tab.md` + README section.

## Status

- Plan: DRAFT — awaiting `/architect` confirmation round
- Implementation: not started
- Review: not started
