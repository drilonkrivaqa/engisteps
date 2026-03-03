# EngiSteps App Improvement Roadmap

This roadmap focuses on four goals:
1. **Better** (quality and reliability)
2. **More useful** (clear user value)
3. **More beautiful** (visual polish)
4. **Easier to work with** (developer productivity)

## 1) Product direction and user value

## A. Define the core user journeys
Focus each release on these primary workflows:
- Find the right engineering tool quickly.
- Enter values with confidence and understand output.
- Save/share results for class, labs, and study.

### Concrete improvements
- Add a **“Suggested for you”** section on Home based on recent/favorite categories.
- Add **tool difficulty labels** (Beginner / Intermediate / Advanced).
- Add **“Explain result”** copy under outputs to help learning, not just calculation.
- Add **saved presets** per tool (e.g., common resistor values, unit systems).

## B. Build trust in results
- Show formula/source links for every calculation.
- Add input validation with clear correction hints.
- Display units everywhere (inputs + output + history snippets).
- Add a result confidence banner when assumptions are applied.

## 2) UX and visual design polish

## A. Home and discovery
- Upgrade category chips into a richer card grid with icon + short description.
- Add quick actions row: `Resume last tool`, `Open favorites`, `New note`.
- Replace plain empty states with illustrative, actionable cards.

## B. Tool pages
- Use a consistent 3-part layout:
  1. Problem statement
  2. Inputs
  3. Results + explanation
- Add sticky `Calculate`/`Save` action bar on long forms.
- Add “Input examples” below complex fields.
- Highlight changed output values with subtle animation.

## C. Visual system
- Define semantic color tokens: success/warning/error/info and use consistently.
- Introduce type scale and spacing scale in one place.
- Add gentle motion tokens (durations/curves) for consistency.
- Add dark mode contrast review (especially cards and chips).

## 3) Feature roadmap (high impact)

## Next 2–4 weeks (quick wins)
- Tool-level search tags and synonyms (e.g., “op-amp”, “operational amplifier”).
- Pin tools to top of category pages.
- Export result to share sheet as clean text.
- Add onboarding choice: student track vs professional quick tools.

## Next 1–2 months
- Build a “unit conversion layer” reusable across all tools.
- Add classroom mode templates for assignments.
- Add notes linking (`note -> tool result`) for traceable study workflows.
- Add basic usage analytics dashboard (local anonymized counts).

## Next 1–2 quarters
- Cloud sync for favorites/history/notes.
- Collaborative classroom spaces.
- “Compare scenarios” mode (A/B input sets with side-by-side outputs).

## 4) Engineering quality and maintainability

## A. Architecture cleanup
- Introduce a shared `ToolExecutionService` so history/favorites/notes integration logic is centralized.
- Define typed view models for screen state instead of dynamic normalizers.
- Move reusable input parsing/validation into a dedicated `core/forms` module.

## B. Testing strategy
- Add golden tests for key screens (Home, Tool detail, Search).
- Add unit tests for every formula tool implementation.
- Add widget tests for validation and error messaging.
- Add smoke integration test for “search -> run tool -> save result”.

## C. Developer experience
- Add root `README.md` with setup, architecture map, and contribution guide.
- Add `Makefile` or scripts for common commands (`analyze`, `test`, `format`, `run`).
- Enforce lint + format + tests in CI.
- Add pull request template with checklist for UX, testing, and docs.

## 5) Prioritized execution plan

## Sprint 1
- Improve Home discovery (suggested tools + quick actions).
- Strengthen tool validation and unit display.
- Add first wave of tests (formulas + home widget test).

## Sprint 2
- Introduce result explanations and preset input sets.
- Add sharing/export and pinning improvements.
- Add developer scripts and CI quality gates.

## Sprint 3
- Build unit conversion layer and classroom templates.
- Expand UI polish pass (type scale, motion, dark mode contrast).
- Add onboarding improvements and analytics basics.

## Success metrics
Track these after each release:
- Time-to-first-successful-calculation.
- Search-to-tool-open conversion.
- Weekly active users and 7-day retention.
- Favorites/save rate per active user.
- Crash-free sessions and calculation error rate.

## Definition of done (for new tools/features)
- Inputs validated with helpful messages.
- Units explicitly shown.
- Result explanation included.
- Tool has tests (unit + at least one widget path).
- Documentation and changelog updated.
